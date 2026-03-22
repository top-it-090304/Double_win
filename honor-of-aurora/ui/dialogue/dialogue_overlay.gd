extends Control

## Минимальное окно диалога: подпись к DialogueManager (сигналы line_changed и т.д.).

const SPEAKER_LABELS := {
	"healer": "Целитель",
	"hero": "Рыцарь",
	"narrator": "Повествование",
}

@onready var _speaker: Label = $Panel/MarginContainer/VBox/SpeakerName
@onready var _body: Label = $Panel/MarginContainer/VBox/DialogueBody


func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process_input(true)
	DialogueManager.dialogue_started.connect(_on_dialogue_started)
	DialogueManager.line_changed.connect(_on_line_changed)
	DialogueManager.dialogue_ended.connect(_on_dialogue_ended)


func _input(event: InputEvent) -> void:
	if not visible or not DialogueManager.is_active():
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_SPACE or event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
			DialogueManager.advance_line()
			get_viewport().set_input_as_handled()


func _on_dialogue_started(_sequence: DialogueSequence) -> void:
	visible = true


func _on_line_changed(line: DialogueLine, _index: int, _line_count: int) -> void:
	var sid: String = line.speaker_id
	_speaker.text = SPEAKER_LABELS.get(sid, sid.capitalize() if not sid.is_empty() else "?")
	_body.text = line.text


func _on_dialogue_ended(_sequence: DialogueSequence) -> void:
	visible = false
	_body.text = ""
	_speaker.text = ""
