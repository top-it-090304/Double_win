extends Control
class_name VirtualJoystick

## Виртуальный стик — яркое свечение и контраст, чтобы отличие было видно сразу.

const OUTER_RADIUS := 82.0
const DEAD_ZONE := 0.14
const KNOB_RADIUS := 30.0

var _stick_offset: Vector2 = Vector2.ZERO
var _touch_id: int = -1
var _dragging: bool = false
var _center: Vector2 = Vector2.ZERO


func _ready() -> void:
	custom_minimum_size = Vector2(228, 228)
	mouse_filter = Control.MOUSE_FILTER_STOP
	resized.connect(_on_resized)
	call_deferred("_on_resized")
	queue_redraw()


func _on_resized() -> void:
	_center = size * 0.5
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var st := event as InputEventScreenTouch
		if st.pressed:
			if _touch_id < 0:
				## Не вызывать make_input_local: в _gui_input позиция уже локальная (Viewport + ScreenTouch).
				var local := st.position
				if _in_circle(local):
					_touch_id = st.index
					_dragging = true
					_apply_local(local)
		else:
			if st.index == _touch_id:
				_reset_stick()
	elif event is InputEventScreenDrag:
		var sd := event as InputEventScreenDrag
		if sd.index == _touch_id and _dragging:
			## Позиция уже в локальных координатах этого Control (см. Viewport::_gui_* для ScreenDrag).
			_apply_local(sd.position)
	elif event is InputEventMouseMotion:
		var mm := event as InputEventMouseMotion
		if _dragging and _touch_id == 0 and (mm.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
			_apply_local(get_local_mouse_position())
	elif event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				if _touch_id < 0:
					var local := get_local_mouse_position()
					if _in_circle(local):
						_touch_id = 0
						_dragging = true
						_apply_local(local)
			else:
				if _touch_id == 0:
					_reset_stick()


func _in_circle(local: Vector2) -> bool:
	return local.distance_to(_center) <= OUTER_RADIUS + 18.0


func _apply_local(local: Vector2) -> void:
	var off := local - _center
	var max_r := OUTER_RADIUS - KNOB_RADIUS * 0.35
	if off.length() > max_r and off.length_squared() > 0.0001:
		off = off.normalized() * max_r
	_stick_offset = off
	_push_vector()
	queue_redraw()


func _push_vector() -> void:
	var v := _stick_offset / OUTER_RADIUS
	if v.length() < DEAD_ZONE:
		MobileVirtualInput.move_vector = Vector2.ZERO
	else:
		var n := v.normalized()
		var mag := clampf((v.length() - DEAD_ZONE) / (1.0 - DEAD_ZONE), 0.0, 1.0)
		MobileVirtualInput.move_vector = n * mag


func _reset_stick() -> void:
	_touch_id = -1
	_dragging = false
	_stick_offset = Vector2.ZERO
	MobileVirtualInput.move_vector = Vector2.ZERO
	queue_redraw()


func _draw() -> void:
	var c := _center if _center != Vector2.ZERO else size * 0.5
	_draw_outer_bloom(c)
	_draw_base_plate(c)
	_draw_rim_and_inner(c)
	_draw_cross(c)
	_draw_knob(c + _stick_offset)


func _draw_outer_bloom(center: Vector2) -> void:
	for i in range(8):
		var t := float(i) / 7.0
		var rad := OUTER_RADIUS + 18.0 - t * 14.0
		var a := 0.24 - t * 0.024
		draw_circle(center, rad, Color(0.2, 0.65, 1.0, a))
	draw_arc(center, OUTER_RADIUS + 6.0, 0.0, TAU, 96, Color(0.5, 0.88, 0.95, 0.55), 5.0, true)


func _draw_base_plate(center: Vector2) -> void:
	draw_circle(center, OUTER_RADIUS + 6.0, Color(0.0, 0.0, 0.0, 0.68))
	draw_circle(center, OUTER_RADIUS + 3.0, Color(0.07, 0.09, 0.15, 0.96))
	draw_circle(center, OUTER_RADIUS, Color(0.11, 0.15, 0.24, 1.0))


func _draw_rim_and_inner(center: Vector2) -> void:
	var drag_boost := 1.25 if _dragging else 1.0
	# Яркий холодный обод
	draw_arc(center, OUTER_RADIUS, 0.0, TAU, 120, Color(0.45, 0.78, 1.0, 0.75 * drag_boost), 4.0, true)
	# Внутренний светлый сегмент
	draw_arc(center, OUTER_RADIUS - 2.0, -PI * 0.45, PI * 0.15, 56, Color(0.65, 0.88, 1.0, 0.35), 5.0, true)
	draw_circle(center, OUTER_RADIUS - 8.0, Color(0.0, 0.0, 0.0, 0.42))
	draw_circle(center, OUTER_RADIUS - 10.0, Color(0.08, 0.22, 0.42, 0.48 * drag_boost))


func _draw_cross(center: Vector2) -> void:
	var cross_l := 36.0
	var col := Color(0.78, 0.85, 0.98, 0.55)
	draw_line(center + Vector2(-cross_l, 0), center + Vector2(cross_l, 0), col, 2.5, true)
	draw_line(center + Vector2(0, -cross_l), center + Vector2(0, cross_l), col, 2.5, true)


func _draw_knob(pos: Vector2) -> void:
	for i in range(5):
		var o := Vector2(0, 2.0 + float(i) * 1.2)
		draw_circle(pos + o, KNOB_RADIUS + 5.0 - float(i), Color(0.0, 0.0, 0.0, 0.18 - i * 0.028))
	draw_circle(pos, KNOB_RADIUS + 2.0, Color(0.15, 0.55, 0.95, 0.45))
	draw_circle(pos, KNOB_RADIUS, Color(0.22, 0.24, 0.32, 1.0))
	draw_circle(pos, KNOB_RADIUS - 2.0, Color(0.38, 0.44, 0.56, 0.62))
	draw_arc(pos, KNOB_RADIUS - 5.0, -PI * 0.95, -PI * 0.05, 28, Color(1.0, 1.0, 1.0, 0.45), 3.5, true)
	draw_arc(pos, KNOB_RADIUS - 0.5, 0.0, TAU, 64, Color(0.85, 0.9, 1.0, 0.65), 2.0, true)
