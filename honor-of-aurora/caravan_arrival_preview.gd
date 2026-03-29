extends Node
## Превью диалога прибытия каравана. F6 на этой сцене в редакторе Godot.

func _ready() -> void:
	SaveManager.caravan_sent_count = 0
	SaveManager.crown_order_index = 1
	SaveManager.crown_displeasure = 0
	call_deferred("_play_caravan_arrival_dialogue")


func _play_caravan_arrival_dialogue() -> void:
	var seq := load("res://dialogue/caravan_arrival.tres") as DialogueSequence
	if seq == null:
		push_error("caravan_arrival_preview: не удалось load(res://dialogue/caravan_arrival.tres)")
		return
	if not DialogueManager.start_dialogue(seq, false):
		push_error("caravan_arrival_preview: DialogueManager.start_dialogue вернул false")
