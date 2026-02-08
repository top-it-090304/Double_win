class_name InputHandler
extends Node

func get_movement_input() -> Vector2:
	var input = Vector2.ZERO
	
	# Используем Input Actions (нужно создать в Project Settings)
	input.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	input.y = Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	
	return input.normalized()

func is_attack_pressed() -> bool:
	return Input.is_action_just_pressed("attack")

func is_interact_pressed() -> bool:
	return Input.is_action_just_pressed("interact")

func is_jump_pressed() -> bool:
	return Input.is_action_just_pressed("jump")

func is_sprint_pressed() -> bool:
	return Input.is_action_pressed("sprint")

func get_mouse_position() -> Vector2:
	return get_viewport().get_mouse_position()
