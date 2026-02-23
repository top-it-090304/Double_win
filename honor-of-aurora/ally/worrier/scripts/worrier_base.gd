extends CharacterBody2D

enum State { IDLE, RUN, ATTACK, SHIELD, DEATH }
var state: State = State.IDLE
var last_dir: Vector2 = Vector2.DOWN
var health_bar: TextureProgressBar

@export var speed: float = 250.0
@export var max_health: int = 100
@export var attack_damage: int = 10

@onready var attack_area = $AttackArea
@onready var anim = $AnimatedSprite2D

signal health_changed(current_health)

var health: int

var attack_index = 0

func _ready():
	add_to_group("player")
	
	var bar_node = get_tree().get_first_node_in_group("player_health_bar")
	if bar_node and bar_node is TextureProgressBar:
		health_bar = bar_node
	else:
		push_error("Health bar not found! Проверьте группу 'player_health_bar'.")
		return
	
	
	health = max_health
	health_bar.max_value = max_health
	health_bar.value = health
	
	anim.connect("animation_finished", _on_anim_finished)
	
	health_bar.max_value = max_health
	health_bar.value = health

func _physics_process(delta):
	var dir = Vector2.ZERO
	
	if state == State.DEATH:
		move_and_slide()
		return
	
	if state not in [State.ATTACK, State.SHIELD]:
		dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	if dir != Vector2.ZERO:
		last_dir = dir
		velocity = dir * speed
	else:
		velocity = Vector2.ZERO
	move_and_slide()
	
	if state not in [State.ATTACK, State.SHIELD]:
		if velocity.length() > 0:
			if state != State.RUN:
				state = State.RUN
		else:
			if state != State.IDLE:
				state = State.IDLE
	
	if Input.is_action_just_pressed("attack") and state not in [State.ATTACK, State.SHIELD]:
		change_state(State.ATTACK)
	if Input.is_action_just_pressed("shield") and state != State.SHIELD:
		change_state(State.SHIELD)
	if state == State.SHIELD and Input.is_action_just_released("shield"):
		back_to_movement()
	
	update_anim()

func change_state(new_state: State):
	if state == new_state: return
	state = new_state
	
	match state:
		State.ATTACK:
			var anim_name = ""
			
			if abs(last_dir.y) > abs(last_dir.x):
				if last_dir.y > 0:
					anim_name = "attack_1"
				else:
					anim_name = "attack_2"
			else:
				attack_index = (attack_index + 1) % 2
				anim_name = "attack_1" if attack_index == 0 else "attack_2"
			
			if last_dir.x < 0 or last_dir.y > 0:
				anim.flip_h = true
			else:
				anim.flip_h = false
			
			anim.play(anim_name)
		
		State.SHIELD:
			velocity = Vector2.ZERO
			if anim.sprite_frames.has_animation("shield"):
				anim.play("shield")
			else:
				back_to_movement()
		_:
			pass

func _on_anim_finished():
	if state == State.ATTACK:
		apply_damage()
		back_to_movement()

func back_to_movement():
	state = State.RUN if velocity.length() > 0 else State.IDLE

func update_anim():
	match state:
		State.IDLE:
			anim.play("idle")
		State.RUN:
			anim.play("run")
			if velocity.x != 0:
				anim.flip_h = velocity.x < 0
		State.DEATH:
			anim.play("dead")

func take_damage(amount):
	var final_damage = amount
	if state == State.SHIELD:
		final_damage = int(amount * 0.2)
	health -= final_damage
	health_changed.emit(health)
	if health <= 0 and state != State.DEATH:
		die()
	show_damage_number(final_damage)

func die():
	state = State.DEATH
	velocity = Vector2.ZERO
	anim.play("dead")
	await anim.animation_finished
	queue_free()
	
func apply_damage():
	for body in attack_area.get_overlapping_bodies():
		if body.is_in_group("enemy") and body.has_method("take_damage"):
			body.take_damage(attack_damage)

func show_damage_number(amount: int):
	var damage_number = preload("res://ui/DamageNumber/damage_number.tscn").instantiate()
	damage_number.get_node("Label").text = str(amount)
	add_child(damage_number)
	damage_number.position = Vector2(-26, -120)  
