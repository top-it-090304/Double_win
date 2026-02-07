class_name AttackState
extends State

func enter() -> void:
    character.animation_player.play("attack")
    await character.animation_player.animation_finished
    character.state_machine.transition_to("Idle")
