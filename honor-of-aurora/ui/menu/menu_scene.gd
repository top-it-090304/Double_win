extends Node2D 

@export var cloud_scene: PackedScene
@export var spawn_x: float = -200 
@export var spawn_interval: float = 2.0

var spawn_timer: Timer

func _ready():
	await get_tree().process_frame
	
	var screen_height = get_viewport().get_visible_rect().size.y
	spawn_timer = Timer.new()
	spawn_timer.wait_time = spawn_interval
	spawn_timer.autostart = true
	add_child(spawn_timer)
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)

func _on_spawn_timer_timeout():
	var cloud_instance = cloud_scene.instantiate()
	
	var screen_height = get_viewport().get_visible_rect().size.y
	
	var random_y = randf_range(0, screen_height)
	
	cloud_instance.position = Vector2(spawn_x, random_y)
	add_child(cloud_instance)
