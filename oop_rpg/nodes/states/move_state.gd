class_name MoveState
extends State

func enter() -> void:
    character.animation_player.play("walk")
