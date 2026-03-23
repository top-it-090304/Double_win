extends CharacterBody2D

## Чёрная пешка: все клипы из `black_pawn_frames.tres` (полосы 192×192).
## idle, run; idle_axe … idle_wood; run_axe … run_wood; interact_axe, interact_hammer, interact_knife, interact_pickaxe.
@export var speed: float = 120.0


func _ready() -> void:
	play_unit_animation(&"idle")


func play_unit_animation(anim: StringName) -> void:
	var sprite := _sprite()
	if sprite:
		sprite.play(anim)


func _sprite() -> AnimatedSprite2D:
	return get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
