extends Area2D

## Зарегистрированный id (см. DialogueRegistry DEFINITION_PATHS и DialogueDefinition).
@export var dialogue_id: String = ""
## Устаревший вариант: прямой ресурс, если dialogue_id пустой.
@export var dialogue: DialogueSequence
@export var trigger_once: bool = true
@export var pause_game: bool = false

var _triggered: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if not GameplayFacade.is_player_body(body):
		return
	if not dialogue_id.is_empty():
		if trigger_once and _triggered:
			return
		if DialogueRegistry.try_start(dialogue_id, pause_game):
			if trigger_once:
				_triggered = true
		return
	if dialogue == null or dialogue.lines.is_empty():
		return
	if trigger_once and _triggered:
		return
	dialogue.ensure_lines_ready()
	if dialogue.lines.is_empty():
		return
	if DialogueManager.start_dialogue(dialogue, pause_game):
		_triggered = true
