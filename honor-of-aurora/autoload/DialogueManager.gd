extends Node

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


func is_current_line_choice() -> bool:
	var line := get_current_line()
	return line is DialogueChoiceLine and (line as DialogueChoiceLine).options.size() > 0


## Выбор варианта при DialogueChoiceLine (индекс с 0).
func pick_dialogue_choice(option_index: int) -> void:
	if not is_active():
		return
	var line: DialogueLine = get_current_line()
	if not line is DialogueChoiceLine:
		return
	var dcl := line as DialogueChoiceLine
	if option_index < 0 or option_index >= dcl.options.size():
		return
	var opt: DialogueChoiceOption = dcl.options[option_index]
	for k in opt.grant_flags:
		if not k.is_empty():
			StoryState.set_flag(k, true)
	_sequence.lines.remove_at(_index)
	for i in range(opt.continuation.size()):
		_sequence.lines.insert(_index + i, opt.continuation[i])
	_emit_current_line()


func _emit_current_line() -> void:
	var line: DialogueLine = _sequence.lines[_index]
	line_changed.emit(line, _index, _sequence.lines.size())
	# Сразу из менеджера: при паузе игры await в окне диалога может не давать дойти до конца обработчика.
	SoundManager.play_dialogue_mumble(line.speaker_id)
