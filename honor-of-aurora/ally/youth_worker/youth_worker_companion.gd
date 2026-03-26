extends "res://ally/pawn/scripts/pawn_base.gd"
## Сюжетный юноша: на базе — как рабочий (добыча); в походе — как спутник. Не в pawn_count; смерть → worker_youth_dead.

func _ready() -> void:
	add_to_group("story_youth_companion")
	max_health = 55
	attack_damage = 12
	super._ready()
	speed = 130.0
