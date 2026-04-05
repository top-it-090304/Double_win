extends Node
## Сцена предпросмотра: диалог прибытия каравана (фон + `dialogue_window`). Запуск — F6 при открытой сцене.

const _CARAVAN_ARRIVAL_SEQ: DialogueSequence = preload("res://dialogue/caravan_arrival.tres")


func _ready() -> void:
	DialogueManager.start_dialogue(_CARAVAN_ARRIVAL_SEQ, false)
