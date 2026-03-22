extends Control

## Сенсорный HUD: джойстик слева, атака и щит справа. Скрывается при паузе и диалоге.
## Родитель — CanvasLayer HUD; этот узел — Control на весь экран (без вложенного CanvasLayer).

@export var force_show_in_editor: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	_ensure_full_rect()
	if not get_viewport().size_changed.is_connected(_on_viewport_size_changed):
		get_viewport().size_changed.connect(_on_viewport_size_changed)
	DialogueManager.dialogue_started.connect(_on_dialogue_started_visibility)
	DialogueManager.dialogue_ended.connect(_on_dialogue_ended_visibility)
	_refresh_visibility()


func _on_viewport_size_changed() -> void:
	_ensure_full_rect()


func _ensure_full_rect() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	offset_left = 0.0
	offset_top = 0.0
	offset_right = 0.0
	offset_bottom = 0.0


func _on_dialogue_started_visibility(_a = null) -> void:
	_refresh_visibility()


func _on_dialogue_ended_visibility(_a = null) -> void:
	MobileVirtualInput.clear_input()
	_refresh_visibility()


func _process(_delta: float) -> void:
	_refresh_visibility()


func _refresh_visibility() -> void:
	if not is_inside_tree():
		return
	var want := _should_show_touch_ui()
	var blocked := get_tree().paused or DialogueManager.is_active()
	var show := want and not blocked
	visible = show
	MobileVirtualInput.set_controls_visible(show)


func _should_show_touch_ui() -> bool:
	if force_show_in_editor:
		return true
	var osn := OS.get_name()
	if osn == "Android" or osn == "iOS":
		return true
	if DisplayServer.is_touchscreen_available():
		return true
	if OS.has_feature("android") or OS.has_feature("ios"):
		return true
	return false
