extends CanvasLayer

## Переход «главное меню → игра»: облака заезжают с краёв, затем улетают.
## Заголовок — стилизованный текст (game_title_text), не PNG.
## Те же текстуры облаков, что в objects/clouds/cloud.tscn. Множитель cloud_visual_scale к размеру текстуры.
## Локальные координаты _holder: (0,0) — левый верх видимой области вьюпорта; размер = visible_rect.size (без vr.position — CanvasLayer уже в системе вьюпорта).
##
## Плотность: row_height_px × col_width_factor × extra. Конечные точки — 2D-сетка по всему экрану; сторона заезда — шахматно (col+row) % 2.
## Фаза наезда: старт без задержки; момент остановки размазан не более чем на stop_time_spread_sec (последний к cover_total_sec). Кривая: TRANS_EXPO, EASE_OUT.

## Philosopher (SIL OFL) — кириллица, спокойный «книжный» характер; Bold читается в крупном заголовке.
const TITLE_FONT_DISPLAY: Font = preload("res://ui/font/Philosopher-Bold.ttf")
const TITLE_FONT_TAGLINE: Font = preload("res://ui/font/Philosopher-Regular.ttf")

const CLOUD_TEXTURES: Array[Texture2D] = [
	preload("res://Asets/Unit_pack/Terrain/Decorations/Clouds/Clouds_01.png"),
	preload("res://Asets/Unit_pack/Terrain/Decorations/Clouds/Clouds_02.png"),
	preload("res://Asets/Unit_pack/Terrain/Decorations/Clouds/Clouds_03.png"),
	preload("res://Asets/Unit_pack/Terrain/Decorations/Clouds/Clouds_04.png"),
	preload("res://Asets/Unit_pack/Terrain/Decorations/Clouds/Clouds_05.png"),
	preload("res://Asets/Unit_pack/Terrain/Decorations/Clouds/Clouds_06.png"),
	preload("res://Asets/Unit_pack/Terrain/Decorations/Clouds/Clouds_07.png"),
	preload("res://Asets/Unit_pack/Terrain/Decorations/Clouds/Clouds_08.png"),
]

const META_FROM_LEFT := &"cloud_from_left"
const META_TITLE_OVERLAY := &"menu_title_overlay"
const META_CLOUD_WRAPPER := &"menu_cloud_row_wrapper"
const META_TITLE_MOTION_VISUAL := &"title_motion_visual"
const _EDGE_INSET: float = 4.0

## Вертикаль: число рядов из высоты экрана (как в первой версии).
@export var min_rows: int = 12
@export var max_rows: int = 24
@export var row_height_px: float = 32.0
## Горизонталь: шаг по ширине ≈ est_w * col_width_factor (меньше factor — больше столбцов).
@export var max_columns: int = 40
@export var col_width_factor: float = 0.62
## Дополнительные облака поверх сетки (свой индекс полосы band).
@export var extra_clouds: int = 32
@export var max_clouds: int = 420
## Центры и конечные позиции допускают вылет за край вьюпорта — закрытие углов и полос без дыр.
@export var screen_edge_bleed_px: float = 120.0
## Случайная позиция центра внутри ячейки сетки покрытия (0.1 = у края клетки).
@export var spread_cell_inner_jitter: float = 0.38
## Немного крупнее исходных PNG (1.0 = как в файле).
@export var cloud_visual_scale: float = 1.408
## Момент полной остановки последнего облака (самый длинный твин).
@export var cover_total_sec: float = 1.4
## Разница между самым ранним и самым поздним моментом остановки (секунды).
@export var stop_time_spread_sec: float = 0.3
@export var exit_duration_sec: float = 0.55
@export var exit_stagger_sec: float = 0.12
@export var spawn_offscreen_margin: float = 64.0
@export var spawn_safety_pad_px: float = 28.0
@export var spawn_safety_cw_fraction: float = 0.1
@export var spawn_offscreen_depth_variance_px: float = 140.0
@export var exit_past_edge_px: float = 24.0
## Плавное появление заголовка (0 = прозрачность → 1).
@export var title_fade_in_sec: float = 0.75
## Плавное исчезновение заголовка при уходе облаков.
@export var title_fade_out_sec: float = 0.5
## Ровно эта доля облаков на экране перехода — полностью непрозрачные; остальные — случайная альфа.
@export_range(0.0, 1.0, 0.01) var opaque_cloud_fraction: float = 0.5
@export_range(0.0, 1.0, 0.01) var translucent_alpha_min: float = 0.18
@export_range(0.0, 1.0, 0.01) var translucent_alpha_max: float = 0.78
## Аддитивное свечение только у полностью непрозрачных облаков (TextureRect внутри обёртки).
@export_range(1.0, 1.35, 0.01) var opaque_cloud_glow_scale: float = 1.1
@export_range(0.0, 0.55, 0.01) var opaque_cloud_glow_strength: float = 0.18
@export var opaque_cloud_glow_tint: Color = Color(0.78, 0.9, 1.0, 1.0)
## Текст заголовка на экране перехода (перенос строки = вторая строка).
@export_multiline var game_title_text: String = "Честь\nАвроры"
## Подзаголовок под названием (пусто = не показывать).
@export var game_title_tagline: String = "Свет под цепью островов"
@export_range(0.75, 1.0, 0.01) var title_fill_alpha: float = 0.9
@export_range(1.0, 1.06, 0.001) var title_breath_scale_max: float = 1.014
@export_range(1.5, 5.0, 0.1) var title_breath_period_sec: float = 3.2

var _holder: Control
var _title_motion_tween: Tween


func _ready() -> void:
	layer = 3000
	process_mode = Node.PROCESS_MODE_ALWAYS


func _ensure_holder() -> void:
	if _holder != null and is_instance_valid(_holder):
		return
	_holder = Control.new()
	_holder.mouse_filter = Control.MOUSE_FILTER_STOP
	_holder.clip_contents = false
	add_child(_holder)


## Размер видимой области; Rect с origin (0,0) — локальная система детей CanvasLayer совпадает с левым верхом вьюпорта.
func _visible_rect_strict() -> Rect2:
	var vr := get_viewport().get_visible_rect()
	var w: float = vr.size.x
	var h: float = vr.size.y
	if w < 8.0 or h < 8.0:
		var win := DisplayServer.window_get_size()
		w = maxf(w, float(win.x))
		h = maxf(h, float(win.y))
	return Rect2(0.0, 0.0, w, h)


func _apply_holder_to_visible_rect(vr: Rect2) -> void:
	var vw: float = vr.size.x
	var vh: float = vr.size.y
	_holder.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_holder.anchor_right = 0.0
	_holder.anchor_bottom = 0.0
	_holder.offset_left = 0.0
	_holder.offset_top = 0.0
	_holder.offset_right = vw
	_holder.offset_bottom = vh
	_holder.position = Vector2.ZERO
	_holder.size = Vector2(vw, vh)


func _spawn_margin_for_width(cw: float) -> float:
	return spawn_offscreen_margin + spawn_safety_pad_px + cw * spawn_safety_cw_fraction


func _spawn_x_left_local(cw: float, rng: RandomNumberGenerator, depth_max_px: float = -1.0) -> float:
	var m: float = _spawn_margin_for_width(cw)
	var dmax: float = depth_max_px if depth_max_px > 0.0 else spawn_offscreen_depth_variance_px
	var depth: float = rng.randf_range(0.0, dmax)
	return -cw - m - depth


func _spawn_x_right_local(vw: float, cw: float, rng: RandomNumberGenerator, depth_max_px: float = -1.0) -> float:
	var m: float = _spawn_margin_for_width(cw)
	var dmax: float = depth_max_px if depth_max_px > 0.0 else spawn_offscreen_depth_variance_px
	var depth: float = rng.randf_range(0.0, dmax)
	return vw + m + depth


func _scaled_cloud_size(tex: Texture2D) -> Vector2:
	var s: float = maxf(0.05, cloud_visual_scale)
	return Vector2(float(tex.get_width()) * s, float(tex.get_height()) * s)


func _cloud_layer_modulate(opaque: bool, rng: RandomNumberGenerator) -> Color:
	var r: float = clampf(rng.randf_range(0.94, 1.03), 0.0, 1.0)
	var g: float = clampf(rng.randf_range(0.96, 1.04), 0.0, 1.0)
	var b: float = clampf(rng.randf_range(0.97, 1.06), 0.0, 1.0)
	var a: float = 1.0 if opaque else rng.randf_range(
		minf(translucent_alpha_min, translucent_alpha_max),
		maxf(translucent_alpha_min, translucent_alpha_max)
	)
	a = clampf(a, 0.0, 1.0)
	return Color(r, g, b, a)


func _shuffled_opaque_flags(n: int, rng: RandomNumberGenerator) -> Array[bool]:
	var n_opaque: int = int(round(float(n) * clampf(opaque_cloud_fraction, 0.0, 1.0)))
	n_opaque = clampi(n_opaque, 0, n)
	var flags: Array[bool] = []
	for _i in range(n_opaque):
		flags.append(true)
	while flags.size() < n:
		flags.append(false)
	for i in range(flags.size() - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var t: bool = flags[i]
		flags[i] = flags[j]
		flags[j] = t
	return flags


func _rows_for_height(h: float) -> int:
	var by_step: int = int(ceil(h / maxf(16.0, row_height_px)))
	return clampi(by_step, min_rows, max_rows)


func _cols_for_width(vw: float) -> int:
	var est_w: float = float(CLOUD_TEXTURES[0].get_width()) * maxf(0.05, cloud_visual_scale)
	var f: float = maxf(0.38, col_width_factor)
	var cols: int = maxi(3, int(ceil(vw / maxf(8.0, est_w * f))))
	return mini(cols, max_columns)


## Сетка по всему кадру (с bleed); from_left = ((ci+ri) % 2 == 0) — шахматный порядок по ячейкам сетки.
func _compute_checkerboard_placements(n: int, vw: float, vh: float, bleed: float, rng: RandomNumberGenerator) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if n <= 0:
		return out
	var b: float = maxf(0.0, bleed)
	var x0: float = -b
	var x1: float = vw + b
	var y0: float = -b
	var y1: float = vh + b
	var aw: float = maxf(1.0, x1 - x0)
	var ah: float = maxf(1.0, y1 - y0)
	var aspect: float = aw / maxf(1.0, ah)
	var cols_p: int = int(round(sqrt(float(n) * aspect)))
	cols_p = clampi(cols_p, 1, n)
	var rows_p: int = int(ceil(float(n) / float(cols_p)))
	if cols_p * rows_p < n:
		rows_p += 1
	var cell_w: float = aw / float(max(1, cols_p))
	var cell_h: float = ah / float(max(1, rows_p))
	var total_cells: int = cols_p * rows_p
	var cell_indices: Array[int] = []
	for i in range(total_cells):
		cell_indices.append(i)
	cell_indices.shuffle()
	var jmin: float = clampf(0.5 - spread_cell_inner_jitter * 0.5, 0.08, 0.45)
	var jmax: float = clampf(0.5 + spread_cell_inner_jitter * 0.5, 0.55, 0.92)
	for k in range(n):
		var cell: int = cell_indices[k]
		var ci: int = cell % cols_p
		var ri: int = cell / cols_p
		var tx: float = rng.randf_range(jmin, jmax)
		var ty: float = rng.randf_range(jmin, jmax)
		var cx: float = x0 + (float(ci) + tx) * cell_w
		var cy: float = y0 + (float(ri) + ty) * cell_h
		var from_left: bool = ((ci + ri) % 2) == 0
		out.append({"c": Vector2(cx, cy), "from_left": from_left})
	return out


func _center_to_top_left_clamped(center: Vector2, cw: float, ch: float, vw: float, vh: float, bleed: float) -> Vector2:
	var b: float = maxf(0.0, bleed)
	var lo_x: float = -b
	var hi_x: float = vw - cw + b
	var lo_y: float = -b
	var hi_y: float = vh - ch + b
	var left_x: float = center.x - cw * 0.5
	var top_y: float = center.y - ch * 0.5
	if hi_x < lo_x:
		left_x = (vw - cw) * 0.5
	else:
		left_x = clampf(left_x, lo_x, hi_x)
	if hi_y < lo_y:
		top_y = (vh - ch) * 0.5
	else:
		top_y = clampf(top_y, lo_y, hi_y)
	return Vector2(left_x, top_y)


func _fit_counts_to_cap(row_count: int, cols: int, extra_n: int, cap: int) -> Vector3i:
	var r: int = row_count
	var c: int = cols
	var e: int = maxi(0, extra_n)
	while r * c + e > cap:
		if e > 0:
			e -= 1
		elif c > 3:
			c -= 1
		elif r > min_rows:
			r -= 1
		else:
			break
	return Vector3i(r, c, e)


func _add_cloud(
	tween: Tween,
	tex: Texture2D,
	start_x: float,
	end_x: float,
	y: float,
	delay_sec: float,
	from_left: bool,
	move_dur: float,
	trans_type: Tween.TransitionType,
	ease_type: Tween.EaseType,
	modulate: Color
) -> void:
	var sz: Vector2 = _scaled_cloud_size(tex)
	var cw: float = sz.x
	var ch: float = sz.y
	var is_opaque_cloud: bool = modulate.a >= 0.995

	var wrapper := Control.new()
	wrapper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wrapper.custom_minimum_size = Vector2(cw, ch)
	wrapper.size = Vector2(cw, ch)
	wrapper.position = Vector2(start_x, y)
	wrapper.set_meta(META_CLOUD_WRAPPER, true)
	wrapper.set_meta(META_FROM_LEFT, from_left)

	if is_opaque_cloud:
		var glow_tr := TextureRect.new()
		glow_tr.texture = tex
		glow_tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		glow_tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		var gs: float = maxf(1.01, opaque_cloud_glow_scale)
		var gw: float = cw * gs
		var gh: float = ch * gs
		glow_tr.custom_minimum_size = Vector2(gw, gh)
		glow_tr.size = Vector2(gw, gh)
		glow_tr.position = Vector2((cw - gw) * 0.5, (ch - gh) * 0.5)
		glow_tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var gmat := CanvasItemMaterial.new()
		gmat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		glow_tr.material = gmat
		var gt: Color = opaque_cloud_glow_tint
		glow_tr.modulate = Color(gt.r, gt.g, gt.b, clampf(opaque_cloud_glow_strength, 0.0, 1.0))
		wrapper.add_child(glow_tr)

	var tr := TextureRect.new()
	tr.texture = tex
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.modulate = modulate
	tr.custom_minimum_size = Vector2(cw, ch)
	tr.size = Vector2(cw, ch)
	tr.position = Vector2.ZERO
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wrapper.add_child(tr)
	_holder.add_child(wrapper)

	var tw_move := tween.tween_property(wrapper, "position", Vector2(end_x, y), move_dur)
	if delay_sec > 0.0:
		tw_move.set_delay(delay_sec)
	tw_move.set_trans(trans_type)
	tw_move.set_ease(ease_type)


func _title_label_settings(
	p_font: Font,
	font_px: int,
	outline_w: int,
	outline_col: Color,
	fill_col: Color,
	with_shadow: bool = true,
	shadow_strength: float = 1.0
) -> LabelSettings:
	var ls := LabelSettings.new()
	ls.font = p_font
	ls.font_size = font_px
	ls.font_color = fill_col
	ls.outline_size = outline_w
	ls.outline_color = outline_col
	# В части версий Godot у LabelSettings нет shadow_enabled — тень выключаем нулевым size / альфой.
	if with_shadow:
		var ss: float = clampf(shadow_strength, 0.0, 2.0)
		ls.shadow_color = Color(0.04, 0.06, 0.14, 0.55 * ss)
		ls.shadow_size = int(roundf(4.0 * ss))
		ls.shadow_offset = Vector2(1, 3) * ss
	else:
		ls.shadow_color = Color(0, 0, 0, 0)
		ls.shadow_size = 0
		ls.shadow_offset = Vector2.ZERO
	return ls


func _make_stacked_title_label(
	text: String,
	font_px: int,
	outline_w: int,
	outline_col: Color,
	fill_col: Color,
	with_shadow: bool = true,
	p_font: Font = TITLE_FONT_DISPLAY
) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl.label_settings = _title_label_settings(p_font, font_px, outline_w, outline_col, fill_col, with_shadow)
	return lbl


func _add_title(vw: float, vh: float) -> Control:
	_stop_title_motion()
	var lines: String = game_title_text.strip_edges()
	if lines.is_empty():
		lines = "Честь\nАвроры"

	var title_root := Control.new()
	title_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	title_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_root.set_meta(META_TITLE_OVERLAY, true)
	title_root.modulate = Color(1, 1, 1, 0)
	title_root.z_index = 500

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_root.add_child(center)

	var visual := VBoxContainer.new()
	visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	visual.add_theme_constant_override("separation", 14)
	center.add_child(visual)

	# Крупный заголовок: доля ширины экрана и потолок px.
	var base_px: int = int(clampf(vw * 0.102, 52.0, 168.0))
	var fill_a: float = clampf(title_fill_alpha, 0.0, 1.0)

	var stack := Control.new()
	stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var line_count: int = maxi(1, lines.split("\n").size())
	var stack_h: float = float(base_px) * (1.05 + float(line_count) * 1.22)
	var stack_w: float = minf(vw * 0.98, 1900.0)
	stack.custom_minimum_size = Vector2(stack_w, stack_h)
	stack.size = Vector2(stack_w, stack_h)

	# Сзади вперёд: холодный ореол, золотое кольцо, аддитивный заряд, основной текст.
	stack.add_child(
		_make_stacked_title_label(
			lines,
			base_px + 6,
			22,
			Color(0.38, 0.74, 1.0, 0.38),
			Color(1, 1, 1, 0.0)
		)
	)
	stack.add_child(
		_make_stacked_title_label(
			lines,
			base_px + 2,
			14,
			Color(1.0, 0.72, 0.38, 0.58),
			Color(1, 1, 1, 0.0)
		)
	)
	var charge := _make_stacked_title_label(
		lines,
		int(maxf(float(base_px) * 1.05, float(base_px + 1))),
		0,
		Color.TRANSPARENT,
		Color(0.55, 0.82, 1.0, 0.14),
		false
	)
	var ch_mat := CanvasItemMaterial.new()
	ch_mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	charge.material = ch_mat
	stack.add_child(charge)

	var main_fill := Color(1.0, 0.96, 0.88, fill_a)
	stack.add_child(
		_make_stacked_title_label(
			lines,
			base_px,
			5,
			Color(0.18, 0.28, 0.48, 0.92),
			main_fill
		)
	)

	visual.add_child(stack)

	var tag: String = game_title_tagline.strip_edges()
	if not tag.is_empty():
		var sub := Label.new()
		sub.text = "— %s —" % tag
		sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		sub.mouse_filter = Control.MOUSE_FILTER_IGNORE
		# Крупнее и контрастнее основного «тонкого» варианта — читаемость на облаках.
		var sub_px: int = maxi(26, int(float(base_px) * 0.38))
		sub.label_settings = _title_label_settings(
			TITLE_FONT_TAGLINE,
			sub_px,
			6,
			Color(0.03, 0.06, 0.2, 0.94),
			Color(0.99, 0.97, 0.93, 0.98),
			true,
			1.35
		)
		visual.add_child(sub)

	title_root.set_meta(META_TITLE_MOTION_VISUAL, visual)
	_holder.add_child(title_root)

	var _on_visual_resized := func() -> void:
		visual.pivot_offset = visual.size * 0.5
	visual.resized.connect(_on_visual_resized)
	_on_visual_resized.call()

	return title_root


func _stop_title_motion() -> void:
	if _title_motion_tween != null and _title_motion_tween.is_valid():
		_title_motion_tween.kill()
	_title_motion_tween = null


func _start_title_breath(visual: Control) -> void:
	if visual == null or not is_instance_valid(visual):
		return
	_stop_title_motion()
	var smax: float = maxf(1.001, title_breath_scale_max)
	var half: float = maxf(0.8, title_breath_period_sec) * 0.5
	_title_motion_tween = create_tween()
	_title_motion_tween.set_loops()
	_title_motion_tween.set_parallel(false)
	_title_motion_tween.set_trans(Tween.TRANS_SINE)
	_title_motion_tween.set_ease(Tween.EASE_IN_OUT)
	_title_motion_tween.tween_property(visual, "scale", Vector2(smax, smax), half)
	_title_motion_tween.tween_property(visual, "scale", Vector2(1.0, 1.0), half)


func play_cover() -> void:
	_ensure_holder()
	await get_tree().process_frame
	await get_tree().process_frame
	var vr := _visible_rect_strict()
	_apply_holder_to_visible_rect(vr)
	var vw: float = vr.size.x
	var vh: float = vr.size.y
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var row_count: int = _rows_for_height(vh)
	var cols: int = _cols_for_width(vw)
	var extra_n: int = maxi(0, extra_clouds)
	var fitted: Vector3i = _fit_counts_to_cap(row_count, cols, extra_n, maxi(1, max_clouds))
	row_count = fitted.x
	cols = fitted.y
	extra_n = fitted.z
	var entries: Array[Dictionary] = []
	for row in range(row_count):
		for col in range(cols):
			entries.append({"g": true, "row": row, "col": col})
	for n in range(extra_n):
		entries.append({"g": false, "n": n})
	var total_clouds: int = maxi(1, entries.size())
	var bleed: float = maxf(0.0, screen_edge_bleed_px)
	var pairs: Array[Dictionary] = _compute_checkerboard_placements(total_clouds, vw, vh, bleed, rng)
	pairs.shuffle()
	var cover_total: float = maxf(0.2, cover_total_sec)
	var n_clouds: int = pairs.size()
	var spread: float = clampf(stop_time_spread_sec, 0.0, maxf(0.0, cover_total - 0.05))
	var t_ends: Array[float] = []
	if n_clouds <= 1:
		t_ends.append(cover_total)
	else:
		var t0: float = cover_total - spread
		for k in range(n_clouds):
			var t_end: float = t0 + float(k) / float(n_clouds - 1) * spread
			t_ends.append(t_end)
		t_ends.shuffle()
	var tween := create_tween()
	tween.set_parallel(true)
	var opaque_flags: Array[bool] = _shuffled_opaque_flags(pairs.size(), rng)
	for idx in range(pairs.size()):
		var p: Dictionary = pairs[idx]
		var center: Vector2 = p["c"]
		var from_left: bool = bool(p["from_left"])
		var tex: Texture2D = CLOUD_TEXTURES[rng.randi() % CLOUD_TEXTURES.size()]
		var sz0: Vector2 = _scaled_cloud_size(tex)
		var cw: float = sz0.x
		var ch: float = sz0.y
		var end_pos: Vector2 = _center_to_top_left_clamped(center, cw, ch, vw, vh, bleed)
		var end_x: float = end_pos.x
		var y: float = end_pos.y
		# Левый поток визуально ниже правого: смещение на половину высоты спрайта (без зеркальной симметрии).
		if from_left:
			var lo_y: float = -bleed
			var hi_y: float = vh - ch + bleed
			y += ch * 0.5
			if hi_y >= lo_y:
				y = clampf(y, lo_y, hi_y)
		var depth_max: float = spawn_offscreen_depth_variance_px
		if from_left:
			depth_max *= rng.randf_range(0.72, 1.22)
		else:
			depth_max *= rng.randf_range(0.98, 1.58)
		var start_x: float = _spawn_x_left_local(cw, rng, depth_max) if from_left else _spawn_x_right_local(vw, cw, rng, depth_max)
		var delay_sec: float = 0.0
		var move_dur: float = t_ends[idx]
		var cloud_mod: Color = _cloud_layer_modulate(opaque_flags[idx], rng)
		_add_cloud(
			tween,
			tex,
			start_x,
			end_x,
			y,
			delay_sec,
			from_left,
			move_dur,
			Tween.TRANS_EXPO,
			Tween.EASE_OUT,
			cloud_mod
		)
	var title_root: Control = _add_title(vw, vh)
	var t_in: float = maxf(0.05, title_fade_in_sec)
	var step_in := tween.tween_property(title_root, "modulate", Color(1, 1, 1, 1), t_in)
	step_in.set_trans(Tween.TRANS_SINE)
	step_in.set_ease(Tween.EASE_IN_OUT)
	step_in.finished.connect(
		func() -> void:
			if not is_instance_valid(title_root):
				return
			var tv: Variant = title_root.get_meta(META_TITLE_MOTION_VISUAL, null)
			if tv is Control and is_instance_valid(tv):
				var tvc: Control = tv as Control
				tvc.pivot_offset = tvc.size * 0.5
				_start_title_breath(tvc)
	)
	await tween.finished


func play_exit() -> void:
	if _holder == null or not is_instance_valid(_holder):
		queue_free()
		return
	_stop_title_motion()
	_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var vr := _visible_rect_strict()
	var vw: float = vr.size.x
	var pad: float = maxf(_EDGE_INSET, exit_past_edge_px)
	var children: Array[Node] = _holder.get_children()
	var tw := create_tween()
	tw.set_parallel(true)
	tw.set_ease(Tween.EASE_IN)
	tw.set_trans(Tween.TRANS_QUAD)
	var n: int = children.size()
	var idx: int = 0
	for child in children:
		if child is Control and bool(child.get_meta(META_CLOUD_WRAPPER, false)):
			var from_left_w: bool = bool(child.get_meta(META_FROM_LEFT, true))
			var end_x_w: float = (-child.size.x - pad) if from_left_w else (vw + pad)
			var delay_w: float = float(idx) * exit_stagger_sec / float(max(1, n))
			idx += 1
			var step_w := tw.tween_property(child, "position:x", end_x_w, exit_duration_sec)
			step_w.set_delay(delay_w)
			continue
		if child is Control and bool(child.get_meta(META_TITLE_OVERLAY, false)):
			var t_out: float = maxf(0.05, title_fade_out_sec)
			var step_title := tw.tween_property(child, "modulate", Color(1, 1, 1, 0), t_out)
			step_title.set_trans(Tween.TRANS_SINE)
			step_title.set_ease(Tween.EASE_IN)
			continue
	await tw.finished
	queue_free()
