extends "res://characters/character_unit.gd"
## Враг: группа enemy.

@export var health: int = 50


func _ready() -> void:
	super._ready()
	add_to_group("enemy")
	call_deferred("_sync_spawn_health_from_export")


func _sync_spawn_health_from_export() -> void:
	if health_component:
		health_component.set_max_and_current(health)


func _get_initial_health() -> int:
	return health


func _get_initial_max_health() -> int:
	return health
