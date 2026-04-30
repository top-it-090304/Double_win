extends Node2D
## Жёлтая «тропа» из пульсирующих точек, ведущая игрока к целевой точке (например, к целителю на старте).
##
## Использование:
##   var trail := BreadcrumbTrailScene.instantiate()
##   parent.add_child(trail)
##   trail.setup(start_global_pos, target_global_pos, "intro_base_island_done")
##
## Точки самостоятельно:
##   - вычисляют путь через NavigationServer2D (обходят воду, постройки и т.п.);
##   - пульсируют в противофазе бегущей волной;
##   - исчезают, когда игрок подходит к цели ближе DESPAWN_RADIUS_PX
##     или когда выставлен указанный story-флаг.

## Радиус, при сближении игрока с целью на котором тропа удаляется.
const DESPAWN_RADIUS_PX := 220.0
## Шаг между точками вдоль пути (в пикселях).
const DOT_SPACING_PX := 96.0
## Максимальное число точек в тропе (страховка от слишком длинного пути).
const MAX_DOTS := 64
## Радиус нарисованной точки.
const DOT_RADIUS_PX := 7.0
## Толщина внешнего кольца-обводки.
const DOT_OUTLINE_PX := 2.0
## Длительность одного цикла пульсации одной точки (сек).
const PULSE_PERIOD_SEC := 1.6
## Сдвиг фазы между соседними точками — даёт эффект «бегущей волны» к цели.
const PULSE_PHASE_PER_DOT := 0.18
## Цвет точек (тёплый жёлтый — стандартный «маршрут» в RPG).
const COLOR_DOT := Color(1.0, 0.88, 0.32, 1.0)
const COLOR_OUTLINE := Color(0.25, 0.18, 0.04, 0.85)
## Z-индекс — поверх земли/декора, но ниже HUD/CanvasLayer.
const Z_INDEX_TRAIL := 40
## Период проверки игрока (сек) — низкая частота, не нагружает физику.
const CHECK_INTERVAL_SEC := 0.25

var _dots: PackedVector2Array = PackedVector2Array()
var _target_pos: Vector2 = Vector2.ZERO
var _hide_flag: String = ""
var _phase_time: float = 0.0
var _check_accum: float = 0.0


func _ready() -> void:
	z_index = Z_INDEX_TRAIL
	z_as_relative = false
	## Не рендерим до setup() — иначе кадр кричащих нулей.
	visible = false


## Публичный API: расставить точки по пути от start_pos к target_pos и активировать тропу.
## hide_flag — story-флаг (StoryState), при выставлении которого тропа удалится.
func setup(start_pos: Vector2, target_pos: Vector2, hide_flag: String = "") -> void:
	_target_pos = target_pos
	_hide_flag = hide_flag
	_dots = _build_dots_along_path(start_pos, target_pos)
	if _dots.is_empty():
		queue_free()
		return
	visible = true
	queue_redraw()


func _build_dots_along_path(start_pos: Vector2, target_pos: Vector2) -> PackedVector2Array:
	var result := PackedVector2Array()
	var path := _compute_nav_path(start_pos, target_pos)
	if path.size() < 2:
		## Фолбэк: прямая линия (на случай, если навигация ещё не выпечена).
		path = PackedVector2Array([start_pos, target_pos])
	## Сэмплируем точки равномерно по длине ломаной.
	var total_len := 0.0
	var seg_lens := PackedFloat32Array()
	seg_lens.resize(path.size() - 1)
	for i in range(path.size() - 1):
		var l := path[i].distance_to(path[i + 1])
		seg_lens[i] = l
		total_len += l
	if total_len <= 1.0:
		return result
	## Не ставим точку прямо на старте (под ногами героя) и прямо на цели (на NPC).
	## Отступ вычисляется так, чтобы между «зарезервированными» зонами уместилось целое число шагов.
	var head_skip: float = clampf(48.0, 0.0, total_len * 0.5)
	var tail_skip: float = clampf(72.0, 0.0, total_len * 0.5)
	var usable: float = total_len - head_skip - tail_skip
	if usable <= DOT_SPACING_PX * 0.5:
		return result
	var n: int = int(floor(usable / DOT_SPACING_PX))
	n = clampi(n, 1, MAX_DOTS)
	for i in range(n):
		var t: float = head_skip + DOT_SPACING_PX * (float(i) + 0.5)
		var p: Vector2 = _point_at_distance(path, seg_lens, t)
		result.append(p)
	return result


func _compute_nav_path(start_pos: Vector2, target_pos: Vector2) -> PackedVector2Array:
	var world := get_world_2d()
	if world == null:
		return PackedVector2Array()
	var map_rid: RID = world.get_navigation_map()
	if not map_rid.is_valid():
		return PackedVector2Array()
	## Принудительное обновление карты — навигация в base_islad печётся в _ready через call_deferred,
	## без этого первый запрос пути может вернуть пусто.
	NavigationServer2D.map_force_update(map_rid)
	var s: Vector2 = NavigationServer2D.map_get_closest_point(map_rid, start_pos)
	var g: Vector2 = NavigationServer2D.map_get_closest_point(map_rid, target_pos)
	var path: PackedVector2Array = NavigationServer2D.map_get_path(map_rid, s, g, false, 1)
	if path.is_empty():
		path = NavigationServer2D.map_get_path(map_rid, s, g, true, 1)
	return path


static func _point_at_distance(
	path: PackedVector2Array, seg_lens: PackedFloat32Array, dist: float
) -> Vector2:
	var remaining: float = dist
	for i in range(seg_lens.size()):
		var l: float = seg_lens[i]
		if remaining <= l:
			var t: float = 0.0 if l <= 0.0001 else remaining / l
			return path[i].lerp(path[i + 1], t)
		remaining -= l
	return path[path.size() - 1]


func _process(delta: float) -> void:
	_phase_time += delta
	queue_redraw()
	_check_accum += delta
	if _check_accum < CHECK_INTERVAL_SEC:
		return
	_check_accum = 0.0
	_check_should_hide()


func _check_should_hide() -> void:
	if _hide_flag != "" and StoryState.has_flag(_hide_flag):
		queue_free()
		return
	var tree := get_tree()
	if tree == null:
		return
	var player := tree.get_first_node_in_group("player") as Node2D
	if player != null and is_instance_valid(player):
		if player.global_position.distance_to(_target_pos) <= DESPAWN_RADIUS_PX:
			queue_free()
			return


func _draw() -> void:
	if _dots.is_empty():
		return
	var two_pi: float = TAU
	for i in range(_dots.size()):
		var phase: float = _phase_time / PULSE_PERIOD_SEC + float(i) * PULSE_PHASE_PER_DOT
		var s: float = sin(phase * two_pi) * 0.5 + 0.5  # [0..1]
		var alpha: float = lerp(0.45, 1.0, s)
		var radius: float = DOT_RADIUS_PX * lerp(0.85, 1.15, s)
		var c_dot := COLOR_DOT
		c_dot.a = alpha
		var c_out := COLOR_OUTLINE
		c_out.a = alpha
		var p: Vector2 = _dots[i]
		draw_circle(p, radius + DOT_OUTLINE_PX, c_out)
		draw_circle(p, radius, c_dot)
