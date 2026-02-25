extends CharacterBody2D

enum State { PATROL, CHASE, ATTACK, DEATH, HIT }
var state: State = State.PATROL

@onready var anim = $AnimatedSprite
@onready var detection_area = $DetectionArea
@onready var attack_area = $AttackArea

@export var speed: float = 100.0
@export var health: int = 50
@export var attack_damage: int = 5
@export var attack_cooldown: float = 2.0
@export var detection_radius: float = 500.0
@export var patrol_change_time: float = 2.0
@export var gold_reward: int = 75

var player: Node2D = null
var can_attack: bool = true
var last_dir: Vector2 = Vector2.DOWN
var patrol_dir: Vector2
var patrol_timer: float = 0.0

var attack_cooldown_timer: Timer

func _ready():
	add_to_group("enemy")
	$DetectionArea/DetectionShape.shape.radius = detection_radius
	
	detection_area.connect("body_entered", _on_detection_area_entered)
	detection_area.connect("body_exited", _on_detection_area_exited)
	attack_area.connect("body_entered", _on_attack_area_entered)
	anim.connect("animation_finished", _on_anim_finished)
	

	attack_cooldown_timer = Timer.new()
	attack_cooldown_timer.one_shot = true
	attack_cooldown_timer.timeout.connect(_on_attack_cooldown_timeout)
	add_child(attack_cooldown_timer)
	
	randomize()
	patrol_dir = Vector2.RIGHT.rotated(randf_range(0, TAU))

func _physics_process(delta):
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
			if player:
				if attack_area.overlaps_body(player):
					velocity = Vector2.ZERO
					if can_attack:
						start_attack()
				else:
					var direction = (player.global_position - global_position).normalized()
					last_dir = direction
					velocity = direction * speed
					update_animation()
			else:
				state = State.PATROL
		
		State.ATTACK:
			velocity = Vector2.ZERO
		
		State.HIT:
			velocity = Vector2.ZERO
		
		State.DEATH:
			velocity = Vector2.ZERO
	
	move_and_slide()
	update_animation()

func _on_detection_area_entered(body):
	if body.is_in_group("player"):
		player = body
		if state != State.ATTACK and state != State.DEATH and state != State.HIT:
			state = State.CHASE

func _on_detection_area_exited(body):
	if body == player:
		player = null
		if state == State.CHASE:
			state = State.PATROL

func _on_attack_area_entered(body):
	if body == player and can_attack and state != State.ATTACK and state != State.DEATH and state != State.HIT:
		start_attack()

func start_attack():
	state = State.ATTACK
	can_attack = false
	velocity = Vector2.ZERO
	if player:
		var dir = (player.global_position - global_position).normalized()
		last_dir = dir
		anim.flip_h = (dir.x < 0)
	anim.play("attack")
	attack_cooldown_timer.start(attack_cooldown)

func apply_damage():
	if player and attack_area.overlaps_body(player):
		player.take_damage(attack_damage)

func _on_anim_finished():
	if anim.animation == "attack":
		apply_damage()
		if player and detection_area.overlaps_body(player):
			state = State.CHASE
		else:
			state = State.PATROL

	
	elif anim.animation == "hit":
		if player:
			if attack_area.overlaps_body(player):
				if can_attack:
					start_attack()
				else:
					state = State.CHASE
			elif detection_area.overlaps_body(player):
				state = State.CHASE
			else:
				state = State.PATROL
		else:
			state = State.PATROL

func _on_attack_cooldown_timeout():
	can_attack = true

func update_animation():
	match state:
		State.PATROL, State.CHASE:
			if velocity.length() > 0:
				anim.play("run")
				if velocity.x != 0:
					anim.flip_h = velocity.x < 0
			else:
				anim.play("idle")
		State.ATTACK, State.HIT, State.DEATH:
			pass

func take_damage(amount: int):
	health -= amount
	
	if health <= 0 and state != State.DEATH:
		die()
		return
	
	if state != State.DEATH and state != State.HIT:
		if anim.sprite_frames.has_animation("hit"):
			state = State.HIT
			anim.play("hit")
		else:
			pass
	
	show_damage_number(amount)

func die():
	state = State.DEATH
	anim.play("dead")
	$CollisionShape2D.set_deferred("disabled", true)
	await anim.animation_finished
	GameManager.add_gold(gold_reward)
	
	queue_free()

func show_damage_number(amount: int):
	var damage_number = preload("res://ui/DamageNumber/damage_number.tscn").instantiate()
	damage_number.get_node("Label").text = str(amount)
	add_child(damage_number)
	damage_number.position = Vector2(-26, -80)  
