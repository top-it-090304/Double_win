extends Control

const NAME_FONT_MIN := 8
const TEXT_FONT_MIN := 8
const TEXT_MEASURE_HEIGHT_TRIM := 2.0
## После открытия диалога тем же кликом, что был «атакой», UI успевает нажать первую кнопку — кратко игнорируем мышь.
const CHOICE_MOUSE_ARM_DELAY_SEC := 0.12
## Минимальная высота строки варианта (компактнее — больше пунктов в видимой области скролла).
const CHOICE_BUTTON_MIN_HEIGHT := 32
## Высота полосы диалога: якорь снизу, offset_top отрицательный — чем меньше, тем выше панель.
const CHROME_OFFSET_TOP_MIN := -180.0
const CHROME_OFFSET_TOP_MAX := -320.0
const CHROME_OFFSET_BOTTOM := -16.0
## Сколько пикселей к росту панели даёт один вариант ответа, пока не достигнут CHROME_OFFSET_TOP_MAX.
const CHROME_EXTRA_PX_PER_CHOICE := 28.0

const TEX_HEALER := preload("res://Asets/Unit_pack/UI Elements/UI Elements/Human Avatars/aa_healler.png")
const TEX_PLAYER := preload("res://Asets/Unit_pack/UI Elements/UI Elements/Human Avatars/aa_player.png")
## Тот же аватар, что у рабочего в меню отряда (squad_orders_menu TEX_PAWN).
const TEX_WORKER := preload("res://Asets/Unit_pack/UI Elements/UI Elements/Human Avatars/Avatars_05.png")
const TEX_VETERAN := preload("res://Asets/Unit_pack/UI Elements/UI Elements/Human Avatars/Avatars_08.png")

const SPEAKER_LABELS := {
	"healer": "Целитель",
	"hero": "Рыцарь",
	"young_worker": "Юноша",
	"narrator": "Повествование",
	"letter": "Письмо",
	"veteran": "Бран",
}

const SPEAKER_FACES := {
	"healer": TEX_HEALER,
	"hero": TEX_PLAYER,
	"young_worker": TEX_WORKER,
	"veteran": TEX_VETERAN,
}

@onready var _dialogue_chrome: Control = $DialogueChrome
@onready var _face: TextureRect = $DialogueChrome/PanelRoot/MarginMain/VBox/ContentVBox/Row/LeftCol/FaceFrame/face
@onready var _name_label: Label = $DialogueChrome/PanelRoot/MarginMain/VBox/ContentVBox/Row/LeftCol/Name
@onready var _text_label: Label = $DialogueChrome/PanelRoot/MarginMain/VBox/ContentVBox/Row/text
@onready var _close_btn: Button = $DialogueChrome/PanelRoot/MarginMain/VBox/ContinueHBox/CloseButton
@onready var _continue_btn: Button = $DialogueChrome/PanelRoot/MarginMain/VBox/ContinueHBox/ContinueButton
@onready var _choices_scroll: ScrollContainer = $DialogueChrome/PanelRoot/MarginMain/VBox/ContentVBox/ChoicesScroll
@onready var _choices_vbox: VBoxContainer = $DialogueChrome/PanelRoot/MarginMain/VBox/ContentVBox/ChoicesScroll/ScrollPad/ChoicesVBox

var _text_pages: PackedStringArray = []
var _text_page_index: int = 0
var _choice_buttons: Array[Button] = []
## Касание, начатое в области списка вариантов (при emulate_mouse_from_touch=false дочерние Button не отдают drag в ScrollContainer).
var _choice_scroll_touch_index: int = -1


func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process_input(true)
	if _continue_btn:
		_continue_btn.pressed.connect(_on_continue_pressed)
	if _close_btn:
		_close_btn.pressed.connect(_force_close_dialogue)
	if _face == null or _name_label == null or _text_label == null or _choices_scroll == null or _choices_vbox == null:
		push_error("DialogueWindow: не найдены узлы face / Name / text / ChoicesScroll / ChoicesVBox под ContentVBox — проверьте дерево сцены.")
	if _choices_scroll:
		_choices_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		_choices_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_apply_label_theme()
	_apply_dialogue_chrome_height(0)
	DialogueManager.dialogue_started.connect(_on_dialogue_started)
	DialogueManager.line_changed.connect(_on_line_changed)
	DialogueManager.dialogue_ended.connect(_on_dialogue_ended)


func _apply_label_theme() -> void:
	if _name_label == null or _text_label == null:
		return
	_name_label.add_theme_font_size_override("font_size", DialogueUiConstants.NAME_FONT_SIZE)
	_name_label.add_theme_color_override("font_color", DialogueUiConstants.NAME_FONT_COLOR)
	_name_label.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	_name_label.clip_text = false
	_text_label.add_theme_font_size_override("font_size", DialogueUiConstants.TEXT_FONT_SIZE)
	_text_label.add_theme_color_override("font_color", DialogueUiConstants.TEXT_FONT_COLOR)
	_text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text_label.clip_text = true
	## Колонка текста растягивается по высоте блока с портретом; без центрирования короткие реплики «липнут» к верху.
	_text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_text_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER


func _apply_dialogue_chrome_height(choice_count: int) -> void:
	if _dialogue_chrome == null:
		return
	var span: float = absf(CHROME_OFFSET_TOP_MAX - CHROME_OFFSET_TOP_MIN)
	var extra: float = 0.0
	if choice_count > 0:
		extra = minf(span, float(choice_count) * CHROME_EXTRA_PX_PER_CHOICE)
	_dialogue_chrome.offset_top = CHROME_OFFSET_TOP_MIN - extra
	_dialogue_chrome.offset_bottom = CHROME_OFFSET_BOTTOM


func _input(event: InputEvent) -> void:
	if not visible or not DialogueManager.is_active():
		return
	if event.is_action_pressed("ui_cancel"):
		_force_close_dialogue()
		get_viewport().set_input_as_handled()
		return
	if event is InputEventScreenDrag:
		if DialogueManager.is_current_line_choice() and _choices_scroll and _choices_scroll.visible:
			var sd := event as InputEventScreenDrag
			if sd.index == _choice_scroll_touch_index and _choice_scroll_touch_index >= 0:
				_choices_scroll.scroll_vertical -= int(sd.relative.y)
				get_viewport().set_input_as_handled()
		return
	if event is InputEventScreenTouch:
		if DialogueManager.is_current_line_choice() and _choices_scroll and _choices_scroll.visible:
			var st := event as InputEventScreenTouch
			if st.pressed:
				if _choices_scroll.get_global_rect().has_point(st.position):
					_choice_scroll_touch_index = st.index
				else:
					_choice_scroll_touch_index = -1
			else:
				if st.index == _choice_scroll_touch_index:
					_choice_scroll_touch_index = -1
		return


func _gui_input(event: InputEvent) -> void:
	if not visible or not DialogueManager.is_active():
		return
	if not _continue_btn.visible:
		return
	if event is InputEventScreenTouch:
		var st := event as InputEventScreenTouch
		if st.pressed:
			_advance_dialogue_or_page()
			accept_event()


func _on_continue_pressed() -> void:
	_advance_dialogue_or_page()


func _force_close_dialogue() -> void:
	if not DialogueManager.is_active():
		return
	SoundManager.play_ui_button()
	DialogueManager.end_dialogue()


func _refresh_continue_button() -> void:
	if _continue_btn == null:
		return
	if not DialogueManager.is_active():
		_continue_btn.visible = false
		if _close_btn:
			_close_btn.visible = false
		return
	if _close_btn:
		_close_btn.visible = true
	if DialogueManager.is_current_line_choice():
		if _text_pages.size() > 1 and _text_page_index < _text_pages.size() - 1:
			_continue_btn.visible = true
		else:
			_continue_btn.visible = false
	else:
		_continue_btn.visible = true


func _advance_dialogue_or_page() -> void:
	if DialogueManager.is_current_line_choice():
		if _text_pages.size() > 1 and _text_page_index + 1 < _text_pages.size():
			SoundManager.play_dialogue_page_turn()
			_text_page_index += 1
			_text_label.text = _text_pages[_text_page_index]
			_fit_dialogue_text_font()
			_refresh_continue_button()
		return
	if _text_pages.size() > 1 and _text_page_index + 1 < _text_pages.size():
		SoundManager.play_dialogue_page_turn()
		_text_page_index += 1
		_text_label.text = _text_pages[_text_page_index]
		_fit_dialogue_text_font()
		_refresh_continue_button()
		return
	SoundManager.play_dialogue_advance()
	DialogueManager.advance_line()


func _on_dialogue_started(_sequence: DialogueSequence) -> void:
	visible = true
	MobileVirtualInput.clear_input()


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
		_apply_dialogue_chrome_height(dcl.options.size())
		_choices_scroll.visible = true
		_choices_scroll.scroll_vertical = 0
		await get_tree().process_frame
		await get_tree().process_frame
		_text_pages = _build_text_pages(line.text)
		_text_page_index = 0
		_text_label.text = _text_pages[0] if not _text_pages.is_empty() else ""
		_fit_name_font()
		_fit_dialogue_text_font()
		for i in dcl.options.size():
			var opt: DialogueChoiceOption = dcl.options[i]
			var btn := Button.new()
			btn.text = "%d. %s" % [i + 1, opt.label]
			btn.custom_minimum_size = Vector2(0, CHOICE_BUTTON_MIN_HEIGHT)
			btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
			btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			btn.mouse_filter = Control.MOUSE_FILTER_IGNORE
			var captured: int = i
			btn.pressed.connect(func() -> void:
				SoundManager.play_ui_button()
				_clear_choice_ui()
				DialogueManager.pick_dialogue_choice(captured)
			)
			_choices_vbox.add_child(btn)
			_choice_buttons.append(btn)
		_refresh_continue_button()
		## process_always: таймер срабатывает даже при паузе дерева (диалог с pause_game).
		await get_tree().create_timer(CHOICE_MOUSE_ARM_DELAY_SEC, true, false, true).timeout
		for b in _choice_buttons:
			if is_instance_valid(b):
				b.mouse_filter = Control.MOUSE_FILTER_STOP
		return

	_apply_dialogue_chrome_height(0)
	await get_tree().process_frame
	await get_tree().process_frame
	_fit_name_font()
	_text_pages = _build_text_pages(line.text)
	_text_page_index = 0
	_text_label.text = _text_pages[0] if not _text_pages.is_empty() else ""
	_fit_dialogue_text_font()
	_refresh_continue_button()


func _clear_choice_ui() -> void:
	_choice_buttons.clear()
	_choice_scroll_touch_index = -1
	for c in _choices_vbox.get_children():
		c.queue_free()
	if _choices_scroll:
		_choices_scroll.visible = false
		_choices_scroll.scroll_vertical = 0


func _on_dialogue_ended(_sequence: DialogueSequence) -> void:
	_clear_choice_ui()
	_apply_dialogue_chrome_height(0)
	visible = false
	_text_label.text = ""
	_name_label.text = ""
	_face.texture = null
	_text_pages = []
	_text_page_index = 0
	_refresh_continue_button()


func _font_for_label(label: Label) -> Font:
	var f: Font = label.get_theme_font("font")
	return f if f != null else ThemeDB.fallback_font


func _text_max_width() -> float:
	## После выбора варианта лейбл один кадр может иметь нулевую ширину — пагинация тогда режет текст по одному слову на «страницу».
	var w: float = _text_label.size.x
	if w < 48.0:
		var row: Control = _text_label.get_parent() as Control
		if row:
			w = row.size.x
	if w < 48.0:
		var vp: Viewport = get_viewport()
		if vp:
			w = vp.get_visible_rect().size.x * 0.5
	return maxf(w, 240.0)


func _text_max_height() -> float:
	var h: float = _text_label.size.y - TEXT_MEASURE_HEIGHT_TRIM
	if h < 32.0:
		var vp: Viewport = get_viewport()
		if vp:
			h = vp.get_visible_rect().size.y * 0.11
	return maxf(h, float(DialogueUiConstants.TEXT_FONT_SIZE) * 1.6)


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
	_fit_font_to_label(_name_label, _name_label.text, DialogueUiConstants.NAME_FONT_SIZE, NAME_FONT_MIN)


func _fit_dialogue_text_font() -> void:
	if _text_label == null:
		return
	_fit_font_to_label(_text_label, _text_label.text, DialogueUiConstants.TEXT_FONT_SIZE, TEXT_FONT_MIN)


func _build_text_pages(full_text: String) -> PackedStringArray:
	var t: String = full_text.strip_edges().replace("\n", " ")
	while t.contains("  "):
		t = t.replace("  ", " ")
	if t.is_empty():
		return PackedStringArray([""])
	var font: Font = _font_for_label(_text_label)
	var max_w: float = maxf(_text_max_width(), 8.0)
	var max_h: float = maxf(_text_max_height(), float(DialogueUiConstants.TEXT_FONT_SIZE) * 1.5)
	var pages: Array[String] = []
	var rest: String = t
	while not rest.is_empty():
		var page: String = _take_text_page(rest, font, DialogueUiConstants.TEXT_FONT_SIZE, max_w, max_h)
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
