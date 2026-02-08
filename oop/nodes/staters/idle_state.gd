class_name IdleState
extends State

func enter() -> void:
	if character:
		character.velocity = Vector2.ZERO
		character.play_animation("idle")

func update(delta: float) -> void:
	# Логика состояния покоя
	pass

func exit() -> void:
	pass
