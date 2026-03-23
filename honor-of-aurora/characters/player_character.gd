extends "res://characters/ally_unit.gd"
## Игрок: группы ally + player.

func _ready() -> void:
	super._ready()
	add_to_group("player")


func _handle_death() -> void:
	## Скрипт героя (воин) обязан переопределить — см. worrier_base.die().
	pass
