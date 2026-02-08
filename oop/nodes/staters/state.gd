class_name State
extends Node  # ⬅ State это компонент

var character: CharacterBase
var state_machine: StateMachine

func enter() -> void:
	pass

func exit() -> void:
	pass

func update(delta: float) -> void:
	pass

func physics_update(delta: float) -> void:
	pass

func handle_input(event: InputEvent) -> void:
	pass
