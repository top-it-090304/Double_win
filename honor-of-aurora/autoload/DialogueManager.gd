extends Node

## Синглтон: очередь реплик, сигналы для UI.
## Кнопка «Далее» должна вызывать advance_line(). После последней реплики advance_line() сам вызовет end_dialogue().
##
## Важно: если pause_game=true, но нет UI с PROCESS_MODE_ALWAYS и кнопкой «Далее», игра зависнет в вечной паузе,
## потому что end_dialogue() вызывается только после advance_line(). По умолчанию пауза выключена.
## Листание клавишами: ui/dialogue/dialogue_window.gd (HUD).

signal dialogue_started(sequence: DialogueSequence)
signal line_changed(line: DialogueLine, index: int, line_count: int)
signal dialogue_ended(sequence: DialogueSequence)

var _sequence: DialogueSequence = null
var _index: int = 0
var _pause_locked: bool = false
var _paused_snapshot: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_INHERIT


func is_active() -> bool:
	return _sequence != null


func start_dialogue(sequence: DialogueSequence, pause_game: bool = false) -> bool:
	if sequence == null:
		return false
	sequence.ensure_lines_ready()
	if sequence.lines.is_empty():
		return false
	if is_active():
		return false
	_sequence = sequence
	_index = 0
	if pause_game:
		_paused_snapshot = get_tree().paused
		get_tree().paused = true
		_pause_locked = true
	process_mode = Node.PROCESS_MODE_ALWAYS
	dialogue_started.emit(_sequence)
	_emit_current_line()
	return true


func advance_line() -> void:
	if not is_active():
		return
	_index += 1
	if _index >= _sequence.lines.size():
		end_dialogue()
	else:
		_emit_current_line()


func end_dialogue() -> void:
	if not is_active():
		return
	var finished: DialogueSequence = _sequence
	_sequence = null
	_index = 0
	if _pause_locked:
		get_tree().paused = _paused_snapshot
		_pause_locked = false
	process_mode = Node.PROCESS_MODE_INHERIT
	dialogue_ended.emit(finished)


func get_current_line() -> DialogueLine:
	if not is_active():
		return null
	return _sequence.lines[_index]


func _emit_current_line() -> void:
	var line: DialogueLine = _sequence.lines[_index]
	line_changed.emit(line, _index, _sequence.lines.size())
