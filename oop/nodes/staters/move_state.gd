class_name MoveState
extends State

func enter() -> void:
	if character:
		character.play_animation("walk")

func update(delta: float) -> void:
	# Движение обрабатывается в CharacterBase
	pass

func physics_update(delta: float) -> void:
	pass

func exit() -> void:
	pass
