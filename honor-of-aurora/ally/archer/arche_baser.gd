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
## Приказ идти к монаху (только лучник, база).
var _order_to_healer: bool = false
var _base_attack_cooldown: float = 3.0
var _base_max_health: int = 60
var _base_speed: float = 160.0
var _base_projectile_damage: int = 10

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
	sprite.play("idle")
	
	attack_timer = Timer.new()
	attack_timer.wait_time = attack_cooldown
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

func _on_enemy_entered(body):
	if body.is_in_group("enemy"):
		enemies_in_range.append(body)
		_refresh_state()

func _on_enemy_exited(body):
	if body.is_in_group("enemy"):
		enemies_in_range.erase(body)
		_refresh_state()

func _on_attack_timer_timeout():
	if state == State.SHOOT and velocity.length() <= 0.1:
		call_deferred("attack")

func attack():
	if state != State.SHOOT:
		return
	if velocity.length() > 0.1:
		return
	
	var target
	for enemy in enemies_in_range:
		if is_instance_valid(enemy):
			target = enemy
			break
	if not target:
		enemies_in_range.clear()
		return
	
	var dir = (target.global_position - global_position).normalized()
	
	if dir.x > 0 and not facing_right:
		facing_right = true
		sprite.flip_h = false
	elif dir.x < 0 and facing_right:
		facing_right = false
		sprite.flip_h = true
	
	sprite.play("attack")
	await get_tree().create_timer(0.6).timeout
	
	if arrow_scene:
		var arrow = arrow_scene.instantiate()
		arrow.global_position = global_position + dir * 30
		arrow.direction = dir
		arrow.damage = projectile_damage
		get_tree().current_scene.add_child(arrow)

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
		move_and_slide()
		return
	
	if not player or not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player") as Node2D
	
	match state:
		State.FOLLOW:
			velocity = _get_follow_velocity()
			if velocity.length() > 0.1:
				if sprite.animation != "run":
					sprite.play("run")
				sprite.flip_h = velocity.x < 0
			else:
				if sprite.animation != "idle":
					sprite.play("idle")
		
		State.SHOOT:
			velocity = Vector2.ZERO
			# После attack имя анимации остаётся "attack", пока не запустят другую — проверяем is_playing().
			if not (sprite.animation == "attack" and sprite.is_playing()):
				if sprite.animation != "idle":
					sprite.play("idle")
			_start_shooting_if_needed()
		
		State.FLEE:
			var dir = global_position.direction_to(flee_target)
			velocity = dir * speed * flee_speed_multiplier
			if sprite.animation != "run":
				sprite.play("run")
			sprite.flip_h = velocity.x < 0
			
			if global_position.distance_to(flee_target) <= 12.0:
				velocity = Vector2.ZERO
				_refresh_state()
	
	_apply_soft_separation_to_velocity(delta)
	move_and_slide()
	
	if state == State.FOLLOW:
		_refresh_state()

func _get_follow_velocity() -> Vector2:
	if stationary_guard:
		return Vector2.ZERO
	if _order_to_healer:
		return _get_healer_trek_velocity()
	if SquadOrders.mode == SquadOrders.Mode.HOLD:
		return Vector2.ZERO
	if SquadOrders.mode == SquadOrders.Mode.PATROL:
		return _get_base_patrol_velocity()
	if not player:
		return Vector2.ZERO
	
	var dist = global_position.distance_to(player.global_position)
	if dist > follow_distance:
		return global_position.direction_to(player.global_position) * speed
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
	var dir := global_position.direction_to(healer.global_position)
	if dir.length_squared() < 1e-6:
		return Vector2.ZERO
	return dir * speed


func _get_base_patrol_velocity() -> Vector2:
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
	var dir := global_position.direction_to(_patrol_goal)
	if dir.length_squared() < 1e-8:
		_patrol_goal = SquadPatrol.pick_waypoint(_base_patrol_spawn, base_patrol_leash_radius)
		dir = global_position.direction_to(_patrol_goal)
	return dir * speed * patrol_speed_scale

func _start_shooting_if_needed() -> void:
	if state != State.SHOOT:
		return
	if enemies_in_range.is_empty():
		attack_timer.stop()
		return
	if attack_timer.is_stopped():
		attack_timer.start()
		call_deferred("attack")

func _refresh_state() -> void:
	enemies_in_range = enemies_in_range.filter(func(e): return is_instance_valid(e))
	
	if state in [State.DEAD, State.FLEE]:
		return
	
	if _order_to_healer:
		state = State.FOLLOW
		attack_timer.stop()
		return
	
	if not enemies_in_range.is_empty():
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
