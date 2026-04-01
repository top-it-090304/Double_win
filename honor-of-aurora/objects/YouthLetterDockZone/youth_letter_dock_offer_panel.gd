extends Control
## Модальное окно у причала (стиль как замковое меню / pay_shop).
## Шрифт — как у реплик в dialogue_window: ThemeDB.fallback_font (см. dialogue_window.gd _font_for_label).

signal offer_confirmed
signal offer_canceled

@onready var _title: Label = %TitleLabel
@onready var _body: Label = %BodyLabel
@onready var _confirm: Button = %ConfirmButton
@onready var _cancel: Button = %CancelButton


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_STOP
	var f: Font = ThemeDB.fallback_font
	for n: Control in [_title, _body, _confirm, _cancel]:
		if n != null:
			n.add_theme_font_override("font", f)
	if _confirm:
		_confirm.pressed.connect(_on_confirm)
	if _cancel:
		_cancel.pressed.connect(_on_cancel)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_on_cancel()


func setup(title_text: String, body_text: String, confirm_text: String, cancel_text: String) -> void:
	if _title:
		_title.text = title_text
	if _body:
		_body.text = body_text
	if _confirm:
		_confirm.text = confirm_text
	if _cancel:
		_cancel.text = cancel_text


func _on_confirm() -> void:
	offer_confirmed.emit()
	queue_free()


func _on_cancel() -> void:
	offer_canceled.emit()
	queue_free()
