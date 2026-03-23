extends "res://characters/character_unit.gd"
## Союзник-НПС: группа ally.

func _ready() -> void:
	super._ready()
	add_to_group("ally")
