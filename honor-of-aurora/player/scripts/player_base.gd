extends CharacterBody2D

enum State { IDLE, RUN, ATTACK, SHIELD }
var state: State = State.IDLE
var last_dir: Vector2 = Vector2.DOWN

@export var speed: float = 200.0
@export var max_health: int = 100
@export var attack_damage: int = 10

@onready var anim = $AnimatedSprite2D
var health: int

var attack_index = 0

func _ready():
	health = max_health
	anim.connect("animation_finished", _on_anim_finished)

func _physics_process(delta):
	var dir = Vector2.ZERO
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
	if Input.is_action_just_pressed("shield") and state not in [State.ATTACK, State.SHIELD]:
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
			
			if last_dir.x < 0:
				anim.flip_h = true
			else:
				anim.flip_h = false
			
			anim.play(anim_name)
		
		State.SHIELD:
			if anim.sprite_frames.has_animation("shield"):
				anim.play("shield")
			else:
				back_to_movement()
		_:
			pass

func _on_anim_finished():
	if state == State.ATTACK:
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
