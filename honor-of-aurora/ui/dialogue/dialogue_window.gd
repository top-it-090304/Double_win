extends Control

const NAME_FONT_SIZE := 15
const NAME_FONT_COLOR := Color(1, 1, 1, 1)
const TEXT_FONT_SIZE := 40
const TEXT_FONT_COLOR := Color(1, 1, 1, 1)
const NAME_FONT_MIN := 8
const TEXT_FONT_MIN := 8
const TEXT_MEASURE_HEIGHT_TRIM := 2.0

const TEX_HEALER := preload("res://Asets/Unit_pack/UI Elements/UI Elements/Human Avatars/aa_healler.png")
const TEX_PLAYER := preload("res://Asets/Unit_pack/UI Elements/UI Elements/Human Avatars/aa_player.png")

const SPEAKER_LABELS := {
	"healer": "Целитель",
	"hero": "Рыцарь",
	"narrator": "Повествование",
	"letter": "Письмо",
}

const SPEAKER_FACES := {
	"healer": TEX_HEALER,
	"hero": TEX_PLAYER,
}

@onready var _face: TextureRect = $DialogueChrome/PanelRoot/MarginMain/VBox/Row/LeftCol/FaceFrame/face
@onready var _name_label: Label = $DialogueChrome/PanelRoot/MarginMain/VBox/Row/LeftCol/Name
@onready var _text_label: Label = $DialogueChrome/PanelRoot/MarginMain/VBox/Row/text
@onready var _choices_vbox: VBoxContainer = $DialogueChrome/PanelRoot/MarginMain/VBox/ChoicesVBox

var _text_pages: PackedStringArray = []
var _text_page_index: int = 0
var _choice_buttons: Array[Button] = []


func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process_input(true)
	if _face == null or _name_label == null or _text_label == null or _choices_vbox == null:
		push_error("DialogueWindow: не найдены узлы face / Name / text / ChoicesVBox под DialogueChrome — проверьте дерево сцены.")
	_apply_label_theme()
	DialogueManager.dialogue_started.connect(_on_dialogue_started)
	DialogueManager.line_changed.connect(_on_line_changed)
	DialogueManager.dialogue_ended.connect(_on_dialogue_ended)


func _apply_label_theme() -> void:
	if _name_label == null or _text_label == null:
		return
	_name_label.add_theme_font_size_override("font_size", NAME_FONT_SIZE)
	_name_label.add_theme_color_override("font_color", NAME_FONT_COLOR)
	_name_label.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	_name_label.clip_text = false
	_text_label.add_theme_font_size_override("font_size", TEXT_FONT_SIZE)
	_text_label.add_theme_color_override("font_color", TEXT_FONT_COLOR)
	_text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text_label.clip_text = true


func _input(event: InputEvent) -> void:
	if not visible or not DialogueManager.is_active():
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if DialogueManager.is_current_line_choice():
			var kc: int = event.keycode
			if kc >= KEY_1 and kc <= KEY_9:
				var idx: int = kc - KEY_1
				if idx < _choice_buttons.size():
					_choice_buttons[idx].pressed.emit()
					get_viewport().set_input_as_handled()
				return
		if event.keycode == KEY_SPACE or event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
			if DialogueManager.is_current_line_choice():
				if _text_pages.size() > 1 and _text_page_index + 1 < _text_pages.size():
					_advance_dialogue_or_page()
					get_viewport().set_input_as_handled()
				return
			_advance_dialogue_or_page()
			get_viewport().set_input_as_handled()


func _advance_dialogue_or_page() -> void:
	if DialogueManager.is_current_line_choice():
		if _text_pages.size() > 1 and _text_page_index + 1 < _text_pages.size():
			SoundManager.play_dialogue_page_turn()
			_text_page_index += 1
			_text_label.text = _text_pages[_text_page_index]
			_fit_dialogue_text_font()
		return
	if _text_pages.size() > 1 and _text_page_index + 1 < _text_pages.size():
		SoundManager.play_dialogue_page_turn()
		_text_page_index += 1
		_text_label.text = _text_pages[_text_page_index]
		_fit_dialogue_text_font()
		return
	SoundManager.play_dialogue_advance()
	DialogueManager.advance_line()


func _on_dialogue_started(_sequence: DialogueSequence) -> void:
	visible = true


func _on_line_changed(line: DialogueLine, _index: int, _line_count: int) -> void:
	_clear_choice_ui()
	var sid: String = line.speaker_id
	_name_label.text = SPEAKER_LABELS.get(sid, sid.capitalize() if not sid.is_empty() else "?")
	var tex: Texture2D = SPEAKER_FACES.get(sid, null)
	if tex:
		_face.texture = tex
		_face.visible = true
	else:
		_face.texture = null
		_face.visible = false

	if line is DialogueChoiceLine:
		var dcl := line as DialogueChoiceLine
		_choices_vbox.visible = true
		_text_pages = _build_text_pages(line.text)
		_text_page_index = 0
		_text_label.text = _text_pages[0] if not _text_pages.is_empty() else ""
		await get_tree().process_frame
		await get_tree().process_frame
		_fit_name_font()
		_fit_dialogue_text_font()
		for i in dcl.options.size():
			var opt: DialogueChoiceOption = dcl.options[i]
			var btn := Button.new()
			btn.text = "%d. %s" % [i + 1, opt.label]
			btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
			btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			var captured: int = i
			btn.pressed.connect(func() -> void:
				SoundManager.play_ui_button()
				_clear_choice_ui()
				DialogueManager.pick_dialogue_choice(captured)
			)
			_choices_vbox.add_child(btn)
			_choice_buttons.append(btn)
		return

	await get_tree().process_frame
	await get_tree().process_frame
	_fit_name_font()
	_text_pages = _build_text_pages(line.text)
	_text_page_index = 0
	_text_label.text = _text_pages[0] if not _text_pages.is_empty() else ""
	_fit_dialogue_text_font()


func _clear_choice_ui() -> void:
	_choice_buttons.clear()
	for c in _choices_vbox.get_children():
		c.queue_free()
	_choices_vbox.visible = false


func _on_dialogue_ended(_sequence: DialogueSequence) -> void:
	_clear_choice_ui()
	visible = false
	_text_label.text = ""
	_name_label.text = ""
	_face.texture = null
	_text_pages = []
	_text_page_index = 0


func _font_for_label(label: Label) -> Font:
	var f: Font = label.get_theme_font("font")
	return f if f != null else ThemeDB.fallback_font


func _text_max_width() -> float:
	return maxf(_text_label.size.x, 8.0)


func _text_max_height() -> float:
	return maxf(_text_label.size.y - TEXT_MEASURE_HEIGHT_TRIM, 1.0)


func _label_effective_size(label: Label) -> Vector2:
	var s: Vector2 = label.size
	return Vector2(maxf(s.x, 4.0), maxf(s.y, 4.0))


func _fit_font_to_label(label: Label, text: String, max_fs: int, min_fs: int) -> void:
	if label == null:
		return
	if text.is_empty():
		label.add_theme_font_size_override("font_size", max_fs)
		return
	var font: Font = _font_for_label(label)
	var dim: Vector2 = _label_effective_size(label)
	var max_w: float = maxf(dim.x, 4.0)
	var max_h: float = maxf(dim.y, float(min_fs))
	var chosen: int = min_fs
	var fs: int = max_fs
	while fs >= min_fs:
		var sz: Vector2 = font.get_multiline_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, max_w, fs, -1)
		if float(sz.y) <= max_h + 1.0:
			chosen = fs
			break
		fs -= 1
	label.add_theme_font_size_override("font_size", chosen)


func _fit_name_font() -> void:
	if _name_label == null:
		return
	_name_label.visible = true
	_name_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	_fit_font_to_label(_name_label, _name_label.text, NAME_FONT_SIZE, NAME_FONT_MIN)


func _fit_dialogue_text_font() -> void:
	if _text_label == null:
		return
	_fit_font_to_label(_text_label, _text_label.text, TEXT_FONT_SIZE, TEXT_FONT_MIN)


func _build_text_pages(full_text: String) -> PackedStringArray:
	var t: String = full_text.strip_edges().replace("\n", " ")
	while t.contains("  "):
		t = t.replace("  ", " ")
	if t.is_empty():
		return PackedStringArray([""])
	var font: Font = _font_for_label(_text_label)
	var max_w: float = maxf(_text_max_width(), 8.0)
	var max_h: float = maxf(_text_max_height(), float(TEXT_FONT_SIZE) * 1.5)
	var pages: Array[String] = []
	var rest: String = t
	while not rest.is_empty():
		var page: String = _take_text_page(rest, font, TEXT_FONT_SIZE, max_w, max_h)
		if page.is_empty():
			page = rest.substr(0, 1)
		pages.append(page)
		rest = rest.substr(page.length()).strip_edges()
	return PackedStringArray(pages)


func _text_block_height(text: String, font: Font, font_size: int, max_width: float) -> float:
	if text.is_empty():
		return 0.0
	var sz: Vector2 = font.get_multiline_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, max_width, font_size, -1)
	return float(sz.y)


func _take_text_page(rest: String, font: Font, font_size: int, max_width: float, max_height: float) -> String:
	rest = rest.strip_edges()
	if rest.is_empty():
		return ""
	if _text_block_height(rest, font, font_size, max_width) <= max_height:
		return rest
	var words: PackedStringArray = rest.split(" ", false)
	if words.is_empty():
		return _take_by_chars(rest, font, font_size, max_width, max_height)
	var acc: String = ""
	for i in words.size():
		var w: String = words[i]
		var candidate: String = w if acc.is_empty() else acc + " " + w
		if _text_block_height(candidate, font, font_size, max_width) > max_height:
			if not acc.is_empty():
				return acc
			return _take_by_chars(w, font, font_size, max_width, max_height)
		acc = candidate
	return acc


func _take_by_chars(rest: String, font: Font, font_size: int, max_width: float, max_height: float) -> String:
	if rest.is_empty():
		return ""
	var lo: int = 1
	var hi: int = rest.length()
	var best: String = ""
	while lo <= hi:
		var mid: int = (lo + hi) >> 1
		var sub: String = rest.substr(0, mid)
		if _text_block_height(sub, font, font_size, max_width) <= max_height:
			best = sub
			lo = mid + 1
		else:
			hi = mid - 1
	if best.is_empty():
		return rest.substr(0, 1)
	return best
