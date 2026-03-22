extends Area2D

## Универсальная зона: при входе игрока запускает диалог (не обязана совпадать с heal_area монаха).

@export var dialogue: DialogueSequence
@export var trigger_once: bool = true
@export var pause_game: bool = false

var _triggered: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	if dialogue == null or dialogue.lines.is_empty():
		return
	if trigger_once and _triggered:
		return
	if DialogueManager.is_active():
		return
	if DialogueManager.start_dialogue(dialogue, pause_game):
		_triggered = true
