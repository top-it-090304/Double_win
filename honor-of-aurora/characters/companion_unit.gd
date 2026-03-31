extends "res://characters/ally_unit.gd"
## Спутник: следование за героем, ближний бой, урон, смерть (анимация dead).
## Урон наносится в малой области у острия (см. _get_melee_hit_*), а не по всему радиусу AttackArea.

enum State { FOLLOW, ATTACK, DEAD }

@export var speed: float = 135.0
@export var max_health: int = 70
@export var follow_distance: float = 160.0
@export var follow_stop_distance: float = 100.0
@export var attack_damage: int = 16
@export var attack_cooldown: float = 1.05
## Патруль: радиус от точки спавна, куда можно уходить.
@export var base_patrol_leash_radius: float = 1400.0
## Считаем цель достигнутой на этом расстоянии (пикс.).
@export var patrol_reach_distance: float = 44.0
## Максимум секунд на один отрезок пути к цели — потом новая точка (если застряли в открытом месте).
@export var patrol_max_segment_time: float = 50.0
## Кадров подряд у стены — новая цель.
@export var patrol_wall_stuck_frames: int = 12
## Доля от `speed` при патрулировании (медленнее обычного бега за героем).
@export_range(0.15, 1.0, 0.01) var patrol_speed_scale: float = 0.62
## Как у лучника: путь по нав-сетке острова + локальный обход стен (без этого копейщик режет прямую и уходит с суши/в коллизии).
@export var follow_use_navigation: bool = true

var _follow_nav: SquadNavFollow = SquadNavFollow.new()
var _follow_nav_layer_sync_attempts: int = 0

var state: State = State.FOLLOW
var player: Node2D = null
var _attack_cd: float = 0.0
var _paralysis_time: float = 0.0
var _base_patrol_spawn: Vector2 = Vector2.ZERO
var _patrol_goal: Vector2 = Vector2.ZERO
var _patrol_has_goal: bool = false
var _patrol_segment_time: float = 0.0
var _patrol_stuck_frames: int = 0
var _patrol_no_move_frames: int = 0
var _base_patrol_zone_nodes: Array[Node2D] = []
var _base_patrol_zone_idx: int = 0
var _base_building_patrol_leash_escape: bool = false
## Направление удара (к цели) для расчёта точки острия в мировых координатах.
var _attack_hit_dir: Vector2 = Vector2.RIGHT
## Цель текущего замаха (чтобы «острие» не уходило дальше цели — иначе промах по intersect_shape у близкой овцы/врага).
var _melee_attack_target: Node2D = null

@onready var sprite: AnimatedSprite2D = get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
@onready var attack_area: Area2D = get_node_or_null("AttackArea") as Area2D

var _base_speed: float = 0.0
var _base_max_health: int = 0
var _base_attack_damage: int = 0
var progression_building_type: String = "Barracks"


func _get_initial_max_health() -> int:
	return max_health


func _get_initial_health() -> int:
	return max_health


func _get_melee_hit_reach() -> float:
	return 76.0


func _get_melee_hit_radius() -> float:
	return 24.0


func _ready() -> void:
	super._ready()
	_base_speed = speed
	_base_max_health = max_health
	_base_attack_damage = attack_damage
	apply_building_progression_from_manager()
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	max_slides = 6
	if sprite:
		sprite.animation_finished.connect(_on_sprite_animation_finished)
	_play_idle()
	player = get_tree().get_first_node_in_group("player") as Node2D
	call_deferred("_capture_base_patrol_spawn_after_placed")
	call_deferred("_sync_follow_nav_layers_from_scene")
	if not Events.location_changed.is_connected(_on_events_location_changed_resync_follow_nav):
		Events.location_changed.connect(_on_events_location_changed_resync_follow_nav)


func _capture_base_patrol_spawn_after_placed() -> void:
	_base_patrol_spawn = global_position
	_patrol_has_goal = false


func squad_rally_after_reposition() -> void:
	_reset_base_building_patrol_state()
	if _follow_nav:
		_follow_nav.clear()
	if state == State.ATTACK:
		state = State.FOLLOW


func _reset_base_building_patrol_state() -> void:
	_base_patrol_zone_nodes.clear()
	_base_patrol_zone_idx = 0
	_base_building_patrol_leash_escape = false
	_patrol_has_goal = false


func _on_events_location_changed_resync_follow_nav(_loc: Events.LOCATION) -> void:
	_reset_base_building_patrol_state()
	call_deferred("_sync_follow_nav_layers_from_scene")


func _sync_follow_nav_layers_from_scene() -> void:
	if not is_instance_valid(self) or _follow_nav == null:
		return
	if not is_inside_tree():
		if _follow_nav_layer_sync_attempts < 8:
			_follow_nav_layer_sync_attempts += 1
			call_deferred("_sync_follow_nav_layers_from_scene")
		return
	_follow_nav_layer_sync_attempts = 0
	_follow_nav.sync_nav_layers_from_scene(self)


func apply_building_progression_from_manager() -> void:
	var unit_kind := "lancer"
	if progression_building_type == "Castle":
		unit_kind = "pawn"
	var mul := GameManager.get_ally_tier_stat_multiplier(unit_kind)
	speed = _base_speed * float(mul.get("speed", 1.0))
	max_health = maxi(1, int(round(float(_base_max_health) * float(mul.get("hp", 1.0)))))
	attack_damage = maxi(1, int(round(float(_base_attack_damage) * float(mul.get("damage", 1.0)))))
	if health_component:
		var old_max := maxi(1, int(health_component.max_health))
		var old_current := int(health_component.current_health)
		health_component.set_max_health(max_health)
		health_component.set_current_health(clampi(int(round(float(max_health) * float(old_current) / float(old_max))), 1, max_health))
	if sprite:
		sprite.modulate = GameManager.get_tier_visual_modulate(SaveManager.get_building_tier(progression_building_type))


func apply_paralysis(duration_sec: float) -> void:
	_paralysis_time = maxf(_paralysis_time, duration_sec)


func _idle_anim() -> StringName:
	return &"idle"


func _run_anim() -> StringName:
	return &"run"


func _attack_anim_for_direction(_dir: Vector2) -> StringName:
	return &"attack"


func _play_idle() -> void:
	if sprite:
		sprite.play(_idle_anim())


func _play_run() -> void:
	if sprite:
		sprite.play(_run_anim())


func _physics_process(delta: float) -> void:
	if state == State.DEAD:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	if _paralysis_time > 0.0:
		_paralysis_time = maxf(0.0, _paralysis_time - delta)
		if state == State.ATTACK:
			state = State.FOLLOW
		velocity = Vector2.ZERO
		_play_idle()
		move_and_slide()
		return

	if not player or not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player") as Node2D

	_attack_cd = maxf(0.0, _attack_cd - delta)

	match state:
		State.FOLLOW:
			_process_follow(delta)
		State.ATTACK:
			velocity = Vector2.ZERO

	if not (SquadOrders.mode == SquadOrders.Mode.PATROL and state == State.FOLLOW):
		_apply_soft_separation_to_velocity(delta)
	var v_sq_before_move := velocity.length_squared()
	var pos_before_move := global_position
	var vel_before_move := velocity
	move_and_slide()
	if state == State.FOLLOW:
		_sync_follow_movement_animation(vel_before_move)
		if SquadOrders.mode == SquadOrders.Mode.PATROL and not (Events.current_location != Events.LOCATION.BASE and is_in_group("ally_pawn")):
			if v_sq_before_move > 100.0 and global_position.distance_to(pos_before_move) < 0.45:
				_patrol_no_move_frames += 1
				if _patrol_no_move_frames >= 22:
					_follow_nav.clear()
					if Events.current_location == Events.LOCATION.BASE and _base_patrol_zone_nodes.size() >= 2:
						_advance_base_patrol_zone_to_next()
						if _patrol_has_goal and _base_patrol_zone_nodes.size() >= 2:
							var zn: Node2D = _base_patrol_zone_nodes[_base_patrol_zone_idx]
							if is_instance_valid(zn):
								_patrol_goal = zn.global_position
					else:
						_patrol_goal = SquadPatrol.pick_waypoint(_base_patrol_spawn, base_patrol_leash_radius)
					_patrol_segment_time = 0.0
					_patrol_stuck_frames = 0
					_patrol_no_move_frames = 0
			elif global_position.distance_to(pos_before_move) >= 0.45:
				_patrol_no_move_frames = 0


func _process_follow(_delta: float) -> void:
	if _process_follow_custom(_delta):
		return
	var enemy := _nearest_enemy_in_attack_area()
	if enemy and _attack_cd <= 0.0 and attack_area:
		_start_attack(enemy)
		return
	## Овцы базы — не группа `enemy`; без этого сюжетный рабочий (NONE) и обычный follow не наносят урон.
	var sheep := _nearest_base_sheep_in_attack_area()
	if sheep != null and _attack_cd <= 0.0 and attack_area:
		_start_attack(sheep)
		return

	if SquadOrders.mode == SquadOrders.Mode.HOLD:
		_follow_nav.clear()
		velocity = Vector2.ZERO
		_play_idle()
		return

	if SquadOrders.mode == SquadOrders.Mode.PATROL:
		## На островах рабочие не спавнятся из экономики; единственный — сюжетный юноша.
		## Режим PATROL здесь — наследие «работы» на базе: иначе он кружит и не дерётся.
		if Events.current_location != Events.LOCATION.BASE and is_in_group("ally_pawn"):
			pass
		else:
			_process_base_patrol(_delta)
			_apply_follow_wall_slide_if_needed()
			return

	if not player:
		_follow_nav.clear()
		velocity = Vector2.ZERO
		_play_idle()
		return

	_sync_follow_player_velocity()
	_apply_follow_wall_slide_if_needed()


## Рабочий (pawn): шахта, «сбор» на острове. По умолчанию — обычное следование.
func _process_follow_custom(_delta: float) -> bool:
	return false


func _process_base_patrol(_delta: float) -> void:
	if Events.current_location == Events.LOCATION.BASE:
		velocity = _compute_base_patrol_velocity_base_zones()
	else:
		_process_base_patrol_adventure_ring()


func _advance_base_patrol_zone_to_next() -> void:
	var tree := get_tree()
	_base_patrol_zone_idx += 1
	if _base_patrol_zone_idx >= _base_patrol_zone_nodes.size():
		_base_patrol_zone_idx = 0
		if tree:
			_base_patrol_zone_nodes = SquadBaseBuildingPatrol.collect_shuffled_zone_nodes(tree)
		if _base_patrol_zone_nodes.size() < 2:
			_patrol_has_goal = false
			return
	if _follow_nav:
		_follow_nav.clear()
	_patrol_segment_time = 0.0
	_patrol_stuck_frames = 0


func _resolve_patrol_goal_node() -> Node2D:
	if _base_patrol_zone_nodes.is_empty():
		return null
	var i := clampi(_base_patrol_zone_idx, 0, _base_patrol_zone_nodes.size() - 1)
	var goal_node: Node2D = _base_patrol_zone_nodes[i]
	if is_instance_valid(goal_node):
		return goal_node
	return null


func _compute_base_patrol_velocity_base_zones() -> Vector2:
	var delta := get_physics_process_delta_time()
	var tree := get_tree()
	if tree == null:
		return _get_base_patrol_velocity_adventure_ring()
	if _base_patrol_zone_nodes.size() < 2:
		_base_patrol_zone_nodes = SquadBaseBuildingPatrol.collect_shuffled_zone_nodes(tree)
		_base_patrol_zone_idx = 0
	if _base_patrol_zone_nodes.size() < 2:
		return _get_base_patrol_velocity_adventure_ring()
	if _base_building_patrol_leash_escape:
		if global_position.distance_to(_base_patrol_spawn) <= base_patrol_leash_radius * 0.88:
			_base_building_patrol_leash_escape = false
	elif global_position.distance_to(_base_patrol_spawn) > base_patrol_leash_radius * 0.94:
		_base_building_patrol_leash_escape = true
		_patrol_goal = SquadPatrol.pick_waypoint(_base_patrol_spawn, base_patrol_leash_radius * 0.42)
		_patrol_segment_time = 0.0
		_patrol_stuck_frames = 0
		return SquadBaseBuildingPatrol.velocity_toward_goal_worker_like(
			self, _follow_nav, _patrol_goal, speed, patrol_speed_scale, follow_use_navigation, delta
		)
	if not _patrol_has_goal:
		_patrol_has_goal = true
		_patrol_segment_time = 0.0
		_base_patrol_zone_idx = clampi(_base_patrol_zone_idx, 0, _base_patrol_zone_nodes.size() - 1)
	_patrol_segment_time += delta
	var goal_node: Node2D = _resolve_patrol_goal_node()
	if goal_node == null:
		_base_patrol_zone_nodes = SquadBaseBuildingPatrol.collect_shuffled_zone_nodes(tree)
		if _base_patrol_zone_nodes.size() < 2:
			_patrol_has_goal = false
			return _get_base_patrol_velocity_adventure_ring()
		_base_patrol_zone_idx = clampi(_base_patrol_zone_idx, 0, _base_patrol_zone_nodes.size() - 1)
		goal_node = _resolve_patrol_goal_node()
		if goal_node == null:
			_patrol_has_goal = false
			return _get_base_patrol_velocity_adventure_ring()
	_patrol_goal = goal_node.global_position
	if SquadBaseBuildingPatrol.zone_goal_reached(self, goal_node):
		_advance_base_patrol_zone_to_next()
		if not _patrol_has_goal:
			return _get_base_patrol_velocity_adventure_ring()
		goal_node = _resolve_patrol_goal_node()
		if goal_node == null:
			_patrol_has_goal = false
			return _get_base_patrol_velocity_adventure_ring()
		_patrol_goal = goal_node.global_position
	elif _patrol_segment_time >= patrol_max_segment_time:
		_advance_base_patrol_zone_to_next()
		if not _patrol_has_goal:
			return _get_base_patrol_velocity_adventure_ring()
		goal_node = _resolve_patrol_goal_node()
		if goal_node == null:
			_patrol_has_goal = false
			return _get_base_patrol_velocity_adventure_ring()
		_patrol_goal = goal_node.global_position
	if is_on_wall():
		_patrol_stuck_frames += 1
		if _patrol_stuck_frames >= patrol_wall_stuck_frames:
			_advance_base_patrol_zone_to_next()
			if not _patrol_has_goal:
				return _get_base_patrol_velocity_adventure_ring()
			_patrol_stuck_frames = 0
			goal_node = _resolve_patrol_goal_node()
			if goal_node == null:
				_patrol_has_goal = false
				return _get_base_patrol_velocity_adventure_ring()
			_patrol_goal = goal_node.global_position
	else:
		_patrol_stuck_frames = 0
	if not _patrol_has_goal:
		return _get_base_patrol_velocity_adventure_ring()
	goal_node = _resolve_patrol_goal_node()
	if goal_node == null:
		_patrol_has_goal = false
		return _get_base_patrol_velocity_adventure_ring()
	_patrol_goal = goal_node.global_position
	var vn := SquadBaseBuildingPatrol.velocity_toward_goal_worker_like(
		self, _follow_nav, _patrol_goal, speed, patrol_speed_scale, follow_use_navigation, delta
	)
	if vn.length_squared() < 1.0:
		_advance_base_patrol_zone_to_next()
		if not _patrol_has_goal:
			return _get_base_patrol_velocity_adventure_ring()
		goal_node = _resolve_patrol_goal_node()
		if goal_node == null:
			_patrol_has_goal = false
			return _get_base_patrol_velocity_adventure_ring()
		_patrol_goal = goal_node.global_position
		return SquadBaseBuildingPatrol.velocity_toward_goal_worker_like(
			self, _follow_nav, _patrol_goal, speed, patrol_speed_scale, follow_use_navigation, delta
		)
	return vn


func _get_base_patrol_velocity_adventure_ring() -> Vector2:
	var delta := get_physics_process_delta_time()
	if not _patrol_has_goal:
		_patrol_goal = SquadPatrol.pick_waypoint(_base_patrol_spawn, base_patrol_leash_radius)
		_patrol_has_goal = true
		_patrol_segment_time = 0.0
	_patrol_segment_time += delta
	if global_position.distance_to(_base_patrol_spawn) > base_patrol_leash_radius * 0.94:
		_patrol_goal = SquadPatrol.pick_waypoint(_base_patrol_spawn, base_patrol_leash_radius * 0.42)
		_patrol_segment_time = 0.0
		_patrol_stuck_frames = 0
	var to_goal := _patrol_goal - global_position
	if to_goal.length() <= patrol_reach_distance:
		_patrol_goal = SquadPatrol.pick_waypoint(_base_patrol_spawn, base_patrol_leash_radius)
		_patrol_segment_time = 0.0
		_patrol_stuck_frames = 0
	elif _patrol_segment_time >= patrol_max_segment_time:
		_patrol_goal = SquadPatrol.pick_waypoint(_base_patrol_spawn, base_patrol_leash_radius)
		_patrol_segment_time = 0.0
		_patrol_stuck_frames = 0
	if is_on_wall():
		_patrol_stuck_frames += 1
		if _patrol_stuck_frames >= patrol_wall_stuck_frames:
			_patrol_goal = SquadPatrol.pick_waypoint(_base_patrol_spawn, base_patrol_leash_radius)
			_patrol_segment_time = 0.0
			_patrol_stuck_frames = 0
	else:
		_patrol_stuck_frames = 0
	return SquadBaseBuildingPatrol.velocity_toward_goal_worker_like(
		self, _follow_nav, _patrol_goal, speed, patrol_speed_scale, follow_use_navigation, delta
	)


func _process_base_patrol_adventure_ring() -> void:
	velocity = _get_base_patrol_velocity_adventure_ring()


func _sync_follow_player_velocity() -> void:
	var dist := global_position.distance_to(player.global_position)
	if dist <= follow_distance:
		_follow_nav.clear()
	if dist > follow_distance:
		if follow_use_navigation and _follow_nav:
			var dlt: float = get_physics_process_delta_time()
			var vn: Variant = _follow_nav.get_velocity_or_null(self, player.global_position, speed, dlt)
			if vn != null and vn is Vector2:
				var fv: Vector2 = vn as Vector2
				if fv.length_squared() > 1.0:
					velocity = fv
					return
				velocity = SquadWorkerLikeSteering.steer_direction(self, player.global_position, speed) * speed
				return
		velocity = SquadWorkerLikeSteering.steer_direction(self, player.global_position, speed) * speed
		return
	velocity = Vector2.ZERO


func _apply_follow_wall_slide_if_needed() -> void:
	if velocity.length_squared() <= 4.0:
		return
	if SquadOrders.mode == SquadOrders.Mode.PATROL:
		SquadWorkerLikeSteering.apply_wall_slide_toward(self, _patrol_goal, speed * patrol_speed_scale)
	elif SquadOrders.mode == SquadOrders.Mode.COMBAT and player and is_instance_valid(player):
		SquadWorkerLikeSteering.apply_wall_slide_toward(self, player.global_position, speed)


func _sync_follow_movement_animation(vel_for_face: Vector2) -> void:
	if sprite == null or state != State.FOLLOW:
		return
	## run/idle — по фактической скорости после move_and_slide (не бежать на месте у стены).
	## Разворот спрайта — по намерению до скольжения + запас к горизонтали к герою (скольжение часто даёт vx≈0).
	if velocity.length() > 0.1:
		_face_velocity(vel_for_face)
		_play_run()
	else:
		_play_idle()


func _face_velocity(v: Vector2) -> void:
	if sprite == null:
		return
	var hx: float = v.x
	if absf(hx) < 0.08 and player != null and is_instance_valid(player):
		hx = player.global_position.x - global_position.x
	if absf(hx) > 0.05:
		sprite.flip_h = hx < 0.0


func _nearest_enemy_in_attack_area() -> Node2D:
	if attack_area == null:
		return null
	var best: Node2D = null
	var best_d := INF
	for body in attack_area.get_overlapping_bodies():
		if body is Node2D and body.is_in_group("enemy"):
			var d := global_position.distance_to(body.global_position)
			if d < best_d:
				best_d = d
				best = body
	return best


func _nearest_base_sheep_in_attack_area() -> Node2D:
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


func _start_attack(target: Node2D) -> void:
	state = State.ATTACK
	_melee_attack_target = target
	velocity = Vector2.ZERO
	_attack_cd = attack_cooldown
	var dir := target.global_position - global_position
	if dir.length() > 0.01:
		_attack_hit_dir = dir.normalized()
	else:
		_attack_hit_dir = Vector2.RIGHT if sprite == null or not sprite.flip_h else Vector2.LEFT
	if sprite:
		if absf(dir.x) > 0.05:
			sprite.flip_h = dir.x < 0.0
		var anim := _attack_anim_for_direction(dir)
		if sprite.sprite_frames and sprite.sprite_frames.has_animation(anim):
			sprite.play(anim)
		else:
			sprite.play(_idle_anim())


func _on_sprite_animation_finished() -> void:
	if state != State.ATTACK:
		return
	_apply_melee_damage()
	state = State.FOLLOW


func _apply_melee_damage() -> void:
	var reach := _get_melee_hit_reach()
	var dir := _attack_hit_dir
	if dir.length_squared() < 1e-8:
		dir = Vector2.RIGHT
	var ref_target: Node2D = _melee_attack_target
	if ref_target == null or not is_instance_valid(ref_target):
		ref_target = _nearest_base_sheep_in_attack_area()
		if ref_target == null:
			ref_target = _nearest_enemy_in_attack_area()
	if ref_target != null and is_instance_valid(ref_target):
		var to_t: Vector2 = ref_target.global_position - global_position
		var d: float = to_t.length()
		if d > 0.01:
			dir = to_t / d
			## Полный reach оставляет круг удара за целью при малой дистанции — коллизия овцы не попадает в intersect_shape.
			reach = minf(reach, maxf(d, 20.0))
	var tip := global_position + dir * reach
	_melee_attack_target = null
	var space := get_world_2d().direct_space_state
	var circle := CircleShape2D.new()
	circle.radius = _get_melee_hit_radius()
	var params := PhysicsShapeQueryParameters2D.new()
	params.shape = circle
	params.transform = Transform2D(0.0, tip)
	params.collision_mask = 1
	params.collide_with_areas = false
	params.collide_with_bodies = true
	params.exclude = [get_rid()]
	var hits := space.intersect_shape(params, 32)
	for h in hits:
		var col: Variant = h.get("collider", null)
		if col is Node and ((col as Node).is_in_group("enemy") or (col as Node).is_in_group("base_sheep")):
			GameplayFacade.try_apply_damage(col as Node, attack_damage)


func take_damage(amount: Variant) -> void:
	if state == State.DEAD:
		return
	super.take_damage(amount)


func _on_health_damage_applied(amount: int) -> void:
	if amount <= 0:
		return
	SoundManager.play_player_hurt()
	GameplayFacade.spawn_damage_number(self, amount, Vector2(-26, -90))


func _handle_death() -> void:
	_die()


func _die() -> void:
	state = State.DEAD
	_attack_cd = 999.0
	velocity = Vector2.ZERO
	if not bool(get_meta("no_squad_death", false)):
		SaveManager.notify_squad_member_died(self)
	var col := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if col:
		col.set_deferred("disabled", true)
	if attack_area:
		attack_area.set_deferred("monitoring", false)
	if sprite:
		if sprite.sprite_frames and sprite.sprite_frames.has_animation(&"dead"):
			## Иначе при смерти во время атаки сигнал animation_finished от прерванной
			## анимации атаки завершает await до play("dead") — смерть не видна.
			sprite.stop()
			sprite.play(&"dead")
			await sprite.animation_finished
	queue_free()
