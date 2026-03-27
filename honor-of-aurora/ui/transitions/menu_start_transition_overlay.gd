extends CanvasLayer

## Переход «главное меню → игра»: облака заезжают с краёв, затем улетают.
## Те же текстуры, что в objects/clouds/cloud.tscn. Единый множитель cloud_visual_scale к размеру текстуры.
## Локальные координаты _holder: (0,0) — левый верх видимой области вьюпорта; размер = visible_rect.size (без vr.position — CanvasLayer уже в системе вьюпорта).
##
## Плотность: row_height_px × col_width_factor × extra. Конечные точки — 2D-сетка по всему экрану; сторона заезда — шахматно (col+row) % 2.
## Фаза наезда: старт без задержки; момент остановки размазан не более чем на stop_time_spread_sec (последний к cover_total_sec). Кривая: TRANS_EXPO, EASE_OUT.

const TITLE_TEXTURE: Texture2D = preload("res://ui/transitions/title_chest_avrory.png")

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
@export var cloud_visual_scale: float = 1.28
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

var _holder: Control


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
	ease_type: Tween.EaseType
) -> void:
	var sz: Vector2 = _scaled_cloud_size(tex)
	var cw: float = sz.x
	var ch: float = sz.y
	var tr := TextureRect.new()
	tr.texture = tex
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.modulate = Color(1, 1, 1, 1)
	tr.custom_minimum_size = Vector2(cw, ch)
	tr.size = Vector2(cw, ch)
	tr.position = Vector2(start_x, y)
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tr.set_meta(META_FROM_LEFT, from_left)
	_holder.add_child(tr)
	var tw_move := tween.tween_property(tr, "position", Vector2(end_x, y), move_dur)
	if delay_sec > 0.0:
		tw_move.set_delay(delay_sec)
	tw_move.set_trans(trans_type)
	tw_move.set_ease(ease_type)


func _add_title(vw: float, vh: float) -> TextureRect:
	var tr := TextureRect.new()
	tr.texture = TITLE_TEXTURE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tr.set_meta(META_TITLE_OVERLAY, true)
	tr.modulate = Color(1, 1, 1, 0)
	var tex_w: float = float(TITLE_TEXTURE.get_width())
	var tex_h: float = float(TITLE_TEXTURE.get_height())
	var max_w: float = vw * 0.72
	var s: float = clampf(max_w / maxf(1.0, tex_w), 0.35, 1.35)
	var rw: float = tex_w * s
	var rh: float = tex_h * s
	tr.custom_minimum_size = Vector2(rw, rh)
	tr.size = Vector2(rw, rh)
	tr.position = Vector2((vw - rw) * 0.5, (vh - rh) * 0.5)
	tr.z_index = 500
	_holder.add_child(tr)
	return tr


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
		var depth_max: float = spawn_offscreen_depth_variance_px
		if from_left:
			depth_max *= rng.randf_range(0.72, 1.22)
		else:
			depth_max *= rng.randf_range(0.98, 1.58)
		var start_x: float = _spawn_x_left_local(cw, rng, depth_max) if from_left else _spawn_x_right_local(vw, cw, rng, depth_max)
		var delay_sec: float = 0.0
		var move_dur: float = t_ends[idx]
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
			Tween.EASE_OUT
		)
	var title_rect: TextureRect = _add_title(vw, vh)
	var t_in: float = maxf(0.05, title_fade_in_sec)
	var step_in := tween.tween_property(title_rect, "modulate", Color(1, 1, 1, 1), t_in)
	step_in.set_trans(Tween.TRANS_SINE)
	step_in.set_ease(Tween.EASE_IN_OUT)
	await tween.finished


func play_exit() -> void:
	if _holder == null or not is_instance_valid(_holder):
		queue_free()
		return
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
		if child is TextureRect:
			var tr: TextureRect = child as TextureRect
			if bool(tr.get_meta(META_TITLE_OVERLAY, false)):
				var t_out: float = maxf(0.05, title_fade_out_sec)
				var step_fade := tw.tween_property(tr, "modulate", Color(1, 1, 1, 0), t_out)
				step_fade.set_trans(Tween.TRANS_SINE)
				step_fade.set_ease(Tween.EASE_IN)
				continue
			var from_left: bool = bool(tr.get_meta(META_FROM_LEFT, true))
			var end_x: float = (-tr.size.x - pad) if from_left else (vw + pad)
			var delay: float = float(idx) * exit_stagger_sec / float(max(1, n))
			idx += 1
			var step := tw.tween_property(tr, "position:x", end_x, exit_duration_sec)
			step.set_delay(delay)
	await tw.finished
	queue_free()
