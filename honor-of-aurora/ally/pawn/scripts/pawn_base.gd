extends "res://characters/companion_unit.gd"

## Спутник: на базовом острове — добыча по `WorkerJob`.
## По умолчанию путь по `NavigationServer2D.map_get_path` (сетка с базы, выпечка из коллизий).
## Запасной режим: `base_worker_use_physics_steering` — только лучи, без глобального пути.

enum WorkerJob { ORE, MEAT, WOOD }

enum BaseWorkerState { IDLE, MOVE, GATHER, COOLDOWN }

var _worker_job: WorkerJob = WorkerJob.ORE
var _pawn_cosmetic_busy: bool = false

var _base_worker_state: BaseWorkerState = BaseWorkerState.IDLE
var _gather_target: Vector2 = Vector2.ZERO
var _gather_cd: float = 0.0
var _move_timeout: float = 0.0
var _island_gathering: bool = false
var _move_stuck_frames: int = 0
var _srv_path: PackedVector2Array = PackedVector2Array()
var _srv_path_idx: int = 0
var _path_repath_timer: float = 0.0
var _meat_chase_node: Node2D = null
var _meat_chase_repath_cd: float = 0.0
## Дальность луча: не меньше этого и ~0.2 с полёта — иначе упирается в углы.
const _STEER_LOOKAHEAD_MIN: float = 88.0
const _STEER_LOOKAHEAD_SPEED_MUL: float = 0.22
## Полуширина «тела» для трёх параллельных лучей (примерно радиус коллайдера).
const _STEER_BODY_HALF_WIDTH: float = 10.0
## Следование по map_get_path: не пропускать точки слишком рано — иначе «врезается» в углы.
const _BASE_NAV_WP_ADVANCE_DIST: float = 14.0
var _base_nav_region: NavigationRegion2D = null
## Вкл: только локальные лучи (часто упирается в углы). Выкл = путь по навигационной сетке с базы.
@export var base_worker_use_physics_steering: bool = false
## Вкл только если `base_worker_use_physics_steering` выкл и на сцене есть NavigationRegion2D.
@export var base_move_use_navigation_agent_path: bool = false
@export var base_move_use_map_force_update: bool = false
@onready var _nav_agent: NavigationAgent2D = $NavigationAgent2D


func _ready() -> void:
	speed = 120.0
	super._ready()
	## Углы и выступы: больше попыток скольжения за кадр, чем у дефолта (4).
	max_slides = 6
	add_to_group("ally_pawn")
	if _nav_agent:
		_nav_agent.path_desired_distance = 16.0
		_nav_agent.target_desired_distance = 28.0
		_nav_agent.path_max_distance = 2000.0
		_nav_agent.avoidance_enabled = false
	call_deferred("_sync_nav_agent_start_position")
	call_deferred("_sync_nav_layers_with_island_region")
	Events.base_island_meat_collected.connect(_on_base_island_meat_collected)


func _on_base_island_meat_collected() -> void:
	if Events.current_location != Events.LOCATION.BASE:
		return
	if _worker_job != WorkerJob.MEAT:
		return
	_cancel_base_worker()


func _sync_nav_agent_start_position() -> void:
	if _nav_agent and is_instance_valid(_nav_agent):
		_nav_agent.target_position = global_position


func _sync_nav_layers_with_island_region() -> void:
	## Слои агента должны совпадать с NavigationRegion2D, иначе map_get_path не видит твои полигоны.
	if _nav_agent == null or not is_instance_valid(_nav_agent):
		return
	var scene := get_tree().current_scene
	if scene == null:
		return
	var nr := scene.find_child("IslandNavigationRegion", true, false)
	if nr is NavigationRegion2D:
		_base_nav_region = nr as NavigationRegion2D
		_nav_agent.navigation_layers = _base_nav_region.navigation_layers


func _apply_nav_layers_from_region() -> void:
	if _nav_agent == null or not is_instance_valid(_nav_agent):
		return
	if _base_nav_region != null and is_instance_valid(_base_nav_region):
		_nav_agent.navigation_layers = _base_nav_region.navigation_layers
		return
	var scene := get_tree().current_scene
	if scene == null:
		return
	var nr := scene.find_child("IslandNavigationRegion", true, false)
	if nr is NavigationRegion2D:
		_base_nav_region = nr as NavigationRegion2D
		_nav_agent.navigation_layers = _base_nav_region.navigation_layers


func _exit_tree() -> void:
	if Events.base_island_meat_collected.is_connected(_on_base_island_meat_collected):
		Events.base_island_meat_collected.disconnect(_on_base_island_meat_collected)


func _physics_process(delta: float) -> void:
	var pos_before := global_position
	super._physics_process(delta)
	if _nav_agent and is_instance_valid(_nav_agent):
		_nav_agent.velocity = velocity
	if _base_worker_state == BaseWorkerState.MOVE and velocity.length_squared() > 100.0:
		var moved := global_position.distance_to(pos_before)
		if moved < 0.45:
			_move_stuck_frames += 1
		else:
			_move_stuck_frames = 0


func _steer_probe_origin() -> Vector2:
	var cs := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if cs != null and is_instance_valid(cs):
		return cs.global_position
	return global_position


func _lookahead_distance() -> float:
	return maxf(_STEER_LOOKAHEAD_MIN, speed * _STEER_LOOKAHEAD_SPEED_MUL)


## Те же слои, что у тела — иначе лучи «не видят» стены тайлмапа, а CharacterBody2D в них упирается.
func _wall_probe_collision_mask() -> int:
	return collision_mask


func _ray_wall_blocked(dir: Vector2, distance: float) -> bool:
	if dir.length_squared() < 1e-8:
		return true
	var d := dir.normalized()
	var space := get_world_2d().direct_space_state
	var perp := Vector2(-d.y, d.x)
	var origin_base := _steer_probe_origin()
	var dist := maxf(24.0, distance)
	for lateral: float in [-_STEER_BODY_HALF_WIDTH, 0.0, _STEER_BODY_HALF_WIDTH]:
		var start: Vector2 = origin_base + perp * lateral + d * 8.0
		var end: Vector2 = start + d * dist
		var params := PhysicsRayQueryParameters2D.create(start, end)
		params.collision_mask = _wall_probe_collision_mask()
		params.hit_from_inside = true
		params.exclude = [get_rid()]
		if space.intersect_ray(params) != null:
			return true
	return false


func _steer_toward_goal(goal_global: Vector2) -> Vector2:
	var to_goal := goal_global - global_position
	var hint := to_goal.normalized() if to_goal.length_squared() > 4.0 else Vector2.RIGHT
	var look := _lookahead_distance()
	if not _ray_wall_blocked(hint, look):
		return hint
	var best := hint
	var best_dot := -2.0
	## Плотный веер к цели (±90°): выбираем свободное направление с максимальным dot к цели.
	for i in range(-18, 19):
		if i == 0:
			continue
		var ang := float(i) * (PI / 18.0)
		var dd := hint.rotated(ang)
		if not _ray_wall_blocked(dd, look):
			var dot: float = dd.dot(hint)
			if dot > best_dot:
				best_dot = dot
				best = dd
	if best_dot > -1.55:
		return best
	## Узкий коридор: короче луч, чуть другой угол.
	for i in range(-36, 37):
		if i == 0:
			continue
		var ang2 := float(i) * (PI / 36.0)
		var dd2 := hint.rotated(ang2)
		if not _ray_wall_blocked(dd2, look * 0.82):
			var dot2: float = dd2.dot(hint)
			if dot2 > best_dot:
				best_dot = dot2
				best = dd2
	if best_dot > -1.85:
		return best
	## Нельзя возвращать hint — это прямо в стену. Боковины ±90°, потом любой свободный луч.
	for sgn in [-1.0, 1.0]:
		var side: Vector2 = hint.rotated(sgn * PI * 0.5)
		if not _ray_wall_blocked(side, look * 0.7):
			return side
	for i in range(0, 16):
		var ang3 := float(i) * (PI / 8.0)
		var dd3 := Vector2.RIGHT.rotated(ang3)
		if not _ray_wall_blocked(dd3, look * 0.55):
			return dd3
	return hint.rotated(PI * 0.5)


func _nav_fallback_velocity() -> Vector2:
	return _steer_toward_goal(_gather_target) * speed


func _apply_base_move_wall_slide() -> void:
	if not is_on_wall():
		return
	var n := get_wall_normal()
	if n.length_squared() < 0.01:
		return
	velocity = velocity.slide(n)
	if velocity.length_squared() < 400.0:
		var to_g := _gather_target - global_position
		var tangent := Vector2(-n.y, n.x)
		if tangent.dot(to_g) < 0.0:
			tangent = -tangent
		velocity = tangent * speed * 0.88


func _rebuild_nav_server_path() -> void:
	if not is_inside_tree():
		return
	if base_worker_use_physics_steering:
		if _nav_agent and is_instance_valid(_nav_agent):
			_nav_agent.target_position = _gather_target
		_srv_path.clear()
		_srv_path_idx = 0
		return
	_apply_nav_layers_from_region()
	if _nav_agent and is_instance_valid(_nav_agent):
		_nav_agent.target_position = _gather_target
	if base_move_use_navigation_agent_path:
		_srv_path.clear()
		_srv_path_idx = 0
		return
	var map_rid: RID = get_world_2d().get_navigation_map()
	var layers := _nav_agent.navigation_layers if _nav_agent else 1
	if base_move_use_map_force_update:
		NavigationServer2D.map_force_update(map_rid)
	var start_pt: Vector2 = NavigationServer2D.map_get_closest_point(map_rid, global_position)
	var goal_pt: Vector2 = NavigationServer2D.map_get_closest_point(map_rid, _gather_target)
	## optimize=false — вершины ближе к «срезу» коридора; true часто режет углы и ведёт в стену.
	var path: PackedVector2Array = NavigationServer2D.map_get_path(
		map_rid,
		start_pt,
		goal_pt,
		false,
		layers
	)
	if path.is_empty() and start_pt.distance_squared_to(goal_pt) > 4.0:
		path = NavigationServer2D.map_get_path(map_rid, start_pt, goal_pt, true, layers)
	_srv_path = path
	_srv_path_idx = 0


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
	_meat_chase_node = null


func get_worker_job_name() -> String:
	match _worker_job:
		WorkerJob.MEAT:
			return "meat"
		WorkerJob.WOOD:
			return "wood"
		_:
			return "ore"


func is_assigned_to_ore_mining() -> bool:
	if Events.current_location != Events.LOCATION.BASE:
		return false
	return _worker_job == WorkerJob.ORE


func get_base_shift_phase_name() -> String:
	return ""


func get_base_shift_task_name() -> String:
	return ""


func _idle_anim() -> StringName:
	if Events.current_location == Events.LOCATION.BASE:
		if _worker_job == WorkerJob.MEAT:
			return &"idle_knife"
		match _worker_job:
			WorkerJob.WOOD:
				return &"idle_axe"
			_:
				return &"idle_pickaxe"
	return &"idle_knife"


func _run_anim() -> StringName:
	if Events.current_location == Events.LOCATION.BASE:
		if _worker_job == WorkerJob.MEAT:
			return &"run_knife"
		match _worker_job:
			WorkerJob.WOOD:
				return &"run_axe"
			_:
				return &"run_pickaxe"
	return &"run_knife"


func _get_melee_hit_reach() -> float:
	return 58.0


func _get_melee_hit_radius() -> float:
	return 20.0


func _attack_anim_for_direction(_dir: Vector2) -> StringName:
	return &"interact_knife"


func _cancel_base_worker() -> void:
	_base_worker_state = BaseWorkerState.IDLE
	_island_gathering = false
	_move_timeout = 0.0
	_meat_chase_node = null
	_meat_chase_repath_cd = 0.0
	_srv_path.clear()
	_srv_path_idx = 0
	_path_repath_timer = 0.0
	_move_stuck_frames = 0
	if _nav_agent and is_instance_valid(_nav_agent):
		_nav_agent.target_position = global_position


func _nearest_sheep_in_attack_area() -> Node2D:
	if attack_area == null:
		return null
	var best: Node2D = null
	var best_d := INF
	for body in attack_area.get_overlapping_bodies():
		if body is Node2D and (body as Node).is_in_group("base_sheep"):
			if (body as Node).has_method("is_alive_for_meat") and not (body as Node).is_alive_for_meat():
				continue
			var d := global_position.distance_to((body as Node2D).global_position)
			if d < best_d:
				best_d = d
				best = body as Node2D
	return best


func _process_follow_custom(_delta: float) -> bool:
	if Events.current_location != Events.LOCATION.BASE:
		_cancel_base_worker()
		return false
	var enemy := _nearest_enemy_in_attack_area()
	if enemy and _attack_cd <= 0.0 and attack_area:
		_cancel_base_worker()
		_pawn_cosmetic_busy = false
		return false
	if SquadOrders.mode == SquadOrders.Mode.HOLD:
		_cancel_base_worker()
		return false
	if _worker_job == WorkerJob.MEAT:
		var scene: Node = get_tree().current_scene
		if IslandWorkerTargets.find_meat_job_gather_point(scene, global_position) == Vector2.ZERO:
			_cancel_base_worker()
			return false
	return _process_base_worker_gather(_delta)


func _process_base_worker_gather(delta: float) -> bool:
	if _nav_agent == null or not is_instance_valid(_nav_agent):
		return false
	var scene: Node = get_tree().current_scene
	match _base_worker_state:
		BaseWorkerState.IDLE:
			_gather_cd -= delta
			if _gather_cd > 0.0:
				velocity = Vector2.ZERO
				_play_idle()
				return true
			var job := get_worker_job_name()
			_meat_chase_node = null
			if job == "meat":
				_meat_chase_node = IslandWorkerTargets.find_nearest_live_meat_node(scene, global_position)
			var tgt: Vector2
			if _meat_chase_node != null and is_instance_valid(_meat_chase_node):
				tgt = _meat_chase_node.global_position
			else:
				tgt = IslandWorkerTargets.find_target_global(scene, job, global_position)
			if tgt == Vector2.ZERO:
				if job == "meat":
					_cancel_base_worker()
					return false
				velocity = Vector2.ZERO
				_play_idle()
				return true
			_gather_target = tgt
			_nav_agent.target_position = tgt
			_base_worker_state = BaseWorkerState.MOVE
			_move_timeout = 0.0
			_move_stuck_frames = 0
			_meat_chase_repath_cd = 0.0
			_srv_path.clear()
			_srv_path_idx = 0
			_path_repath_timer = 0.0
			_rebuild_nav_server_path()
			return true
		BaseWorkerState.MOVE:
			if _worker_job == WorkerJob.MEAT and _meat_chase_node != null and not is_instance_valid(_meat_chase_node):
				_meat_chase_node = null
				_srv_path.clear()
				_srv_path_idx = 0
				_path_repath_timer = 0.0
				_move_stuck_frames = 0
				_base_worker_state = BaseWorkerState.IDLE
				_gather_cd = 0.0
				_move_timeout = 0.0
				velocity = Vector2.ZERO
				if _nav_agent and is_instance_valid(_nav_agent):
					_nav_agent.target_position = global_position
				_play_idle()
				return true
			_move_timeout += delta
			if not (_worker_job == WorkerJob.MEAT and _meat_chase_node != null and is_instance_valid(_meat_chase_node)):
				_path_repath_timer -= delta
			if _worker_job == WorkerJob.MEAT and _meat_chase_node != null and is_instance_valid(_meat_chase_node):
				_gather_target = _meat_chase_node.global_position
				_meat_chase_repath_cd -= delta
				if _meat_chase_repath_cd <= 0.0:
					_meat_chase_repath_cd = 0.1
					_rebuild_nav_server_path()
			var sheep_in_atk := _nearest_sheep_in_attack_area()
			if sheep_in_atk != null and _attack_cd <= 0.0:
				_start_attack(sheep_in_atk)
				return true
			var dist := global_position.distance_to(_gather_target)
			if dist <= 44.0:
				if _worker_job == WorkerJob.MEAT and _meat_chase_node != null and is_instance_valid(_meat_chase_node):
					if _meat_chase_node.has_method("is_alive_for_meat") and _meat_chase_node.is_alive_for_meat():
						velocity = Vector2.ZERO
						_face_toward_global(_gather_target)
						_play_idle()
						return true
					if dist <= 24.0:
						velocity = Vector2.ZERO
						_face_toward_global(_gather_target)
						_play_idle()
						return true
				elif _worker_job != WorkerJob.MEAT:
					_move_stuck_frames = 0
					_begin_island_gather()
					return true
			if _move_timeout > 22.0:
				if get_worker_job_name() == "meat":
					_move_timeout = 0.0
					_rebuild_nav_server_path()
					return true
				_move_stuck_frames = 0
				_begin_island_gather()
				return true
			var need_repath := (
				_path_repath_timer <= 0.0
				or _move_stuck_frames > 12
				or (_move_stuck_frames > 8 and is_on_wall())
			)
			if not base_worker_use_physics_steering:
				need_repath = need_repath or _srv_path.is_empty()
			if need_repath:
				_rebuild_nav_server_path()
				_path_repath_timer = 0.22 if not base_worker_use_physics_steering else 0.35
				if _move_stuck_frames > 12:
					_move_stuck_frames = 6
			if base_worker_use_physics_steering:
				velocity = _steer_toward_goal(_gather_target) * speed
				_apply_base_move_wall_slide()
				_face_velocity(velocity)
				_play_run()
				return true
			if base_move_use_navigation_agent_path and _nav_agent:
				_nav_agent.target_position = _gather_target
				var next := _nav_agent.get_next_path_position()
				var to_next := next - global_position
				if to_next.length_squared() < 4.0:
					to_next = _gather_target - global_position
				if to_next.length_squared() < 1.0:
					velocity = _nav_fallback_velocity()
				else:
					velocity = to_next.normalized() * speed
				_apply_base_move_wall_slide()
				_face_velocity(velocity)
				_play_run()
				return true
			if _srv_path.size() >= 2:
				while (
					_srv_path_idx < _srv_path.size() - 1
					and global_position.distance_to(_srv_path[_srv_path_idx]) < _BASE_NAV_WP_ADVANCE_DIST
				):
					_srv_path_idx += 1
				var wp: Vector2 = _srv_path[_srv_path_idx]
				var to_wp := wp - global_position
				if to_wp.length_squared() < 4.0 and _srv_path_idx < _srv_path.size() - 1:
					_srv_path_idx += 1
					wp = _srv_path[_srv_path_idx]
					to_wp = wp - global_position
				if to_wp.length_squared() > 0.25:
					velocity = to_wp.normalized() * speed
				else:
					velocity = _nav_fallback_velocity()
			else:
				velocity = _nav_fallback_velocity()
			_apply_base_move_wall_slide()
			_face_velocity(velocity)
			_play_run()
			return true
		BaseWorkerState.GATHER:
			velocity = Vector2.ZERO
			return true
		BaseWorkerState.COOLDOWN:
			_gather_cd -= delta
			if _gather_cd <= 0.0:
				_base_worker_state = BaseWorkerState.IDLE
			velocity = Vector2.ZERO
			_play_idle()
			return true
	return false


func _face_toward_global(p: Vector2) -> void:
	if sprite == null:
		return
	var dx := p.x - global_position.x
	if absf(dx) > 2.0:
		sprite.flip_h = dx < 0.0


func _gather_anim_name() -> StringName:
	match get_worker_job_name():
		"ore":
			return &"interact_pickaxe"
		"wood":
			return &"interact_axe"
		_:
			return &"interact_knife"


func _begin_island_gather() -> void:
	if get_worker_job_name() == "meat":
		_base_worker_state = BaseWorkerState.IDLE
		_gather_cd = 0.35
		_move_timeout = 0.0
		return
	_base_worker_state = BaseWorkerState.GATHER
	_island_gathering = true
	velocity = Vector2.ZERO
	_face_toward_global(_gather_target)
	var anim := _gather_anim_name()
	if sprite and sprite.sprite_frames and sprite.sprite_frames.has_animation(anim):
		sprite.play(anim)
	else:
		_finish_island_gather_reward_only()


func _finish_island_gather_reward_only() -> void:
	_apply_island_gather_rewards()
	_island_gathering = false
	_base_worker_state = BaseWorkerState.COOLDOWN
	_gather_cd = randf_range(2.0, 4.2)
	_play_idle()


func _apply_island_gather_rewards() -> void:
	match get_worker_job_name():
		"ore":
			GameManager.add_ore(1)
		"wood":
			GameManager.add_wood(1)
		"meat":
			pass


func _on_sprite_animation_finished() -> void:
	if _island_gathering:
		_apply_island_gather_rewards()
		_island_gathering = false
		_base_worker_state = BaseWorkerState.COOLDOWN
		_gather_cd = randf_range(2.0, 4.2)
		if sprite:
			_play_idle()
		return
	if _pawn_cosmetic_busy:
		_pawn_cosmetic_busy = false
		_play_idle()
		return
	super._on_sprite_animation_finished()
