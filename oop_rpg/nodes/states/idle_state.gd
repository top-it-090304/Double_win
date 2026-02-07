class_name IdleState
extends State

func enter() -> void:
    character.animation_player.play("idle")
    character.velocity = Vector2.ZERO
