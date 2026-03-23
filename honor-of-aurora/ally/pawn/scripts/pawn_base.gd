extends "res://characters/companion_unit.gd"

## Чёрная пешка: `black_pawn_frames.tres` — idle, run, interact_* (атака ножом).

func _ready() -> void:
	speed = 120.0
	super._ready()
	add_to_group("ally_pawn")


func _get_melee_hit_reach() -> float:
	return 58.0


func _get_melee_hit_radius() -> float:
	return 20.0


func _attack_anim_for_direction(_dir: Vector2) -> StringName:
	return &"interact_knife"
