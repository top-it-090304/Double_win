extends "res://characters/character_unit.gd"
## Союзник-НПС: группа ally.

func squad_rally_after_reposition() -> void:
	pass


func _ready() -> void:
	super._ready()
	add_to_group("ally")
