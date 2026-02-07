class_name StateMachine
extends Node

var current_state: State
var states: Dictionary = {}
var character: CharacterBase

func initialize(character_node: CharacterBase) -> void:
    character = character_node
    for child in get_children():
        if child is State:
            states[child.name] = child
            child.character = character
            child.state_machine = self
    if states.has("Idle"):
        transition_to("Idle")

func transition_to(state_name: String) -> void:
    if not states.has(state_name):
        print("ОШИБКА: Состояние ", state_name, " не найдено!")
        return
    if current_state:
        current_state.exit()
    current_state = states[state_name]
    current_state.enter()

func _physics_process(delta: float) -> void:
    if current_state:
        current_state._physics_process(delta)

func _unhandled_input(event: InputEvent) -> void:
    if current_state:
        current_state._unhandled_input(event)
