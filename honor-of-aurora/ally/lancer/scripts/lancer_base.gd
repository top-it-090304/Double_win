extends "res://characters/companion_unit.gd"

## Чёрный копейщик: все клипы из `black_lancer_frames.tres` (клетки атласа 320×320, не 192).
## idle, run, down_attack, down_defence, down_right_attack, down_right_defence,
## right_attack, right_defence, up_attack, up_defence, up_right_attack, up_right_defence.
@export var speed: float = 150.0


func _ready() -> void:
	super._ready()
	play_unit_animation(&"idle")


func play_unit_animation(anim: StringName) -> void:
	var sprite := _sprite()
	if sprite:
		sprite.play(anim)


func _sprite() -> AnimatedSprite2D:
	return get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
