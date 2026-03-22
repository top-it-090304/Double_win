extends CharacterBody2D

enum State { PATROL, CHASE, ATTACK, DEATH, HIT }
var state: State = State.PATROL

@onready var anim = $AnimatedSprite
@onready var detection_area = $DetectionArea
@onready var attack_area = $AttackArea
@onready var detection_shape = $DetectionArea/DetectionShape
@onready var attack_shape = $AttackArea/AttackShape
@export var exp_reward: int = 10

@export var speed: float = 100.0
@export var health: int = 50
@export var attack_damage: int = 10
@export var attack_cooldown: float = 2.0
@export var patrol_change_time: float = 2.0
@export var gold_reward: int = 75
@export var attack_radius: float = 100.0
@export var detection_radius: float = 500.0

var target: Node2D = null
var can_attack: bool = true
var last_dir: Vector2 = Vector2.DOWN
var patrol_dir: Vector2
var patrol_timer: float = 0.0
var attack_cooldown_timer: Timer
var potential_targets: Array[Node2D] = []

const _SEP_EPS := 1e-3

func _dir_toward_target(delta_pos: Vector2) -> Vector2:
	if delta_pos.length() > _SEP_EPS:
		return delta_pos.normalized()
	if last_dir.length() > _SEP_EPS:
		return last_dir.normalized()
	return Vector2.RIGHT

func _away_from_target(delta_pos: Vector2) -> Vector2:
	if delta_pos.length() > _SEP_EPS:
		return -delta_pos.normalized()
	if last_dir.length() > _SEP_EPS:
		return -last_dir.normalized()
	if get_slide_collision_count() > 0:
		return get_slide_collision(0).get_normal()
	return Vector2.RIGHT.rotated(randf() * TAU)

func _ready():
	add_to_group("enemy")
	detection_shape.shape.radius = detection_radius
	attack_shape.shape.radius = attack_radius
	
	detection_area.body_entered.connect(_on_detection_area_entered)
	detection_area.body_exited.connect(_on_detection_area_exited)
	attack_area.body_entered.connect(_on_attack_area_entered)
	anim.animation_finished.connect(_on_anim_finished)
	
	attack_cooldown_timer = Timer.new()
	attack_cooldown_timer.one_shot = true
	attack_cooldown_timer.timeout.connect(_on_attack_cooldown_timeout)
	add_child(attack_cooldown_timer)
	
	randomize()
	patrol_dir = Vector2.RIGHT.rotated(randf_range(0, TAU))

func _physics_process(delta):
	var previous_position := global_position
	
	match state:
		State.PATROL:
			velocity = patrol_dir * speed
			patrol_timer += delta
			if patrol_timer >= patrol_change_time:
				patrol_timer = 0.0
				patrol_dir = Vector2.RIGHT.rotated(randf_range(0, TAU))
			if is_on_wall():
				patrol_dir = patrol_dir.rotated(randf_range(PI/4, PI/2))
		
		State.CHASE:
			_select_target()
			if target and is_instance_valid(target):
				if attack_area.overlaps_body(target):
					velocity = Vector2.ZERO
					if can_attack:
						start_attack()
				else:
					last_dir = _dir_toward_target(target.global_position - global_position)
					velocity = last_dir * speed
			else:
				state = State.PATROL
		
		State.ATTACK, State.HIT, State.DEATH:
			velocity = Vector2.ZERO
	
	move_and_slide()
	
	# Дополнительная логика, чтобы не застревали в стенах/текстурах при преследовании:
	if state == State.CHASE and target and is_instance_valid(target):
		var moved_distance := previous_position.distance_to(global_position)
		if moved_distance < 1.0 and get_slide_collision_count() > 0:
			var c = get_slide_collision(0)
			if c:
				var n: Vector2 = c.get_normal()
				var toward := target.global_position - global_position
				var toward_norm := _dir_toward_target(toward)
				var slide_dir := toward_norm.slide(n)
				if slide_dir.length() > 0.1:
					velocity = slide_dir.normalized() * speed
					move_and_slide()
		
		# Лёгкое отталкивание от цели, чтобы не \"липнуть\" вплотную.
		var to_target := target.global_position - global_position
		var min_distance := attack_radius * 0.4
		if to_target.length() < min_distance:
			var push_dir := _away_from_target(to_target)
			if push_dir.length() > _SEP_EPS:
				velocity = push_dir * speed * 0.4
				move_and_slide()
	
	update_animation()

func _on_detection_area_entered(body):
	if body is Node2D and (body.is_in_group("player") or body.is_in_group("ally")):
		potential_targets.append(body)
		_select_target()
		if state not in [State.ATTACK, State.DEATH, State.HIT]:
			state = State.CHASE

func _on_detection_area_exited(body):
	if body is Node2D:
		potential_targets.erase(body)
		if body == target:
			target = null
		if potential_targets.is_empty() and state == State.CHASE:
			state = State.PATROL

func _on_attack_area_entered(body):
	if body == target and can_attack and state not in [State.ATTACK, State.DEATH, State.HIT]:
		start_attack()

func start_attack():
	SoundManager.play_enemy_attack_swing()
	state = State.ATTACK
	can_attack = false
	if target:
		var dir = _dir_toward_target(target.global_position - global_position)
		last_dir = dir
		anim.flip_h = dir.x < 0
	anim.play("attack")
	attack_cooldown_timer.start(attack_cooldown)

func apply_damage():
	if target and attack_area.overlaps_body(target) and target.has_method("take_damage"):
		target.take_damage(attack_damage)

func _on_anim_finished():
	match anim.animation:
		"attack":
			apply_damage()
			_select_target()
			state = State.CHASE if target and detection_area.overlaps_body(target) else State.PATROL
		"hit":
			_select_target()
			if target:
				state = State.ATTACK if attack_area.overlaps_body(target) and can_attack else State.CHASE if detection_area.overlaps_body(target) else State.PATROL
			else:
				state = State.PATROL

func _on_attack_cooldown_timeout():
	can_attack = true

func update_animation():
	if state in [State.PATROL, State.CHASE]:
		if velocity.length() > 0:
			anim.play("run")
			if velocity.x != 0:
				anim.flip_h = velocity.x < 0
		else:
			anim.play("idle")

func take_damage(amount: int):
	SoundManager.play_enemy_hit()
	health -= amount
	
	if health <= 0:
		die()
		return
	
	if state != State.DEATH and state != State.HIT and anim.sprite_frames.has_animation("hit"):
		state = State.HIT
		anim.play("hit")
	
	show_damage_number(amount)

func die():
	if is_in_group("BOSS"):
		SoundManager.play_boss_defeat()
	else:
		SoundManager.play_death()
	GameManager.add_exp(exp_reward)
	state = State.DEATH
	anim.play("dead")
	
	if is_in_group("BOSS"):
		GameManager.boss_kill()
	
	$CollisionShape2D.set_deferred("disabled", true)
	await anim.animation_finished
	GameManager.add_gold(gold_reward)
	queue_free()

func show_damage_number(amount: int):
	var damage_number = preload("res://ui/DamageNumber/damage_number.tscn").instantiate()
	damage_number.get_node("Label").text = str(amount)
	add_child(damage_number)
	damage_number.position = Vector2(-26, -80)

func _select_target() -> void:
	potential_targets = potential_targets.filter(func(t): return is_instance_valid(t) and detection_area.overlaps_body(t))
	if potential_targets.is_empty():
		target = null
		return
	
	# Prefer player if present; otherwise closest ally.
	for t in potential_targets:
		if t and t.is_in_group("player"):
			target = t
			return
	
	var best: Node2D = null
	var best_dist := INF
	for t in potential_targets:
		if not t:
			continue
		var d = global_position.distance_to(t.global_position)
		if d < best_dist:
			best_dist = d
			best = t
	target = best
