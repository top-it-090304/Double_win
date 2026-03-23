extends "res://characters/character_unit.gd"
## Союзник-лучник (группа ally в _ready).

@export var arrow_scene : PackedScene
@export var attack_cooldown : float = 3.0
@export var idle_flip_interval : float = 10.0

@export var speed: float = 160.0
@export var follow_distance: float = 140.0
@export var follow_stop_distance: float = 110.0

@export var max_health: int = 60

@export var flee_distance: float = 220.0
@export var flee_speed_multiplier: float = 1.25
## Стоит на башне / не следует за героем: только idle + смена flip по таймеру и стрельба по врагам.
@export var stationary_guard: bool = false

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

func _ready() -> void:
	super._ready()
	add_to_group("ally")
	add_to_group("ally_archer")
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
		get_tree().current_scene.add_child(arrow)

func _on_animation_finished():
	if sprite.animation == "attack":
		_refresh_state()

func _on_idle_timer_timeout():
	if state == State.DEAD or state == State.FLEE:
		return
	if stationary_guard:
		return
	if not enemies_in_range and sprite.animation != "attack":
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
	
	move_and_slide()
	
	if state == State.FOLLOW:
		_refresh_state()

func _get_follow_velocity() -> Vector2:
	if stationary_guard:
		return Vector2.ZERO
	if not player:
		return Vector2.ZERO
	
	var dist = global_position.distance_to(player.global_position)
	if dist > follow_distance:
		return global_position.direction_to(player.global_position) * speed
	if dist < follow_stop_distance:
		return Vector2.ZERO
	return Vector2.ZERO

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
