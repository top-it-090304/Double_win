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

var state: State = State.FOLLOW
var player: Node2D = null
var _attack_cd: float = 0.0
var _paralysis_time: float = 0.0
## Направление удара (к цели) для расчёта точки острия в мировых координатах.
var _attack_hit_dir: Vector2 = Vector2.RIGHT

@onready var sprite: AnimatedSprite2D = get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
@onready var attack_area: Area2D = get_node_or_null("AttackArea") as Area2D


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
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	if sprite:
		sprite.animation_finished.connect(_on_sprite_animation_finished)
	_play_idle()
	player = get_tree().get_first_node_in_group("player") as Node2D


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

	move_and_slide()


func _process_follow(_delta: float) -> void:
	var enemy := _nearest_enemy_in_attack_area()
	if enemy and _attack_cd <= 0.0 and attack_area:
		_start_attack(enemy)
		return

	if not player:
		velocity = Vector2.ZERO
		_play_idle()
		return

	var dist := global_position.distance_to(player.global_position)
	if dist > follow_distance:
		velocity = global_position.direction_to(player.global_position) * speed
		_face_velocity(velocity)
		_play_run()
	elif dist < follow_stop_distance:
		velocity = Vector2.ZERO
		_play_idle()
	else:
		velocity = Vector2.ZERO
		_play_idle()


func _face_velocity(v: Vector2) -> void:
	if sprite and absf(v.x) > 0.05:
		sprite.flip_h = v.x < 0.0


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


func _start_attack(target: Node2D) -> void:
	state = State.ATTACK
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
	var tip := global_position + _attack_hit_dir * _get_melee_hit_reach()
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
		if col is Node and (col as Node).is_in_group("enemy"):
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
