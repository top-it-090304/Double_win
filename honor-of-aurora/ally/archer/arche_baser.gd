extends CharacterBody2D

@export var arrow_scene : PackedScene
@export var attack_cooldown : float = 3.0
@export var idle_flip_interval : float = 10.0

var enemies_in_range : Array = []
var facing_right := true

@onready var attack_area = $attack_area
@onready var sprite = $AnimatedSprite2D

var attack_timer : Timer
var idle_timer : Timer

func _ready():
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

func _on_enemy_entered(body):
	if body.is_in_group("enemy"):
		enemies_in_range.append(body)
		if attack_timer.is_stopped():
			call_deferred("attack")
			attack_timer.start()

func _on_enemy_exited(body):
	if body.is_in_group("enemy"):
		enemies_in_range.erase(body)
		if enemies_in_range.is_empty():
			attack_timer.stop()
			sprite.play("idle")

func _on_attack_timer_timeout():
	call_deferred("attack")

func attack():
	if enemies_in_range.is_empty():
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
		sprite.play("idle")

func _on_idle_timer_timeout():
	if not enemies_in_range and sprite.animation != "attack":
		facing_right = !facing_right
		sprite.flip_h = !facing_right
