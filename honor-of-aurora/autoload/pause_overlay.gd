extends CanvasLayer
## Простая пауза для мобильного HUD: затемнение экрана + 2 кнопки: «Продолжить» и
## «Главное меню». Открывается по тапу на иконку «назад» в верхнем HUD (см. HUD._on_button_pressed).
##
## Не используется во время диалогов и активных модалок (HUD сам не вызывает open()).

const _LAYER := 92
const _DIM_COLOR := Color(0.02, 0.03, 0.06, 0.78)
const _PANEL_BG := Color(0.06, 0.07, 0.1, 0.96)
const _PANEL_BORDER := Color(0.92, 0.78, 0.42, 0.55)
const _BTN_FONT_SIZE := 22
const _TITLE_FONT_SIZE := 28

var _root: Control
var _dim: ColorRect
var _panel: PanelContainer
var _resume_btn: Button
var _menu_btn: Button
var _was_paused_before: bool = false


func _ready() -> void:
	layer = _LAYER
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_build_ui()


func _build_ui() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_root)
	_dim = ColorRect.new()
	_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_dim.color = _DIM_COLOR
	_dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_dim.gui_input.connect(_on_dim_gui_input)
	_root.add_child(_dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(center)
	_panel = PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = _PANEL_BG
	sb.set_border_width_all(2)
	sb.border_color = _PANEL_BORDER
	sb.set_corner_radius_all(14)
	sb.content_margin_left = 28
	sb.content_margin_right = 28
	sb.content_margin_top = 22
	sb.content_margin_bottom = 22
	_panel.add_theme_stylebox_override("panel", sb)
	_panel.custom_minimum_size = Vector2(420, 0)
	center.add_child(_panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 16)
	_panel.add_child(v)
	var title := Label.new()
	title.text = "Пауза"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", _TITLE_FONT_SIZE)
	title.add_theme_color_override("font_color", Color(0.96, 0.94, 0.86))
	v.add_child(title)
	_resume_btn = Button.new()
	_resume_btn.text = "Продолжить"
	_resume_btn.focus_mode = Control.FOCUS_NONE
	_resume_btn.add_theme_font_size_override("font_size", _BTN_FONT_SIZE)
	_resume_btn.custom_minimum_size = Vector2(360, 56)
	_resume_btn.pressed.connect(close)
	v.add_child(_resume_btn)
	_menu_btn = Button.new()
	_menu_btn.text = "Главное меню"
	_menu_btn.focus_mode = Control.FOCUS_NONE
	_menu_btn.add_theme_font_size_override("font_size", _BTN_FONT_SIZE)
	_menu_btn.custom_minimum_size = Vector2(360, 56)
	_menu_btn.pressed.connect(_on_menu_pressed)
	v.add_child(_menu_btn)


func is_open() -> bool:
	return visible


func open() -> void:
	if visible:
		return
	if DialogueManager and DialogueManager.is_active():
		return
	_was_paused_before = get_tree().paused
	get_tree().paused = true
	if SoundManager and SoundManager.has_method("play_menu_open"):
		SoundManager.play_menu_open()
	visible = true


func close() -> void:
	if not visible:
		return
	visible = false
	if SoundManager and SoundManager.has_method("play_menu_close"):
		SoundManager.play_menu_close()
	## Возвращаем пред-паузное состояние: если до открытия пауза стояла из-за диалога/меню — оставляем её.
	get_tree().paused = _was_paused_before


func _on_menu_pressed() -> void:
	## Корректно: сначала снимаем нашу паузу, чтобы переход сцены не тормозил, и только потом меняем локацию.
	visible = false
	get_tree().paused = false
	if GameManager and GameManager.has_method("defer_location_changed"):
		GameManager.defer_location_changed(Events.LOCATION.MENU)


func _on_dim_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
		close()
	elif event is InputEventScreenTouch and (event as InputEventScreenTouch).pressed:
		close()


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()
