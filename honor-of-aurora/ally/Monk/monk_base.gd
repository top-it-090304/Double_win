extends CharacterBody2D

enum State { IDLE, RUN, HEAL }
var state = State.IDLE
var target_player = null
var can_heal = true

@export var speed = 150.0
@export var heal_amount = 50
@export var heal_cooldown = 1.0
@export var health = 100
@export var max_health = 100

@onready var anim = $AnimatedSprite2D
@onready var detection = $detection_area
@onready var heal_area = $heal_area
@onready var cooldown = $HealCooldown

func _ready():
	add_to_group("healer")
	detection.body_entered.connect(_on_detection)
	heal_area.body_entered.connect(_on_heal_area)
	cooldown.timeout.connect(_on_cooldown)
	cooldown.one_shot = true

func _physics_process(delta):
	if state == State.HEAL:
		return
	if target_player and is_instance_valid(target_player):
		var dir = global_position.direction_to(target_player.global_position)
		velocity = dir * speed
		move_and_slide()
		state = State.RUN if velocity.length() > 0 else State.IDLE
	else:
		velocity = Vector2.ZERO
		state = State.IDLE
	update_animation()

func update_animation():
	match state:
		State.IDLE:
			anim.play("idle")
		State.RUN:
			anim.play("run")
			anim.flip_h = velocity.x < 0

func _on_detection(body):
	if body.is_in_group("player"):
		target_player = body

func _on_heal_area(body):
	if not can_heal:
		return
	if body.is_in_group("player") or body.is_in_group("healer"):
		_heal(body)

func _heal(target):
	can_heal = false
	cooldown.start(heal_cooldown)
	if target.has_method("heal"):
		target.heal(heal_amount)
	elif target.has_method("take_damage"):
		target.take_damage(-heal_amount)
	if target.has_method("play_heal_effect"):
		target.play_heal_effect()
	play_heal_effect()
	state = State.HEAL
	anim.play("heal")
	await anim.animation_finished
	state = State.IDLE

func play_heal_effect():
	if anim.sprite_frames.has_animation("heal_effect"):
		anim.play("heal_effect")
		await get_tree().create_timer(0.3).timeout
		update_animation()

func _on_cooldown():
	can_heal = true

func take_damage(amount):
	health -= amount
	if health <= 0:
		queue_free()
	elif amount > 0 and can_heal and health < max_health:
		_heal(self)
