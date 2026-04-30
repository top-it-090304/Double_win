extends CanvasLayer
## Лёгкое всплывающее сообщение-подсказка поверх HUD: одна строка/абзац, без кнопок.
## Не блокирует ввод и не ставит игру на паузу. Используется для:
##   - адаптивных подсказок после повторных смертей (см. GameManager.notify_player_death_at_current_location);
##   - контекстных подсказок онбординга (см. EasyHints).
## API: show_tip(text, duration_sec=5.0); show_tip_once(key, text, duration_sec=5.0).

const _LAYER := 95
const _FADE_IN_SEC := 0.25
const _FADE_OUT_SEC := 0.4
const _DEFAULT_DURATION_SEC := 5.0
const _MIN_DURATION_SEC := 2.0
const _MAX_DURATION_SEC := 14.0
const _MAX_WIDTH_PX := 720.0

var _root: Control
var _panel: PanelContainer
var _label: Label
var _hide_timer: Timer
var _tween: Tween
var _shown_keys: Dictionary = {}


func _ready() -> void:
	layer = _LAYER
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	_root.visible = false
	_root.modulate.a = 0.0
	_hide_timer = Timer.new()
	_hide_timer.one_shot = true
	_hide_timer.timeout.connect(_on_hide_timer_timeout)
	add_child(_hide_timer)


func _build_ui() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)
	var anchor := Control.new()
	anchor.anchor_left = 0.5
	anchor.anchor_right = 0.5
	anchor.anchor_top = 0.0
	anchor.anchor_bottom = 0.0
	anchor.offset_left = -_MAX_WIDTH_PX * 0.5
	anchor.offset_right = _MAX_WIDTH_PX * 0.5
	anchor.offset_top = 96.0
	anchor.offset_bottom = 96.0
	anchor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(anchor)
	_panel = PanelContainer.new()
	_panel.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.06, 0.07, 0.1, 0.94)
	sb.set_border_width_all(1)
	sb.border_color = Color(0.92, 0.78, 0.42, 0.7)
	sb.set_corner_radius_all(10)
	sb.content_margin_left = 16
	sb.content_margin_right = 16
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10
	_panel.add_theme_stylebox_override("panel", sb)
	anchor.add_child(_panel)
	_label = Label.new()
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", 20)
	_label.add_theme_color_override("font_color", Color(0.96, 0.94, 0.86))
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(_label)


func show_tip(text: String, duration_sec: float = _DEFAULT_DURATION_SEC) -> void:
	if text.is_empty():
		return
	_label.text = text
	var d := clampf(duration_sec, _MIN_DURATION_SEC, _MAX_DURATION_SEC)
	_root.visible = true
	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(_root, "modulate:a", 1.0, _FADE_IN_SEC)
	_hide_timer.stop()
	_hide_timer.start(d)


## Показать подсказку только один раз за сессию (по ключу). Полезно для контекстного онбординга.
func show_tip_once(key: String, text: String, duration_sec: float = _DEFAULT_DURATION_SEC) -> bool:
	if key.is_empty():
		show_tip(text, duration_sec)
		return true
	if _shown_keys.has(key):
		return false
	_shown_keys[key] = true
	show_tip(text, duration_sec)
	return true


## Сброс ключей "уже показанных" подсказок (например, при «Новой игре»).
func reset_shown_keys() -> void:
	_shown_keys.clear()


func hide_tip() -> void:
	_hide_timer.stop()
	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(_root, "modulate:a", 0.0, _FADE_OUT_SEC)
	_tween.tween_callback(func() -> void:
		_root.visible = false
	)


func _on_hide_timer_timeout() -> void:
	hide_tip()
