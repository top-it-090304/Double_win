extends CharacterBody2D

@export var arrow_scene : PackedScene
@export var attack_cooldown : float = 3.0
@export var idle_flip_interval : float = 10.0

var enemies_in_range : Array = []
var facing_right := true

@onready var attack_area = $attack_area
@onready var animated_sprite = $AnimatedSprite2D

var attack_timer : Timer
var idle_timer : Timer

func _ready():
	animated_sprite.play("idle")
	
	attack_timer = Timer.new()
	attack_timer.wait_time = attack_cooldown
	attack_timer.one_shot = false
	attack_timer.timeout.connect(_on_attack_timer_timeout)
	add_child(attack_timer)
	
	idle_timer = Timer.new()
	idle_timer.wait_time = idle_flip_interval
	idle_timer.one_shot = false
	idle_timer.timeout.connect(_on_idle_timer_timeout)
	add_child(idle_timer)
	idle_timer.start()
	
	attack_area.body_entered.connect(_on_enemy_entered)
	attack_area.body_exited.connect(_on_enemy_exited)

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
			if animated_sprite.animation != "idle":
				animated_sprite.play("idle")

func _on_attack_timer_timeout():
	call_deferred("attack")

func attack():
	if enemies_in_range.is_empty():
		return
	
	var target = null
	for enemy in enemies_in_range:
		if is_instance_valid(enemy):
			target = enemy
			break
	
	if target == null:
		enemies_in_range.clear()
		return
	
	var direction_to_target = (target.global_position - global_position).normalized()
	
	if direction_to_target.x > 0 and not facing_right:
		facing_right = true
		animated_sprite.flip_h = false
	elif direction_to_target.x < 0 and facing_right:
		facing_right = false
		animated_sprite.flip_h = true
	
	animated_sprite.play("attack")
	
	if not animated_sprite.is_connected("animation_finished", Callable(self, "_on_attack_animation_finished")):
		animated_sprite.animation_finished.connect(_on_attack_animation_finished)
	
	if arrow_scene:
		var arrow = arrow_scene.instantiate()
		var offset = direction_to_target * 30
		arrow.global_position = global_position + offset
		arrow.direction = direction_to_target
		get_tree().current_scene.add_child(arrow)

func _on_attack_animation_finished():
	if animated_sprite.animation == "attack":
		animated_sprite.play("idle")

func _on_idle_timer_timeout():
	if enemies_in_range.is_empty() and animated_sprite.animation != "attack":
		facing_right = not facing_right
		animated_sprite.flip_h = not facing_right
