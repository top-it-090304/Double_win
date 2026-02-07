class_name InputHandler
extends Node

func get_movement_vector() -> Vector2:
    var vector = Vector2.ZERO
    vector.x = Input.get_action_strength("right") - Input.get_action_strength("left")
    vector.y = Input.get_action_strength("down") - Input.get_action_strength("up")
    return vector.normalized()

func is_attack_pressed() -> bool:
    return Input.is_action_just_pressed("attack")

func is_interact_pressed() -> bool:
    return Input.is_action_just_pressed("interact")
