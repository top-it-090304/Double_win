extends "res://characters/ally_unit.gd"
## Игрок: группы ally + player.

func _ready() -> void:
	## У героя свой HUD-бар; мини-бар над головой не нужен (см. character_unit.show_mini_hp_bar).
	show_mini_hp_bar = false
	super._ready()
	add_to_group("player")


func _handle_death() -> void:
	## Скрипт героя (воин) обязан переопределить — см. worrier_base.die().
	pass
