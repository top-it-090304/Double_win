extends "res://characters/character_unit.gd"
## Союзник-НПС: группа ally.

func squad_rally_after_reposition() -> void:
	pass


## Как у героя и монаха: слой EffectSprite с анимацией «heal_effect» (если есть в сцене).
func play_heal_effect() -> void:
	var fx: AnimatedSprite2D = get_node_or_null("EffectSprite") as AnimatedSprite2D
	if fx == null or fx.sprite_frames == null:
		return
	if not fx.sprite_frames.has_animation("heal_effect"):
		return
	fx.visible = true
	var main_sprite := get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if main_sprite:
		fx.flip_h = main_sprite.flip_h
	fx.play("heal_effect")
	await fx.animation_finished
	fx.visible = false


func _ready() -> void:
	super._ready()
	add_to_group("ally")
