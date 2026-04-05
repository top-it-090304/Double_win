extends Control

## Сенсорный HUD: джойстик слева, атака и щит справа. Скрывается при паузе и диалоге.
## Родитель — CanvasLayer HUD; этот узел — Control на весь экран (без вложенного CanvasLayer).

@export var force_show_in_editor: bool = false

## Исходные offset’ы RestCampButton из сцены (сохраняем до любых сдвигов).
var _rest_offset_base: Vector4 = Vector4.ZERO
var _rest_offsets_cached: bool = false

## «На тапке»: видимость тач-HUD не критична каждый кадр — реже вызываем _refresh_visibility (TASK-009).
var _slipper_refresh_tick: int = 0
const _SLIPPER_TOUCH_REFRESH_EVERY_FRAMES: int = 3

func _ready() -> void:
	add_to_group("touch_controls")
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	_ensure_full_rect()
	_connect_touch_zone_resize_signals()
	call_deferred("apply_user_touch_settings")
	var vp := get_viewport()
	if vp and not vp.size_changed.is_connected(_on_viewport_size_changed):
		vp.size_changed.connect(_on_viewport_size_changed)
	DialogueManager.dialogue_started.connect(_on_dialogue_started_visibility)
	DialogueManager.dialogue_ended.connect(_on_dialogue_ended_visibility)
	if not Events.location_changed.is_connected(_on_location_changed_touch_visibility):
		Events.location_changed.connect(_on_location_changed_touch_visibility)
	_refresh_visibility()


func _exit_tree() -> void:
	## Иначе автозагрузки могут вызвать колбэк на узле уже вне дерева (Aurora/Wayland + смена сцены) → ERROR can_process / SIGSEGV.
	if DialogueManager.dialogue_started.is_connected(_on_dialogue_started_visibility):
		DialogueManager.dialogue_started.disconnect(_on_dialogue_started_visibility)
	if DialogueManager.dialogue_ended.is_connected(_on_dialogue_ended_visibility):
		DialogueManager.dialogue_ended.disconnect(_on_dialogue_ended_visibility)
	if Events.location_changed.is_connected(_on_location_changed_touch_visibility):
		Events.location_changed.disconnect(_on_location_changed_touch_visibility)
	var vp := get_viewport()
	if vp and vp.size_changed.is_connected(_on_viewport_size_changed):
		vp.size_changed.disconnect(_on_viewport_size_changed)


func _connect_touch_zone_resize_signals() -> void:
	var root := get_node_or_null("Root") as Control
	if root == null:
		return
	var vj := root.get_node_or_null("VirtualJoystick") as Control
	var rc := root.get_node_or_null("RightCluster") as Control
	var rest := root.get_node_or_null("RestCampButton") as Control
	if vj:
		vj.resized.connect(_on_touch_zone_resized.bind(vj, true))
	if rest:
		rest.resized.connect(_on_touch_zone_resized.bind(rest, true))
	if rc:
		rc.resized.connect(_on_touch_zone_resized.bind(rc, false))


func _on_touch_zone_resized(zone: Control, is_left: bool) -> void:
	_apply_scaled_touch_zone(zone, is_left)
	if zone and (zone.name == "VirtualJoystick" or zone.name == "RestCampButton"):
		_reposition_rest_above_joystick()


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


func _on_location_changed_touch_visibility(_loc: Events.LOCATION) -> void:
	_refresh_visibility()


func _process(_delta: float) -> void:
	if PerformancePreset.is_slipper_mode(SaveManager):
		_slipper_refresh_tick += 1
		if (_slipper_refresh_tick % _SLIPPER_TOUCH_REFRESH_EVERY_FRAMES) != 0:
			return
	_refresh_visibility()


func _refresh_visibility() -> void:
	if not is_inside_tree():
		return
	var st := get_tree()
	if st == null:
		return
	var want := _should_show_touch_ui()
	var blocked := st.paused or DialogueManager.is_active()
	var show := want and not blocked
	visible = show
	MobileVirtualInput.set_controls_visible(show)
	if show:
		var loc := Events.current_location
		var on_island: bool = loc != Events.LOCATION.MENU and loc != Events.LOCATION.BASE
		var rally_btn := get_node_or_null("Root/RightCluster/RallyButton") as Control
		if rally_btn:
			rally_btn.visible = on_island
		var rest_btn := get_node_or_null("Root/RestCampButton") as Control
		if rest_btn:
			rest_btn.visible = on_island
			if on_island:
				rest_btn.process_mode = Node.PROCESS_MODE_INHERIT if CrownSystem.should_rest_button_be_interactive() else Node.PROCESS_MODE_DISABLED


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
	if not is_inside_tree():
		return
	var root := get_node_or_null("Root") as Control
	if root == null:
		return
	_cache_rest_offsets_from_scene_if_needed(root)
	root.scale = Vector2.ONE
	root.modulate.a = float(SaveManager.touch_opacity_percent) / 100.0
	var vj := root.get_node_or_null("VirtualJoystick") as Control
	var rc := root.get_node_or_null("RightCluster") as Control
	var rest := root.get_node_or_null("RestCampButton") as Control
	if vj:
		_apply_scaled_touch_zone(vj, true)
	if rest:
		_apply_scaled_touch_zone(rest, true)
	if rc:
		_apply_scaled_touch_zone(rc, false)
	_reposition_rest_above_joystick()
	_refresh_visibility()


func _cache_rest_offsets_from_scene_if_needed(root: Control) -> void:
	if _rest_offsets_cached:
		return
	var rest := root.get_node_or_null("RestCampButton") as Control
	if rest == null:
		return
	_rest_offset_base = Vector4(
		rest.offset_left, rest.offset_top, rest.offset_right, rest.offset_bottom
	)
	_rest_offsets_cached = true


## Джойстик масштабируется от нижнего левого угла и растёт вверх; отступы привала в сцене
## рассчитаны на 100%% — без сдвига при s>1 крест наезжает на кнопку привала.
func _reposition_rest_above_joystick() -> void:
	if not _rest_offsets_cached:
		return
	var root := get_node_or_null("Root") as Control
	if root == null:
		return
	var vj := root.get_node_or_null("VirtualJoystick") as Control
	var rest := root.get_node_or_null("RestCampButton") as Control
	if vj == null or rest == null:
		return
	if vj.size.y < 1.0:
		return
	var s := float(SaveManager.touch_scale_percent) / 100.0
	var dy := (s - 1.0) * vj.size.y
	rest.offset_left = _rest_offset_base.x
	rest.offset_top = _rest_offset_base.y - dy
	rest.offset_right = _rest_offset_base.z
	rest.offset_bottom = _rest_offset_base.w - dy


func _should_show_touch_ui() -> bool:
	## Эпилог в главном меню: герой у сундука — нужны атака/щит, иначе layer меню перекрывает (HUD поднимают отдельно).
	if Events.current_location == Events.LOCATION.MENU:
		var p: Node = GameManager.current_scene_player
		if p != null and is_instance_valid(p):
			return true
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
