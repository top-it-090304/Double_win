extends "res://characters/ally_unit.gd"
## Союзник-лучник.

@export var arrow_scene : PackedScene
@export var attack_cooldown : float = 3.0
@export var idle_flip_interval : float = 10.0

@export var speed: float = 160.0
@export var follow_distance: float = 140.0
@export var follow_stop_distance: float = 110.0
@export var projectile_damage: int = 10

@export var max_health: int = 60

@export var flee_distance: float = 220.0
@export var flee_speed_multiplier: float = 1.25
## Стоит на башне / не следует за героем: только idle + смена flip по таймеру и стрельба по врагам.
@export var stationary_guard: bool = false
## Патруль (как у спутников): целевая точка в круге, без метания.
@export var base_patrol_leash_radius: float = 1400.0
@export var patrol_reach_distance: float = 44.0
@export var patrol_max_segment_time: float = 50.0
@export var patrol_wall_stuck_frames: int = 12
@export_range(0.15, 1.0, 0.01) var patrol_speed_scale: float = 0.62
@export var follow_use_navigation: bool = true
## Дистанция до героя, в пределах которой разрешена стрельба по врагам. 0 = без ограничения (страж на башне не ограничен).
@export var max_distance_from_hero_for_combat: float = 0.0

var enemies_in_range : Array = []
var facing_right := true
var _paralysis_time: float = 0.0

@onready var attack_area = $attack_area
@onready var sprite = $AnimatedSprite2D

var attack_timer : Timer
var idle_timer : Timer

enum State { FOLLOW, SHOOT, FLEE, DEAD }
var state: State = State.FOLLOW
var player: Node2D = null
var flee_target: Vector2 = Vector2.ZERO
var _base_patrol_spawn: Vector2 = Vector2.ZERO
var _patrol_goal: Vector2 = Vector2.ZERO
var _patrol_has_goal: bool = false
var _patrol_segment_time: float = 0.0
var _patrol_stuck_frames: int = 0
var _patrol_no_move_frames: int = 0
## Патруль по зданиям базы (только LOCATION.BASE): порядок точек и индекс текущей цели.
var _base_patrol_zone_nodes: Array[Node2D] = []
var _base_patrol_zone_idx: int = 0
var _base_building_patrol_leash_escape: bool = false
## Приказ идти к монаху (только лучник, база).
var _order_to_healer: bool = false
var _base_attack_cooldown: float = 3.0
var _base_max_health: int = 60
var _base_speed: float = 160.0
var _base_projectile_damage: int = 10
var _follow_nav: SquadNavFollow = SquadNavFollow.new()
var _follow_nav_layer_sync_attempts: int = 0
## Один активный цикл выстрела (async `attack()`), иначе несколько `await` → залп стрел.
var _attack_shot_in_progress: bool = false

func _ready() -> void:
	super._ready()
	add_to_group("ally_archer")
	_base_attack_cooldown = attack_cooldown
	_base_max_health = max_health
	_base_speed = speed
	_base_projectile_damage = projectile_damage
	apply_building_progression_from_manager()
	apply_archery_modifiers_from_manager()
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	max_slides = 6
	sprite.play("idle")
	
	attack_timer = Timer.new()
	attack_timer.wait_time = attack_cooldown
	attack_timer.one_shot = true
	attack_timer.timeout.connect(_on_attack_timer_timeout)
	add_child(attack_timer)
	
	idle_timer = Timer.new()
	idle_timer.wait_time = idle_flip_interval
	idle_timer.timeout.connect(_on_idle_timer_timeout)
	add_child(idle_timer)
	idle_timer.start()
	
	attack_area.body_entered.connect(_on_enemy_entered)
	attack_area.body_exited.connect(_on_enemy_exited)
	sprite.animation_finished.connect(_on_animation_finished)
	
	player = get_tree().get_first_node_in_group("player") as Node2D
	call_deferred("_capture_base_patrol_spawn_after_placed")
	call_deferred("_sync_follow_nav_layers_from_scene")
	if not Events.location_changed.is_connected(_on_events_location_changed_resync_follow_nav):
		Events.location_changed.connect(_on_events_location_changed_resync_follow_nav)
	if health_component:
		health_component.health_changed.connect(_on_squad_health_changed)


func apply_archery_modifiers_from_manager() -> void:
	var as_mul := maxf(0.25, GameManager.get_archery_attack_speed_multiplier())
	var hp_mul := maxf(1.0, GameManager.get_archery_hp_multiplier())
	attack_cooldown = maxf(0.35, _base_attack_cooldown / as_mul)
	max_health = maxi(1, int(round(float(_base_max_health) * hp_mul)))
	if health_component:
		var old_max: int = int(health_component.max_health)
		var old_current: int = int(health_component.current_health)
		health_component.set_max_health(max_health)
		if old_max > 0:
			var ratio := float(old_current) / float(old_max)
			health_component.set_current_health(clampi(int(round(float(max_health) * ratio)), 1, max_health))
		else:
			health_component.set_current_health(max_health)
	if attack_timer:
		attack_timer.wait_time = attack_cooldown


func _on_events_location_changed_resync_follow_nav(_loc: Events.LOCATION) -> void:
	_reset_base_building_patrol_state()
	call_deferred("_sync_follow_nav_layers_from_scene")


func _reset_base_building_patrol_state() -> void:
	_base_patrol_zone_nodes.clear()
	_base_patrol_zone_idx = 0
	_base_building_patrol_leash_escape = false
	_patrol_has_goal = false


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
	var mul := GameManager.get_ally_tier_stat_multiplier("archer")
	speed = _base_speed * float(mul.get("speed", 1.0))
	max_health = maxi(1, int(round(float(_base_max_health) * float(mul.get("hp", 1.0)))))
	projectile_damage = maxi(1, int(round(float(_base_projectile_damage) * float(mul.get("damage", 1.0)))))
	if health_component:
		var old_max: int = maxi(1, int(health_component.max_health))
		var old_current: int = int(health_component.current_health)
		health_component.set_max_health(max_health)
		health_component.set_current_health(clampi(int(round(float(max_health) * float(old_current) / float(old_max))), 1, max_health))
	if sprite:
		sprite.modulate = GameManager.get_tier_visual_modulate(SaveManager.get_building_tier("Archery"))


func _on_squad_health_changed(_current: int, _maximum: int) -> void:
	if _order_to_healer and is_health_full():
		_order_to_healer = false


func squad_order_go_to_healer() -> void:
	if Events.current_location != Events.LOCATION.BASE:
		return
	if not is_in_group("ally_archer"):
		return
	if is_health_full():
		return
	_order_to_healer = true


func _capture_base_patrol_spawn_after_placed() -> void:
	_base_patrol_spawn = global_position
	_patrol_has_goal = false


func apply_paralysis(duration_sec: float) -> void:
	_paralysis_time = maxf(_paralysis_time, duration_sec)


func _get_initial_max_health() -> int:
	return max_health


func _get_initial_health() -> int:
	return max_health


func get_y_sort_bottom_y() -> float:
	var y: float = super.get_y_sort_bottom_y()
	## Стационарные стражи: чуть «ниже» линия для YSortManager → выше z_index, стабильно поверх башни.
	if stationary_guard:
		return y + 72.0
	return y


func _on_enemy_entered(body):
	if body.is_in_group("enemy"):
		enemies_in_range.append(body)
		_refresh_state()

func _on_enemy_exited(body):
	if body.is_in_group("enemy"):
		enemies_in_range.erase(body)
		_refresh_state()

func _on_attack_timer_timeout() -> void:
	if state != State.SHOOT:
		return
	attack()


func _get_first_enemy_target() -> Node2D:
	for enemy in enemies_in_range:
		if is_instance_valid(enemy):
			return enemy as Node2D
	return null


func _sync_sprite_facing_to_nearest_enemy() -> void:
	if sprite == null:
		return
	var target := _get_first_enemy_target()
	if target == null:
		return
	var dx := target.global_position.x - global_position.x
	if absf(dx) < 0.5:
		return
	if dx > 0.0:
		facing_right = true
		sprite.flip_h = false
	else:
		facing_right = false
		sprite.flip_h = true


func attack() -> void:
	if _attack_shot_in_progress:
		return
	if state != State.SHOOT:
		return
	
	var target := _get_first_enemy_target()
	if target == null:
		enemies_in_range.clear()
		return
	
	_attack_shot_in_progress = true
	_sync_sprite_facing_to_nearest_enemy()
	var dir := (target.global_position - global_position).normalized()
	
	sprite.play("attack")
	await get_tree().create_timer(0.6).timeout
	
	if state != State.SHOOT:
		_attack_shot_in_progress = false
		return
	
	if arrow_scene:
		var arrow = arrow_scene.instantiate()
		arrow.global_position = global_position + dir * 30
		arrow.direction = dir
		arrow.damage = maxi(1, int(round(float(projectile_damage) * CrownSystem.get_archer_damage_modifier())))
		get_tree().current_scene.add_child(arrow)
	
	_attack_shot_in_progress = false
	if state == State.SHOOT and not enemies_in_range.is_empty():
		attack_timer.start()
	else:
		attack_timer.stop()

func _on_animation_finished():
	if sprite.animation == "attack":
		_refresh_state()

func _on_idle_timer_timeout():
	if state == State.DEAD or state == State.FLEE:
		return
	if not enemies_in_range and sprite.animation != "attack":
		if stationary_guard or sprite.animation == &"idle":
			facing_right = !facing_right
			sprite.flip_h = !facing_right


func _stationary_guard_skip_move_and_slide() -> bool:
	if not stationary_guard or state == State.FLEE:
		return false
	return velocity.length_squared() < 0.01


## После wall-slide и soft separation — иначе «run» при почти нулевой итоговой скорости.
func _sync_follow_or_flee_movement_animation() -> void:
	if sprite == null:
		return
	if state == State.FOLLOW:
		if stationary_guard:
			return
		if velocity.length() > 0.1:
			if sprite.animation != "run":
				sprite.play("run")
			sprite.flip_h = velocity.x < 0
		else:
			if sprite.animation != "idle":
				sprite.play("idle")
	elif state == State.FLEE:
		if velocity.length() > 0.1:
			if sprite.animation != "run":
				sprite.play("run")
			sprite.flip_h = velocity.x < 0
		else:
			if sprite.animation != "idle":
				sprite.play("idle")


func _physics_process(delta: float) -> void:
	if state == State.DEAD:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	if _paralysis_time > 0.0:
		_paralysis_time = maxf(0.0, _paralysis_time - delta)
		if state == State.SHOOT:
			state = State.FOLLOW
		velocity = Vector2.ZERO
		if sprite:
			sprite.play("idle")
		if not _stationary_guard_skip_move_and_slide():
			move_and_slide()
		return
	
	if not player or not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player") as Node2D
	
	match state:
		State.FOLLOW:
			velocity = _get_follow_velocity()
			## Скольжение у стены — после желаемой скорости, до разведения и анимации (иначе run при почти нулевой фактической скорости).
			if not stationary_guard and velocity.length_squared() > 4.0:
				if SquadOrders.mode == SquadOrders.Mode.PATROL:
					SquadWorkerLikeSteering.apply_wall_slide_toward(self, _patrol_goal, speed * patrol_speed_scale)
				elif SquadOrders.mode == SquadOrders.Mode.COMBAT and player and is_instance_valid(player):
					SquadWorkerLikeSteering.apply_wall_slide_toward(self, player.global_position, speed)
		
		State.SHOOT:
			velocity = Vector2.ZERO
			_sync_sprite_facing_to_nearest_enemy()
			# После attack имя анимации остаётся "attack", пока не запустят другую — проверяем is_playing().
			if not (sprite.animation == "attack" and sprite.is_playing()):
				if sprite.animation != "idle":
					sprite.play("idle")
			_start_shooting_if_needed()
		
		State.FLEE:
			var dir = global_position.direction_to(flee_target)
			velocity = dir * speed * flee_speed_multiplier
			if global_position.distance_to(flee_target) <= 12.0:
				velocity = Vector2.ZERO
				## Иначе `_refresh_state()` сразу выходит: `state == FLEE` → лучник навсегда в побеге и не стреляет.
				state = State.FOLLOW
				_refresh_state()
	## Стационарные стражи: без мягкого разведения — иначе игрок/спутники в радиусе ~28px
	## «выталкивают» лучника с башни каждый кадр (`character_unit._apply_soft_separation_to_velocity`).
	## В SHOOT не разводим: иначе velocity ≠ 0 и `attack()` / таймер выстрела не срабатывают.
	if state != State.SHOOT and (not stationary_guard or state == State.FLEE):
		_apply_soft_separation_to_velocity(delta)
	var v_sq_before_move := velocity.length_squared()
	var pos_before_move := global_position
	## При velocity≈0 `move_and_slide()` всё равно разрешает пересечения с коллизией земли/стен и
	## сдвигает CharacterBody2D — позиция из сцены «уползает». Стационарный страж без бега не зовём.
	if not _stationary_guard_skip_move_and_slide():
		move_and_slide()
	## Анимация после скольжения: иначе «run» при упоре в стену (намерение ≠ фактическое движение).
	if state == State.FOLLOW or state == State.FLEE:
		_sync_follow_or_flee_movement_animation()
	if state == State.FOLLOW and SquadOrders.mode == SquadOrders.Mode.PATROL and not stationary_guard:
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
	
	if state == State.FOLLOW or state == State.SHOOT:
		_refresh_state()

func _get_follow_velocity() -> Vector2:
	if stationary_guard:
		return Vector2.ZERO
	if _order_to_healer:
		_follow_nav.clear()
		return _get_healer_trek_velocity()
	if SquadOrders.mode == SquadOrders.Mode.HOLD:
		_follow_nav.clear()
		return Vector2.ZERO
	if SquadOrders.mode == SquadOrders.Mode.PATROL:
		## На базе патруль идёт по нав-сетке к зданиям — не сбрасываем путь каждый кадр.
		if Events.current_location != Events.LOCATION.BASE:
			_follow_nav.clear()
		return _get_base_patrol_velocity()
	if not player:
		_follow_nav.clear()
		return Vector2.ZERO
	
	var dist = global_position.distance_to(player.global_position)
	if dist <= follow_distance:
		_follow_nav.clear()
	if dist > follow_distance:
		if follow_use_navigation and _follow_nav:
			var dlt: float = get_physics_process_delta_time()
			var vn: Variant = _follow_nav.get_velocity_or_null(self, player.global_position, speed, dlt)
			if vn != null and vn is Vector2:
				var fv: Vector2 = vn as Vector2
				if fv.length_squared() > 1.0:
					return fv
				return SquadWorkerLikeSteering.steer_direction(self, player.global_position, speed) * speed
		return SquadWorkerLikeSteering.steer_direction(self, player.global_position, speed) * speed
	if dist < follow_stop_distance:
		return Vector2.ZERO
	return Vector2.ZERO


func _get_healer_trek_velocity() -> Vector2:
	if is_health_full():
		_order_to_healer = false
		return Vector2.ZERO
	var healer := get_tree().get_first_node_in_group("healer") as Node2D
	if healer == null or not is_instance_valid(healer):
		_order_to_healer = false
		return Vector2.ZERO
	var ha := healer.get_node_or_null("heal_area") as Area2D
	if ha == null:
		_order_to_healer = false
		return Vector2.ZERO
	if ha.overlaps_body(self):
		return Vector2.ZERO
	var steer := SquadWorkerLikeSteering.steer_direction(self, healer.global_position, speed)
	if steer.length_squared() < 1e-6:
		return Vector2.ZERO
	return steer * speed


func _get_base_patrol_velocity() -> Vector2:
	if Events.current_location == Events.LOCATION.BASE:
		return _get_base_patrol_velocity_base_zones()
	return _get_base_patrol_velocity_adventure_ring()


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


func _get_base_patrol_velocity_base_zones() -> Vector2:
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
	var spd := speed * patrol_speed_scale
	var dir := SquadWorkerLikeSteering.steer_direction(self, _patrol_goal, spd)
	if dir.length_squared() < 1e-8:
		_patrol_goal = SquadPatrol.pick_waypoint(_base_patrol_spawn, base_patrol_leash_radius)
		dir = SquadWorkerLikeSteering.steer_direction(self, _patrol_goal, spd)
	return dir * spd

func _start_shooting_if_needed() -> void:
	if state != State.SHOOT:
		return
	if enemies_in_range.is_empty():
		attack_timer.stop()
		return
	if _attack_shot_in_progress:
		return
	if attack_timer.is_stopped():
		attack()

func squad_rally_after_reposition() -> void:
	_reset_base_building_patrol_state()
	if _follow_nav:
		_follow_nav.clear()
	if state == State.SHOOT:
		state = State.FOLLOW
		if attack_timer:
			attack_timer.stop()
	if state == State.FLEE:
		state = State.FOLLOW


func _archer_close_enough_to_hero_for_combat() -> bool:
	if stationary_guard:
		return true
	if player == null or not is_instance_valid(player):
		return false
	if max_distance_from_hero_for_combat <= 0.0:
		return true
	return global_position.distance_to(player.global_position) <= max_distance_from_hero_for_combat


func _refresh_state() -> void:
	enemies_in_range = enemies_in_range.filter(func(e): return is_instance_valid(e))
	
	if state in [State.DEAD, State.FLEE]:
		return
	
	if _order_to_healer:
		state = State.FOLLOW
		attack_timer.stop()
		return
	
	if not enemies_in_range.is_empty() and _archer_close_enough_to_hero_for_combat():
		state = State.SHOOT
		_start_shooting_if_needed()
	else:
		state = State.FOLLOW
		attack_timer.stop()

func take_damage(amount: Variant) -> void:
	if state == State.DEAD:
		return
	var a: int = int(amount)
	super.take_damage(amount)
	if health_component == null or health_component.current_health <= 0:
		return
	if a > 0:
		_start_flee()


func _on_health_damage_applied(amount: int) -> void:
	if amount <= 0 or state == State.DEAD:
		return
	SoundManager.play_player_hurt()
	GameplayFacade.spawn_damage_number(self, amount, Vector2(-26, -100))


func _handle_death() -> void:
	_die()

func _start_flee() -> void:
	_order_to_healer = false
	var away_dir := Vector2.ZERO
	var nearest_dist := INF
	
	for e in enemies_in_range:
		if not is_instance_valid(e):
			continue
		var d = global_position.distance_to(e.global_position)
		if d < nearest_dist:
			nearest_dist = d
			away_dir = (global_position - e.global_position).normalized()
	
	if away_dir == Vector2.ZERO:
		if player:
			away_dir = (global_position - player.global_position).normalized()
		else:
			away_dir = Vector2.LEFT if facing_right else Vector2.RIGHT
	
	flee_target = global_position + away_dir * flee_distance
	state = State.FLEE
	attack_timer.stop()

func _die() -> void:
	state = State.DEAD
	attack_timer.stop()
	velocity = Vector2.ZERO
	if not bool(get_meta("no_squad_death", false)):
		SaveManager.notify_squad_member_died(self)
	var col := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if col:
		col.set_deferred("disabled", true)
	if attack_area:
		attack_area.set_deferred("monitoring", false)
	if sprite and sprite.sprite_frames and sprite.sprite_frames.has_animation("dead"):
		sprite.play("dead")
		await sprite.animation_finished
	queue_free()
