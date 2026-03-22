extends MobaActionButton

func _ready() -> void:
	kind = BtnKind.SHIELD
	super._ready()


func _input(event: InputEvent) -> void:
	if _is_interaction_disabled():
		return
	if not (event is InputEventScreenTouch):
		return
	var st := event as InputEventScreenTouch
	var le := make_input_local(st)
	var local := (le as InputEventScreenTouch).position
	if st.pressed:
		if not _is_point_inside(local):
			return
		_touch_indices[st.index] = true
		_sync_shield_state()
		queue_redraw()
		get_viewport().set_input_as_handled()
		return
	# Отпускание часто приходит не той Control, если палец ушёл с кнопки — сбрасываем по index.
	if _touch_indices.has(st.index):
		_touch_indices.erase(st.index)
		_sync_shield_state()
		queue_redraw()
		get_viewport().set_input_as_handled()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		return
	super._gui_input(event)
