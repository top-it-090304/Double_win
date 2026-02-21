extends CharacterBody2D

enum State { PATROL, CHASE, ATTACK, DEATH }
var state: State = State.PATROL

@onready var anim = $AnimatedSprite
@onready var detection_area = $DetectionArea
@onready var attack_area = $AttackArea

@export var speed: float = 100.0
@export var health: int = 50
@export var attack_damage: int = 5
@export var attack_cooldown: float = 1.0
@export var detection_radius: float = 500.0
@export var patrol_change_time: float = 2.0

var player: Node2D = null
var can_attack: bool = true
var last_dir: Vector2 = Vector2.DOWN
var patrol_dir: Vector2
var patrol_timer: float = 0.0

func _ready():
	$DetectionArea/DetectionShape.shape.radius = detection_radius
	
	detection_area.connect("body_entered", _on_detection_area_entered)
	detection_area.connect("body_exited", _on_detection_area_exited)
	attack_area.connect("body_entered", _on_attack_area_entered)
	anim.connect("animation_finished", _on_anim_finished)
	
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
		State.DEATH:
			velocity = Vector2.ZERO
	
	move_and_slide()
	update_animation()


func _on_detection_area_entered(body):
	if body.is_in_group("player"):
		player = body
		if state != State.ATTACK and state != State.DEATH:

			state = State.CHASE


func _on_detection_area_exited(body):
	if body == player:
		player = null
		if state == State.CHASE:
			state = State.PATROL

func _on_attack_area_entered(body):
	if body == player and can_attack and state != State.ATTACK and state != State.DEATH:
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
		await get_tree().create_timer(attack_cooldown).timeout
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
		State.ATTACK:
			pass
		State.DEATH:
			anim.play("death")

func take_damage(amount):
	health -= amount
	if health <= 0 and state != State.DEATH:
		state = State.DEATH
		anim.play("death")
		$CollisionShape2D.set_deferred("disabled", true)
		await anim.animation_finished
		queue_free()
