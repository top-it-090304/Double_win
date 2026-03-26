extends "res://characters/companion_unit.gd"

## Спутник: на базовом острове — добыча по `WorkerJob` (навигация + interact_*). На походных островах — обычный спутник.

enum WorkerJob { ORE, MEAT, WOOD }

enum BaseWorkerState { IDLE, MOVE, GATHER, COOLDOWN }

var _worker_job: WorkerJob = WorkerJob.ORE
var _pawn_cosmetic_busy: bool = false

var _base_worker_state: BaseWorkerState = BaseWorkerState.IDLE
var _gather_target: Vector2 = Vector2.ZERO
var _gather_cd: float = 0.0
var _move_timeout: float = 0.0
var _island_gathering: bool = false

@onready var _nav_agent: NavigationAgent2D = $NavigationAgent2D


func _ready() -> void:
	speed = 120.0
	super._ready()
	add_to_group("ally_pawn")
	if _nav_agent:
		_nav_agent.path_desired_distance = 16.0
		_nav_agent.target_desired_distance = 28.0
		_nav_agent.path_max_distance = 2000.0
		_nav_agent.avoidance_enabled = false
		_nav_agent.navigation_layers = 1


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if _nav_agent and is_instance_valid(_nav_agent):
		_nav_agent.velocity = velocity


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
	if _nav_agent and is_instance_valid(_nav_agent):
		_nav_agent.target_position = global_position


func _process_follow_custom(delta: float) -> bool:
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
	return _process_base_worker_gather(delta)


func _process_base_worker_gather(delta: float) -> bool:
	if _nav_agent == null or not is_instance_valid(_nav_agent):
		return false
	var scene: Node = get_tree().current_scene
	match _base_worker_state:
		BaseWorkerState.IDLE:
			_gather_cd -= delta
			if _gather_cd > 0.0:
				return false
			var job := get_worker_job_name()
			var tgt := IslandWorkerTargets.find_target_global(scene, job, global_position)
			if tgt == Vector2.ZERO:
				return false
			_gather_target = tgt
			_nav_agent.target_position = tgt
			_base_worker_state = BaseWorkerState.MOVE
			_move_timeout = 0.0
			return true
		BaseWorkerState.MOVE:
			_move_timeout += delta
			var dist := global_position.distance_to(_gather_target)
			if dist <= 44.0:
				_begin_island_gather()
				return true
			if _nav_agent.is_navigation_finished() and dist > 44.0:
				if _move_timeout > 18.0:
					_begin_island_gather()
					return true
			elif _move_timeout > 22.0:
				_begin_island_gather()
				return true
			var next := _nav_agent.get_next_path_position()
			var to_next := next - global_position
			if to_next.length_squared() < 4.0:
				to_next = _gather_target - global_position
			if to_next.length_squared() < 1.0:
				_begin_island_gather()
				return true
			velocity = to_next.normalized() * speed
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
			return false
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
			## Мясо на базе: +1 только при подборе зоной `MeatPickupArea` у `BaseSheep` (или shear у `sheep_resource`), не за анимацию ножа.
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
