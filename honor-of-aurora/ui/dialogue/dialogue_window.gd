extends Control

## UI окна диалога: face, Name, text. Листание: Space / Enter.

const TEX_HEALER := preload("res://Asets/Unit_pack/UI Elements/UI Elements/Human Avatars/aa_healler.png")
const TEX_PLAYER := preload("res://Asets/Unit_pack/UI Elements/UI Elements/Human Avatars/aa_player.png")

const SPEAKER_LABELS := {
	"healer": "Целитель",
	"hero": "Рыцарь",
	"narrator": "Повествование",
}

const SPEAKER_FACES := {
	"healer": TEX_HEALER,
	"hero": TEX_PLAYER,
}

@onready var _face: TextureRect = $background/TileMapLayer/face
@onready var _name_label: Label = $"background/TileMapLayer/Name"
@onready var _text_label: Label = $background/text


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
	_name_label.text = SPEAKER_LABELS.get(sid, sid.capitalize() if not sid.is_empty() else "?")
	_text_label.text = line.text
	var tex: Texture2D = SPEAKER_FACES.get(sid, null)
	if tex:
		_face.texture = tex
		_face.visible = true
	else:
		_face.texture = null
		_face.visible = false


func _on_dialogue_ended(_sequence: DialogueSequence) -> void:
	visible = false
	_text_label.text = ""
	_name_label.text = ""
	_face.texture = null
