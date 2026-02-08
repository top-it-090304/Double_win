class_name HurtState
extends State

func enter() -> void:
	if character:
		character.play_animation("hurt")
		
		# Мигание при получении урона
		var tween = create_tween()
		tween.tween_property(character.sprite, "modulate:a", 0.5, 0.1)
		tween.tween_property(character.sprite, "modulate:a", 1.0, 0.1)
		tween.set_loops(3)
		
		await tween.finished
		
		# Возвращаемся в предыдущее состояние
		state_machine.transition_to("Idle")

func exit() -> void:
	if character:
		character.sprite.modulate.a = 1.0
