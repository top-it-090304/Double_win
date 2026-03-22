extends Area2D

func _ready() -> void:
	add_to_group("squad_spawn_zone")
	monitoring = false
	collision_layer = 0
	collision_mask = 0
