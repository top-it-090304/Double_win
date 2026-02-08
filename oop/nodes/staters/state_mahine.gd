class_name StateMachine
extends Node  # ⬅ StateMachine это менеджер

var current_state: State
var states: Dictionary = {}
var character: CharacterBase

func initialize(character_node: CharacterBase) -> void:
	character = character_node
	
	# Регистрируем все состояния-дети
	for child in get_children():
		if child is State:
			states[child.name] = child
			child.character = character
			child.state_machine = self
	
	# Начинаем с Idle
	if states.has("Idle"):
		transition_to("Idle")

func transition_to(state_name: String) -> void:
	if not states.has(state_name):
		return
	
	# Выход из текущего состояния
	if current_state:
		current_state.exit()
	
	# Вход в новое состояние
	current_state = states[state_name]
	current_state.enter()
	
	# Обновление анимации
	if character and character.animation_player:
		character.animation_player.play(state_name.to_lower())

func update(delta: float) -> void:
	if current_state:
		current_state.update(delta)

func get_current_state_name() -> String:
	if current_state:
		return current_state.name
	return ""
