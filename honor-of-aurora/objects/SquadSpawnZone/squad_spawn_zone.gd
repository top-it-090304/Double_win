extends Area2D

func _ready() -> void:
	add_to_group("squad_spawn_zone")
	add_to_group("base_patrol_zone")
	## Игрок (слой 2) + отряд (слой 8): маска 10 — зона видит вход союзников.
	monitoring = true
	collision_layer = 0
	collision_mask = 10
