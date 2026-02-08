class_name DeathState
extends State

func enter() -> void:
	if character:
		character.play_animation("death")
		character.velocity = Vector2.ZERO
		
		# Отключаем коллизии
		if character.collision_shape:
			character.collision_shape.disabled = true
		
		# Ждем окончания анимации
		await character.animation_player.animation_finished
		
		# Удаляем персонажа
		character.queue_free()

func exit() -> void:
	pass
