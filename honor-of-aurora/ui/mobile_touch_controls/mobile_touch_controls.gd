extends Control

## Сенсорный HUD: джойстик слева, атака и щит справа. Скрывается при паузе и диалоге.
## Родитель — CanvasLayer HUD; этот узел — Control на весь экран (без вложенного CanvasLayer).

@export var force_show_in_editor: bool = false

func _ready() -> void:
	add_to_group("touch_controls")
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	_ensure_full_rect()
	_connect_touch_zone_resize_signals()
	call_deferred("apply_user_touch_settings")
	if not get_viewport().size_changed.is_connected(_on_viewport_size_changed):
		get_viewport().size_changed.connect(_on_viewport_size_changed)
	DialogueManager.dialogue_started.connect(_on_dialogue_started_visibility)
	DialogueManager.dialogue_ended.connect(_on_dialogue_ended_visibility)
	_refresh_visibility()


func _connect_touch_zone_resize_signals() -> void:
	var root := get_node_or_null("Root") as Control
	if root == null:
		return
	var vj := root.get_node_or_null("VirtualJoystick") as Control
	var rc := root.get_node_or_null("RightCluster") as Control
	if vj:
		vj.resized.connect(_on_touch_zone_resized.bind(vj, true))
	if rc:
		rc.resized.connect(_on_touch_zone_resized.bind(rc, false))


func _on_touch_zone_resized(zone: Control, is_left: bool) -> void:
	_apply_scaled_touch_zone(zone, is_left)


func _on_viewport_size_changed() -> void:
	_ensure_full_rect()
	call_deferred("apply_user_touch_settings")


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
	if show:
		var rally_btn := get_node_or_null("Root/RightCluster/RallyButton") as Control
		if rally_btn:
			rally_btn.visible = Events.current_location != Events.LOCATION.MENU


func _apply_scaled_touch_zone(zone: Control, is_left: bool) -> void:
	if zone == null:
		return
	var s := float(SaveManager.touch_scale_percent) / 100.0
	if zone.size.x < 1.0 or zone.size.y < 1.0:
		return
	# Масштаб от нижнего угла у края экрана — элементы не «уплывают» при смене размера.
	if is_left:
		zone.pivot_offset = Vector2(0.0, zone.size.y)
	else:
		zone.pivot_offset = Vector2(zone.size.x, zone.size.y)
	zone.scale = Vector2(s, s)


func apply_user_touch_settings() -> void:
	var root := get_node_or_null("Root") as Control
	if root == null:
		return
	root.scale = Vector2.ONE
	root.modulate.a = float(SaveManager.touch_opacity_percent) / 100.0
	var vj := root.get_node_or_null("VirtualJoystick") as Control
	var rc := root.get_node_or_null("RightCluster") as Control
	if vj:
		_apply_scaled_touch_zone(vj, true)
	if rc:
		_apply_scaled_touch_zone(rc, false)


func _should_show_touch_ui() -> bool:
	match SaveManager.touch_mode:
		1:
			return true
		2:
			return false
		_:
			pass
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
