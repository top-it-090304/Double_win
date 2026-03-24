extends "res://characters/companion_unit.gd"

## Рудокоп на базе: бежит к шахте (камень рядом — молот), к деревьям (топор), к шахте (кирка); не «болтается».
## На острове — нож в бою и короткий «сбор».

enum BaseTaskKind { MINE, TREE, ROCK, MEAT }

enum BaseTool { PICKAXE, AXE, HAMMER, WOOD }

enum ShiftPhase { COOLDOWN, MOVE, WORK }

enum WorkerJob { ORE, MEAT, WOOD }

## Задача из диалога: руда (шахта), мясо (пастбище), дерево (западный маршрут).
var _worker_job: WorkerJob = WorkerJob.ORE

## 0 — кирка у шахты, 1 — молот по камням, 2 — снова кирка у шахты (цикл без смены дерева).
var _shift_seq: int = 0
var _shift_phase: ShiftPhase = ShiftPhase.COOLDOWN
var _shift_cd: float = 0.0
var _shift_target: Vector2 = Vector2.ZERO
var _shift_move_timer: float = 0.0
var _current_shift_kind: BaseTaskKind = BaseTaskKind.MINE
## Цепочка точек маршрута по маркерам WorkerNavPath (база), последняя — цель смены.
var _nav_chain: Array[Vector2] = []
var _nav_idx: int = 0

var _base_visual_tool: BaseTool = BaseTool.PICKAXE
var _base_work_playing: bool = false
var _base_work_site: Vector2 = Vector2.ZERO

var _pawn_cosmetic_busy: bool = false
var _scavenge_cd: float = 0.0

@export var shift_work_reach_px: float = 46.0
@export var shift_move_timeout_sec: float = 11.0
@export var rock_ring_min_px: float = 40.0
@export var rock_ring_max_px: float = 112.0
## Центр шахты + этот радиус: тайлы камня из `island/rocks/*`, по которым бьёт молот (если список не пуст).
@export var mine_rock_pick_radius_px: float = 520.0
## Первые N точек хребта — коридор от портала/спавна; пока рабочий в этом радиусе от них,
## индекс старта выбирается только среди этих точек (не по всей карте).
@export var worker_nav_entry_spine_count: int = 5
@export var worker_nav_spawn_corridor_radius_px: float = 720.0
## Если true — берём только контрольные точки Path2D (как в редакторе); иначе плотная выборка по длине кривой.
@export var worker_nav_prefer_curve_keypoints: bool = true
## Шаг выборки по длине кривой, если keypoints выключены.
@export var worker_nav_path_sample_spacing_px: float = 40.0
## Мясо (зоны 1–3) и дерево (зоны 1–7): запас до границы `Node_zone_*`.
@export var meat_mandatory_zone_reach_px: float = 58.0

## Смена «мясо»: зоны 1→2→3 — центр `CollisionShape2D` + радиус (как в сцене), затем овца.
var _meat_mandatory_zones: Array = []
var _meat_zone_idx: int = 0
## Смена «дерево»: зоны `Node_zone_1` … `Node_zone_6`, затем ближайшее дерево и рубка.
var _wood_mandatory_zones: Array = []
var _wood_zone_idx: int = 0


func _ready() -> void:
	speed = 120.0
	super._ready()
	_shift_cd = randf_range(0.4, 1.6)
	_scavenge_cd = randf_range(5.0, 11.0)
	add_to_group("ally_pawn")


func _capture_base_patrol_spawn_after_placed() -> void:
	super._capture_base_patrol_spawn_after_placed()
	var mc := _get_tilemap_layer_center_by_name(&"mine")
	if mc != Vector2.ZERO:
		_base_patrol_spawn = mc


func _get_tilemap_layer_center_by_name(layer_name: StringName) -> Vector2:
	var scene := get_tree().current_scene
	if scene == null:
		return Vector2.ZERO
	var tm := scene.find_child(String(layer_name), true, false) as TileMapLayer
	if tm == null:
		return Vector2.ZERO
	var cells := tm.get_used_cells()
	if cells.is_empty():
		return Vector2.ZERO
	var ts := Vector2(64, 64)
	if tm.tile_set:
		ts = Vector2(tm.tile_set.tile_size)
	var acc := Vector2.ZERO
	for c in cells:
		var local := tm.map_to_local(c) + ts * 0.5
		acc += tm.to_global(local)
	return acc / float(cells.size())


func _get_marker_global(group: StringName) -> Vector2:
	var n := get_tree().get_first_node_in_group(String(group)) as Node2D
	if n != null and is_instance_valid(n):
		return n.global_position
	return Vector2.ZERO


## Конец пути WorkerRoute2_wood (последняя точка кривой) — зона деревьев.
func _get_worker_route_wood_end_global() -> Vector2:
	var scene := get_tree().current_scene
	if scene == null:
		return Vector2.ZERO
	var path_root := scene.find_child("WorkerNavPath", true, false) as Node2D
	if path_root == null:
		return Vector2.ZERO
	var wood := path_root.get_node_or_null("WorkerRoute2_wood") as Path2D
	if wood == null or wood.curve == null:
		return Vector2.ZERO
	var c := wood.curve
	var n := c.get_point_count()
	if n < 2:
		return Vector2.ZERO
	return wood.to_global(c.get_point_position(n - 1))


func _get_site_for_task(kind: BaseTaskKind) -> Vector2:
	match kind:
		BaseTaskKind.MINE:
			return _get_tilemap_layer_center_by_name(&"mine")
		BaseTaskKind.TREE:
			var we := _get_worker_route_wood_end_global()
			if we != Vector2.ZERO:
				return we
			var t := _get_tilemap_layer_center_by_name(&"trees")
			if t != Vector2.ZERO:
				return t
			return _get_marker_global(&"worker_tree_site")
		BaseTaskKind.ROCK:
			var r := _get_tilemap_layer_center_by_name(&"rocks")
			if r != Vector2.ZERO:
				return r
			return _get_marker_global(&"worker_rock_site")
		BaseTaskKind.MEAT:
			var m := _get_marker_global(&"worker_meat_site")
			if m != Vector2.ZERO:
				return m
			var sh := _find_active_base_sheep()
			if sh != null:
				return sh.global_position
			return Vector2.ZERO
	return Vector2.ZERO


func _get_worker_rocks_root() -> Node:
	var scene := get_tree().current_scene
	if scene == null:
		return null
	var n := scene.get_node_or_null("island/rocks")
	if n != null:
		return n
	return scene.find_child("rocks", true, false)


func _append_rock_tile_centers_in_radius(tm: TileMapLayer, mine_center: Vector2, radius: float, out: Array[Vector2]) -> void:
	if tm == null:
		return
	var cells := tm.get_used_cells()
	if cells.is_empty():
		return
	var ts := Vector2(64, 64)
	if tm.tile_set:
		ts = Vector2(tm.tile_set.tile_size)
	var r2 := radius * radius
	for cell in cells:
		var wp: Vector2 = tm.to_global(tm.map_to_local(cell) + ts * 0.5)
		if wp.distance_squared_to(mine_center) <= r2:
			out.append(wp)


func _get_rock_world_positions_near_mine(mine_center: Vector2) -> Array[Vector2]:
	var rocks_root := _get_worker_rocks_root()
	if rocks_root == null:
		return []
	var out: Array[Vector2] = []
	var radius := maxf(64.0, mine_rock_pick_radius_px)
	if rocks_root is TileMapLayer:
		_append_rock_tile_centers_in_radius(rocks_root as TileMapLayer, mine_center, radius, out)
	for c in rocks_root.get_children():
		if c is TileMapLayer:
			_append_rock_tile_centers_in_radius(c as TileMapLayer, mine_center, radius, out)
	return out


func _rock_spot_near_mine(mine_center: Vector2) -> Vector2:
	var rock_cells := _get_rock_world_positions_near_mine(mine_center)
	if not rock_cells.is_empty():
		return rock_cells[randi() % rock_cells.size()]
	var w := _get_worker_nav_waypoints_for_task(BaseTaskKind.MINE)
	if w.size() >= 2:
		var hub := w[w.size() / 2]
		var d := hub - mine_center
		if d.length() > 32.0:
			return mine_center + d.normalized() * randf_range(rock_ring_min_px, mini(rock_ring_max_px, d.length() * 0.85))
	var ang := randf() * TAU
	var rad := randf_range(rock_ring_min_px, rock_ring_max_px)
	return mine_center + Vector2(cos(ang), sin(ang)) * rad


func _nav_marker_sort_key(n: Node) -> int:
	var s := str(n.name)
	if s.begins_with("Nav"):
		var rest := s.substr(3)
		if rest.is_valid_int():
			return int(rest)
	return 99999


func _keypoints_from_path2d(p: Path2D) -> Array[Vector2]:
	var curve := p.curve
	if curve == null:
		return []
	var n := curve.get_point_count()
	if n < 2:
		return []
	var out: Array[Vector2] = []
	for i in range(n):
		out.append(p.to_global(curve.get_point_position(i)))
	return out


func _sample_curve_path2d(p: Path2D) -> Array[Vector2]:
	var curve := p.curve
	if curve == null:
		return []
	var blen := curve.get_baked_length()
	if blen < 2.0:
		return []
	var spacing := maxf(20.0, worker_nav_path_sample_spacing_px)
	var out: Array[Vector2] = []
	var t := 0.0
	while t <= blen + 0.5:
		var loc := curve.sample_baked(minf(t, blen))
		out.append(p.to_global(loc))
		t += spacing
	if out.size() >= 2:
		return out
	return []


func _path2d_for_task(kind: BaseTaskKind, path_root: Node2D) -> Path2D:
	match kind:
		BaseTaskKind.TREE:
			var wood := path_root.get_node_or_null("WorkerRoute2_wood") as Path2D
			if wood != null:
				return wood
		BaseTaskKind.MEAT:
			var meat_route := path_root.get_node_or_null("WorkerRoute_meat") as Path2D
			if meat_route != null:
				return meat_route
			var mine_fallback := path_root.get_node_or_null("WorkerRoute_mine") as Path2D
			if mine_fallback != null:
				return mine_fallback
		_:
			var mine := path_root.get_node_or_null("WorkerRoute_mine") as Path2D
			if mine != null:
				return mine
	return path_root.get_node_or_null("WorkerRoute_mine") as Path2D


func _get_worker_nav_waypoints_for_task(kind: BaseTaskKind) -> Array[Vector2]:
	var scene := get_tree().current_scene
	if scene == null:
		return []
	var path_root := scene.find_child("WorkerNavPath", true, false) as Node2D
	if path_root == null:
		return []
	var route := _path2d_for_task(kind, path_root)
	if route != null:
		if worker_nav_prefer_curve_keypoints:
			var kp := _keypoints_from_path2d(route)
			if kp.size() >= 2:
				return kp
		var baked := _sample_curve_path2d(route)
		if baked.size() >= 2:
			return baked
	var nodes: Array[Node] = []
	for c in path_root.get_children():
		if c is Marker2D and str(c.name).begins_with("Nav"):
			nodes.append(c)
	nodes.sort_custom(func(a, b): return _nav_marker_sort_key(a) < _nav_marker_sort_key(b))
	var out: Array[Vector2] = []
	for c in nodes:
		out.append((c as Node2D).global_position)
	return out


func _nearest_waypoint_index(p: Vector2, w: Array[Vector2]) -> int:
	if w.is_empty():
		return 0
	var best := 0
	var bd := INF
	for i in range(w.size()):
		var d := p.distance_squared_to(w[i])
		if d < bd:
			bd = d
			best = i
	return best


func _spine_start_index(from: Vector2, w: Array[Vector2]) -> int:
	if w.is_empty():
		return 0
	var entry_n: int = mini(maxi(worker_nav_entry_spine_count, 1), w.size())
	var near_corridor := false
	for i in range(entry_n):
		if from.distance_to(w[i]) <= worker_nav_spawn_corridor_radius_px:
			near_corridor = true
			break
	if not near_corridor:
		return _nearest_waypoint_index(from, w)
	var best := 0
	var bd := INF
	for i in range(entry_n):
		var d := from.distance_squared_to(w[i])
		if d < bd:
			bd = d
			best = i
	return best


func _build_nav_chain(from: Vector2, to: Vector2, kind: BaseTaskKind) -> Array[Vector2]:
	var w := _get_worker_nav_waypoints_for_task(kind)
	if w.is_empty():
		return [to]
	var i0 := _spine_start_index(from, w)
	var i1 := _nearest_waypoint_index(to, w)
	## Дерево: если рабочий уже у конца хребта (после зон), а дерево ближе к более ранней точке кривой,
	## i0 > i1 — иначе цепочка вела бы НАЗАД по Nav* (разворот и бесконечный бег).
	if kind == BaseTaskKind.TREE and i0 > i1:
		return [to]
	if i0 == i1:
		var out_same: Array[Vector2] = []
		if from.distance_to(w[i0]) > shift_work_reach_px * 0.75:
			out_same.append(w[i0])
		out_same.append(to)
		return out_same
	var chain: Array[Vector2] = []
	if i0 < i1:
		for i in range(i0, i1 + 1):
			chain.append(w[i])
	else:
		for i in range(i0, i1 - 1, -1):
			chain.append(w[i])
	chain.append(to)
	return chain


func _set_tool_for_task(kind: BaseTaskKind) -> void:
	match kind:
		BaseTaskKind.MINE:
			_base_visual_tool = BaseTool.PICKAXE
		BaseTaskKind.TREE:
			_base_visual_tool = BaseTool.AXE
		BaseTaskKind.ROCK:
			_base_visual_tool = BaseTool.HAMMER
		BaseTaskKind.MEAT:
			_base_visual_tool = BaseTool.PICKAXE


## Назначение смены из окна приказов (строки: ore / meat / wood).
func set_worker_job_from_dialogue(key: String) -> void:
	var j := WorkerJob.ORE
	match key:
		"meat":
			j = WorkerJob.MEAT
		"wood":
			j = WorkerJob.WOOD
		"ore", _:
			j = WorkerJob.ORE
	if _worker_job == j:
		return
	_worker_job = j
	_shift_seq = 0
	_interrupt_base_shift()
	_shift_cd = 0.35


func get_worker_job_name() -> String:
	match _worker_job:
		WorkerJob.MEAT:
			return "meat"
		WorkerJob.WOOD:
			return "wood"
		_:
			return "ore"


## Слой mine_off: «шахта выключена», пока ни у кого не назначена добыча руды (не фаза анимации конкретного юнита).
func is_assigned_to_ore_mining() -> bool:
	if Events.current_location != Events.LOCATION.BASE:
		return false
	return _worker_job == WorkerJob.ORE


## Для UI: "cooldown" | "move" | "work" | "".
func get_base_shift_phase_name() -> String:
	if Events.current_location != Events.LOCATION.BASE:
		return ""
	match _shift_phase:
		ShiftPhase.COOLDOWN:
			return "cooldown"
		ShiftPhase.MOVE:
			return "move"
		ShiftPhase.WORK:
			return "work"
	return ""


## Для UI: текущая задача смены — "mine" | "rock" | "tree" | "".
func get_base_shift_task_name() -> String:
	if Events.current_location != Events.LOCATION.BASE:
		return ""
	match _current_shift_kind:
		BaseTaskKind.MINE:
			return "mine"
		BaseTaskKind.ROCK:
			return "rock"
		BaseTaskKind.TREE:
			return "tree"
		BaseTaskKind.MEAT:
			return "meat"
	return ""


func _interact_anim_for_task(kind: BaseTaskKind) -> StringName:
	match kind:
		BaseTaskKind.MINE:
			return &"interact_pickaxe"
		BaseTaskKind.TREE:
			return &"interact_axe"
		BaseTaskKind.ROCK:
			return &"interact_hammer"
		BaseTaskKind.MEAT:
			return &"interact_knife"
	return &"interact_pickaxe"


func _shift_cycle_len() -> int:
	match _worker_job:
		WorkerJob.ORE:
			return 3
		_:
			return 1


func _shift_kind_at_seq(seq: int) -> BaseTaskKind:
	match _worker_job:
		WorkerJob.WOOD:
			return BaseTaskKind.TREE
		WorkerJob.MEAT:
			return BaseTaskKind.MEAT
		_:
			match seq % 3:
				0, 2:
					return BaseTaskKind.MINE
				1:
					return BaseTaskKind.ROCK
	return BaseTaskKind.MINE


func _base_tool_for_shift_kind(kind: BaseTaskKind) -> BaseTool:
	match kind:
		BaseTaskKind.MINE:
			return BaseTool.PICKAXE
		BaseTaskKind.ROCK:
			return BaseTool.HAMMER
		BaseTaskKind.TREE:
			return BaseTool.AXE
		BaseTaskKind.MEAT:
			return BaseTool.PICKAXE
	return BaseTool.PICKAXE


func _apply_idle_tool_for_current_shift() -> void:
	_base_visual_tool = _base_tool_for_shift_kind(_shift_kind_at_seq(_shift_seq))


func _resolve_work_animation(kind: BaseTaskKind) -> StringName:
	var want := _interact_anim_for_task(kind)
	if sprite == null or sprite.sprite_frames == null:
		return want
	if sprite.sprite_frames.has_animation(want):
		return want
	var fallbacks: Array[StringName] = []
	match kind:
		BaseTaskKind.ROCK:
			fallbacks = [&"interact_hammer", &"interact_pickaxe", &"interact_axe"]
		BaseTaskKind.MINE:
			fallbacks = [&"interact_pickaxe", &"interact_hammer"]
		BaseTaskKind.TREE:
			fallbacks = [&"interact_axe", &"interact_pickaxe"]
		BaseTaskKind.MEAT:
			fallbacks = [&"interact_knife", &"interact_pickaxe", &"interact_axe"]
	for a in fallbacks:
		if sprite.sprite_frames.has_animation(a):
			return a
	return want


func _idle_anim() -> StringName:
	if Events.current_location == Events.LOCATION.BASE:
		if _worker_job == WorkerJob.MEAT:
			return &"idle_knife"
		match _base_visual_tool:
			BaseTool.AXE:
				return &"idle_axe"
			BaseTool.HAMMER:
				return &"idle_hammer"
			BaseTool.WOOD:
				return &"idle_wood"
			_:
				return &"idle_pickaxe"
	return &"idle_knife"


func _run_anim() -> StringName:
	if Events.current_location == Events.LOCATION.BASE:
		if _worker_job == WorkerJob.MEAT:
			return &"run_knife"
		match _base_visual_tool:
			BaseTool.AXE:
				return &"run_axe"
			BaseTool.HAMMER:
				return &"run_hammer"
			BaseTool.WOOD:
				return &"run_wood"
			_:
				return &"run_pickaxe"
	return &"run_knife"


func _get_melee_hit_reach() -> float:
	return 58.0


func _get_melee_hit_radius() -> float:
	return 20.0


func _attack_anim_for_direction(_dir: Vector2) -> StringName:
	return &"interact_knife"


func _interrupt_base_shift() -> void:
	_base_work_playing = false
	_shift_phase = ShiftPhase.COOLDOWN
	_shift_cd = 0.6
	_shift_move_timer = 0.0
	_nav_chain.clear()
	_nav_idx = 0
	_meat_mandatory_zones.clear()
	_meat_zone_idx = 0
	_wood_mandatory_zones.clear()
	_wood_zone_idx = 0


func _process_follow_custom(delta: float) -> bool:
	var enemy := _nearest_enemy_in_attack_area()
	if enemy and _attack_cd <= 0.0 and attack_area:
		_interrupt_base_shift()
		_pawn_cosmetic_busy = false
		return false
	if state != State.FOLLOW:
		return false
	## На базе смена (шахта / лес / стадо) не зависит от режима отряда — только от выбора в диалоге.
	if Events.current_location == Events.LOCATION.BASE:
		return _process_base_shift_fsm(delta)
	if SquadOrders.mode == SquadOrders.Mode.HOLD:
		return false
	if Events.is_adventure_location(Events.current_location):
		return _process_island_scavenge(delta)
	return false


func _process_base_shift_fsm(delta: float) -> bool:
	match _shift_phase:
		ShiftPhase.COOLDOWN:
			_shift_cd -= delta
			if _shift_cd > 0.0:
				velocity = Vector2.ZERO
				_apply_idle_tool_for_current_shift()
				_play_idle()
				return true
			_shift_try_start_move()
			return true
		ShiftPhase.MOVE:
			if _worker_job == WorkerJob.MEAT:
				return _process_meat_shift_move(delta)
			if _worker_job == WorkerJob.WOOD:
				return _process_wood_shift_move(delta)
			var aim: Vector2 = _shift_target
			if not _nav_chain.is_empty() and _nav_idx < _nav_chain.size():
				aim = _nav_chain[_nav_idx]
			var to := aim - global_position
			if to.length() <= shift_work_reach_px:
				_nav_idx += 1
				if _nav_chain.is_empty() or _nav_idx >= _nav_chain.size():
					_shift_begin_work()
				return true
			velocity = to.normalized() * speed
			_face_velocity(velocity)
			_play_run()
			_shift_move_timer += delta
			if _shift_move_timer >= shift_move_timeout_sec:
				_interrupt_base_shift()
				_shift_cd = 2.0
			return true
		ShiftPhase.WORK:
			if _base_work_playing:
				velocity = Vector2.ZERO
				_face_work_site(_base_work_site)
				return true
			velocity = Vector2.ZERO
			_play_idle()
			return true
	return false


func _shift_try_start_move() -> void:
	var mine_center := _get_tilemap_layer_center_by_name(&"mine")
	match _worker_job:
		WorkerJob.WOOD:
			_current_shift_kind = BaseTaskKind.TREE
			_set_tool_for_task(BaseTaskKind.TREE)
			_wood_mandatory_zones = _get_mandatory_zone_globals(1, 7)
			_wood_zone_idx = 0
			_nav_chain.clear()
			_nav_idx = 0
			_shift_target = Vector2.ZERO
			_base_work_site = Vector2.ZERO
			_shift_phase = ShiftPhase.MOVE
			_shift_move_timer = 0.0
			return
		WorkerJob.MEAT:
			var sh := _find_active_base_sheep()
			if sh == null:
				_shift_phase = ShiftPhase.COOLDOWN
				_shift_cd = 3.0
				return
			_current_shift_kind = BaseTaskKind.MEAT
			var tm: Vector2 = sh.global_position
			_shift_target = tm
			_base_work_site = tm
			_set_tool_for_task(BaseTaskKind.MEAT)
			_nav_chain.clear()
			_nav_idx = 0
			_meat_mandatory_zones = _get_mandatory_zone_globals(1, 3)
			_meat_zone_idx = 0
			_shift_phase = ShiftPhase.MOVE
			_shift_move_timer = 0.0
			return
		_:
			pass
	for k in range(3):
		var slot: int = (_shift_seq + k) % 3
		var kind: BaseTaskKind = BaseTaskKind.MINE
		var target: Vector2 = Vector2.ZERO
		match slot:
			0, 2:
				if mine_center == Vector2.ZERO:
					continue
				kind = BaseTaskKind.MINE
				target = mine_center
			1:
				if mine_center == Vector2.ZERO:
					continue
				kind = BaseTaskKind.ROCK
				target = _rock_spot_near_mine(mine_center)
		_current_shift_kind = kind
		_shift_target = target
		_base_work_site = target
		_set_tool_for_task(kind)
		_nav_chain = _build_nav_chain(global_position, target, kind)
		_nav_idx = 0
		_shift_phase = ShiftPhase.MOVE
		_shift_move_timer = 0.0
		return
	_shift_phase = ShiftPhase.COOLDOWN
	_shift_cd = 4.0


func _shift_begin_work() -> void:
	var anim := _resolve_work_animation(_current_shift_kind)
	if sprite == null or sprite.sprite_frames == null or not sprite.sprite_frames.has_animation(anim):
		_interrupt_base_shift()
		_shift_cd = 2.0
		return
	_shift_phase = ShiftPhase.WORK
	_base_work_playing = true
	_base_work_site = _shift_target
	sprite.play(anim)


func _face_work_site(site: Vector2) -> void:
	if site == Vector2.ZERO or sprite == null:
		return
	var dx := site.x - global_position.x
	if absf(dx) > 2.0:
		sprite.flip_h = dx < 0.0


func _face_toward_point(p: Vector2) -> void:
	if sprite == null:
		return
	var dx := p.x - global_position.x
	if absf(dx) > 2.0:
		sprite.flip_h = dx < 0.0


func _meat_zone_waypoint(zone: Node2D) -> Vector2:
	var cs := zone.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if cs != null:
		return cs.global_position
	return zone.global_position


func _meat_zone_radius(zone: Node2D) -> float:
	var cs := zone.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if cs != null and cs.shape is CircleShape2D:
		return (cs.shape as CircleShape2D).radius
	if cs != null and cs.shape is RectangleShape2D:
		var sz := (cs.shape as RectangleShape2D).size
		return maxf(sz.x, sz.y) * 0.5
	return 0.0


## Узлы `Node_zone_{first}` … `Node_zone_{last}` (или `node_zone_*`) — только существующие в сцене, по порядку.
func _get_mandatory_zone_globals(first: int, last: int) -> Array:
	var scene := get_tree().current_scene
	if scene == null:
		return []
	var out: Array = []
	for i in range(first, last + 1):
		var nm := "Node_zone_%d" % i
		var z: Node = scene.get_node_or_null(nm)
		if z == null:
			z = scene.find_child(nm, true, false)
		if z == null:
			z = scene.find_child(nm.to_lower(), true, false)
		if z == null:
			continue
		if z is Node2D:
			var zn := z as Node2D
			out.append({"pos": _meat_zone_waypoint(zn), "radius": _meat_zone_radius(zn)})
	return out


func _find_active_base_sheep() -> Node2D:
	var best: Node2D = null
	var bd := INF
	for n in get_tree().get_nodes_in_group("base_sheep"):
		if not n is Node2D:
			continue
		if n.has_method("is_alive_for_meat") and not n.is_alive_for_meat():
			continue
		var n2: Node2D = n as Node2D
		var d := global_position.distance_squared_to(n2.global_position)
		if d < bd:
			bd = d
			best = n2
	return best


func _find_nearest_wood_tree_global() -> Vector2:
	var best: Vector2 = Vector2.ZERO
	var bd := INF
	var found := false
	for n in get_tree().get_nodes_in_group("wood_tree_resource"):
		if not n is Node2D:
			continue
		var n2: Node2D = n as Node2D
		var d := global_position.distance_squared_to(n2.global_position)
		if d < bd:
			bd = d
			best = n2.global_position
			found = true
	if not found:
		return Vector2.ZERO
	return best


## Совпадает с радиусом удара в `wood_tree_chop.gd` (58), шире чем `shift_work_reach_px` у точек маршрута.
func _wood_chop_reach_px() -> float:
	return maxf(shift_work_reach_px * 1.35, 58.0)


func _process_wood_shift_move(delta: float) -> bool:
	if _wood_zone_idx < _wood_mandatory_zones.size():
		var zd: Dictionary = _wood_mandatory_zones[_wood_zone_idx]
		var wp: Vector2 = zd["pos"]
		var zr: float = zd["radius"]
		var to_z := wp - global_position
		var dz := to_z.length()
		if dz <= zr + meat_mandatory_zone_reach_px:
			_wood_zone_idx += 1
			_shift_move_timer = 0.0
			return true
		velocity = to_z.normalized() * speed
		_face_velocity(velocity)
		_play_run()
		_shift_move_timer += delta
		if _shift_move_timer >= shift_move_timeout_sec:
			_interrupt_base_shift()
			_shift_cd = 2.0
		return true
	if _nav_chain.is_empty():
		var tree_pos := _find_nearest_wood_tree_global()
		if tree_pos == Vector2.ZERO:
			velocity = Vector2.ZERO
			_apply_idle_tool_for_current_shift()
			_play_idle()
			_shift_move_timer += delta
			if _shift_move_timer >= shift_move_timeout_sec:
				_interrupt_base_shift()
				_shift_cd = 2.0
			return true
		_shift_target = tree_pos
		_base_work_site = tree_pos
		_nav_chain = _build_nav_chain(global_position, tree_pos, BaseTaskKind.TREE)
		_nav_idx = 0
		_shift_move_timer = 0.0
	## Как в wood_tree_chop (58 px): не требуем точного попадания в последнюю точку хребта — иначе вечный run_axe.
	if _shift_target != Vector2.ZERO and global_position.distance_to(_shift_target) <= _wood_chop_reach_px():
		_shift_begin_work()
		return true
	var aim: Vector2 = _shift_target
	if not _nav_chain.is_empty() and _nav_idx < _nav_chain.size():
		aim = _nav_chain[_nav_idx]
	var to := aim - global_position
	if to.length() <= shift_work_reach_px:
		_nav_idx += 1
		if _nav_chain.is_empty() or _nav_idx >= _nav_chain.size():
			_shift_begin_work()
		return true
	velocity = to.normalized() * speed
	_face_velocity(velocity)
	_play_run()
	_shift_move_timer += delta
	if _shift_move_timer >= shift_move_timeout_sec:
		_interrupt_base_shift()
		_shift_cd = 2.0
	return true


func _process_meat_shift_move(delta: float) -> bool:
	var sheep := _find_active_base_sheep()
	if sheep == null:
		velocity = Vector2.ZERO
		_apply_idle_tool_for_current_shift()
		_play_idle()
		_shift_move_timer += delta
		if _shift_move_timer >= shift_move_timeout_sec:
			_interrupt_base_shift()
			_shift_cd = 2.0
		return true
	if _meat_zone_idx < _meat_mandatory_zones.size():
		var zd: Dictionary = _meat_mandatory_zones[_meat_zone_idx]
		var wp: Vector2 = zd["pos"]
		var zr: float = zd["radius"]
		var to_z := wp - global_position
		var dz := to_z.length()
		if dz <= zr + meat_mandatory_zone_reach_px:
			_meat_zone_idx += 1
			_shift_move_timer = 0.0
			return true
		velocity = to_z.normalized() * speed
		_face_velocity(velocity)
		_play_run()
		_shift_move_timer += delta
		if _shift_move_timer >= shift_move_timeout_sec:
			_interrupt_base_shift()
			_shift_cd = 2.0
		return true
	var goal := sheep.global_position
	var calm: bool = false
	if sheep.has_method("is_calm_for_slaughter"):
		calm = sheep.is_calm_for_slaughter()
	var to := goal - global_position
	var dist := to.length()
	if calm and dist <= shift_work_reach_px * 1.25:
		_shift_target = goal
		_base_work_site = goal
		_shift_begin_work()
		return true
	if dist > 8.0:
		velocity = to.normalized() * speed
		_face_velocity(velocity)
		_play_run()
	else:
		velocity = Vector2.ZERO
		_face_toward_point(goal)
		_play_run()
	_shift_move_timer += delta
	if _shift_move_timer >= shift_move_timeout_sec:
		_interrupt_base_shift()
		_shift_cd = 2.0
	return true


func _process_island_scavenge(delta: float) -> bool:
	if _pawn_cosmetic_busy:
		velocity = Vector2.ZERO
		return true
	_scavenge_cd -= delta
	if _scavenge_cd > 0.0:
		return false
	if player == null or not is_instance_valid(player):
		return false
	if player is CharacterBody2D and (player as CharacterBody2D).velocity.length() > 38.0:
		_scavenge_cd = 2.0
		return false
	if global_position.distance_to(player.global_position) > 230.0:
		_scavenge_cd = 2.5
		return false
	_pawn_cosmetic_busy = true
	_scavenge_cd = randf_range(14.0, 24.0)
	var anims: Array[StringName] = [&"interact_hammer", &"interact_axe", &"interact_pickaxe"]
	var pick: StringName = anims[randi() % anims.size()]
	if sprite and sprite.sprite_frames:
		if sprite.sprite_frames.has_animation(pick):
			sprite.play(pick)
		elif sprite.sprite_frames.has_animation(&"interact_hammer"):
			sprite.play(&"interact_hammer")
		else:
			_pawn_cosmetic_busy = false
			return false
	return true


func _on_sprite_animation_finished() -> void:
	if _pawn_cosmetic_busy:
		_pawn_cosmetic_busy = false
		_play_idle()
		return
	if _base_work_playing:
		_base_work_playing = false
		if Events.current_location == Events.LOCATION.BASE and _worker_job == WorkerJob.ORE and _current_shift_kind == BaseTaskKind.MINE:
			GameManager.add_ore(1)
		_shift_seq = (_shift_seq + 1) % _shift_cycle_len()
		_shift_phase = ShiftPhase.COOLDOWN
		_shift_cd = randf_range(1.2, 2.8)
		_base_work_site = Vector2.ZERO
		_apply_idle_tool_for_current_shift()
		_play_idle()
		return
	super._on_sprite_animation_finished()
