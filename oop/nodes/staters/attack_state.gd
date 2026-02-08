class_name AttackState
extends State

func enter() -> void:
	if character:
		character.play_animation("attack")
		character.attack_started.emit()
		
		# Ждем окончания анимации
		await character.animation_player.animation_finished
		
		# Возвращаемся в Idle
		state_machine.transition_to("Idle")
		character.attack_finished.emit()

func exit() -> void:
	pass
