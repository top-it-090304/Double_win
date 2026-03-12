extends Node2D

const spawn_position = Vector2(600, 740)

@export var enemy_scenes: Array[PackedScene] = [
	preload("res://enemies/snake/Snake.tscn"),
	preload("res://enemies/gnome/gnome.tscn")
]

@export var spawn_points: Array[Marker2D] = []
@export var max_enemies: int = 30
@export var random_spawn: bool = true

var current_index: int = 0

func _ready():
	
	if SaveManager.boss_kill < 1:
		spawn_enemies()
	

func spawn_enemies():
	if spawn_points.is_empty():
		return
	
	if enemy_scenes.is_empty():
		return
	
	var spawned_count = 0
	for point in spawn_points:
		if spawned_count >= max_enemies:
			break
			
		var enemy_scene = get_next_enemy_scene()
		var enemy = enemy_scene.instantiate()
		enemy.global_position = point.global_position
		add_child(enemy)
		spawned_count += 1

func get_next_enemy_scene() -> PackedScene:
	if random_spawn:
		return enemy_scenes[randi() % enemy_scenes.size()]
	else:
		var scene = enemy_scenes[current_index]
		current_index = (current_index + 1) % enemy_scenes.size()
		return scene


func _on_timer_timeout() -> void:
	pass # Replace with function body.
