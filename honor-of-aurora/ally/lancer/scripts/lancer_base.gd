extends "res://characters/companion_unit.gd"

## Копейщик: `black_lancer_frames.tres` — направленные атаки копьём.

func _ready() -> void:
	speed = 150.0
	super._ready()
	add_to_group("ally_lancer")


func _get_melee_hit_reach() -> float:
	return 108.0


func _get_melee_hit_radius() -> float:
	return 22.0


func _attack_anim_for_direction(dir: Vector2) -> StringName:
	if sprite == null:
		return &"right_attack"
	var d := dir
	if d.length() < 0.01:
		d = Vector2.RIGHT
	else:
		d = d.normalized()
	var x: float = d.x
	var y: float = d.y
	var ax: float = absf(x)
	var ay: float = absf(y)
	sprite.flip_h = x < 0.0
	if ay > ax * 1.05:
		if y > 0.0:
			return &"down_attack"
		return &"up_attack"
	if ax > ay * 1.05:
		return &"right_attack"
	if y > 0.0:
		return &"down_right_attack"
	return &"up_right_attack"
