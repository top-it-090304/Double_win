extends Control
class_name MobaActionButton

## Control + явная обработка ScreenTouch — параллельно со стиком (несколько касаний).
## Button + emulate_mouse_from_touch даёт один виртуальный курсор и блокирует второй палец.

enum BtnKind { ATTACK, SHIELD, RALLY, REST }

@export var kind: BtnKind = BtnKind.ATTACK

const TEX_ATTACK := preload("res://Asets/Unit_pack/UI Elements/UI Elements/Icons/Icon_05.png")
const TEX_SHIELD := preload("res://Asets/Unit_pack/UI Elements/UI Elements/Icons/Icon_06.png")
const TEX_RALLY := preload("res://Asets/Unit_pack/UI Elements/UI Elements/Cursors/Cursor_04.png")
const TEX_REST := preload("res://Asets/Environment/Resources/Resources/M_Idle.png")

const SZ_ATTACK := Vector2(100, 100)
const SZ_SHIELD := Vector2(76, 76)
const SZ_RALLY := Vector2(60, 60)
const SZ_REST := Vector2(76, 76)

## Палитра: насыщенный коралл и лёд (щит/«чит») — заметнее на экране. (Литералы Color — const; from_hsv в const недопустим.)
const ACCENT_ATTACK := Color(1.0, 0.21, 0.26, 1.0)
const ACCENT_SHIELD := Color(0.1, 0.64, 1.0, 1.0)
const BASE_INNER_ATTACK := Color(0.2, 0.07, 0.09, 1.0)
const BASE_INNER_SHIELD := Color(0.04, 0.12, 0.26, 1.0)
const ACCENT_RALLY := Color(0.95, 0.72, 0.22, 1.0)
const BASE_INNER_RALLY := Color(0.16, 0.11, 0.04, 1.0)
const ACCENT_REST := Color(0.76, 0.56, 0.24, 1.0)
const BASE_INNER_REST := Color(0.12, 0.1, 0.06, 1.0)

var _hovered: bool = false
## Индексы касаний, начавшиеся на этой кнопке (для щита и визуала).
var _touch_indices: Dictionary = {}
var _mouse_pressed: bool = false


func _ready() -> void:
	focus_mode = Control.FOCUS_NONE
	mouse_filter = Control.MOUSE_FILTER_STOP
	var sz: Vector2 = SZ_SHIELD
	if kind == BtnKind.ATTACK:
		sz = SZ_ATTACK
	elif kind == BtnKind.RALLY:
		sz = SZ_RALLY
	elif kind == BtnKind.REST:
		sz = SZ_REST
	custom_minimum_size = sz
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)


func _on_mouse_entered() -> void:
	_hovered = true
	queue_redraw()


func _on_mouse_exited() -> void:
	_hovered = false
	queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_THEME_CHANGED:
		queue_redraw()


func _is_visual_pressed() -> bool:
	if kind == BtnKind.SHIELD:
		return not _touch_indices.is_empty() or _mouse_pressed
	return _mouse_pressed or not _touch_indices.is_empty()


func _is_visual_hover() -> bool:
	return _hovered


func _sync_shield_state() -> void:
	if kind != BtnKind.SHIELD:
		return
	MobileVirtualInput.shield_held = not _touch_indices.is_empty() or _mouse_pressed


func _is_point_inside(local: Vector2) -> bool:
	return Rect2(Vector2.ZERO, size).has_point(local)


func _is_interaction_disabled() -> bool:
	return process_mode == Node.PROCESS_MODE_DISABLED or not visible


## Атака и сбор: ScreenTouch через _input (как у щита), иначе после set_input_as_handled() у щита
## событие может не дойти до _gui_input соседней кнопки.
func _input(event: InputEvent) -> void:
	if _is_interaction_disabled() or (kind != BtnKind.ATTACK and kind != BtnKind.RALLY and kind != BtnKind.REST):
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
		if kind == BtnKind.ATTACK:
			MobileVirtualInput.queue_attack()
		elif kind == BtnKind.RALLY:
			_try_rally_squad()
		else:
			_try_rest_camp()
		queue_redraw()
		get_viewport().set_input_as_handled()
		return
	if _touch_indices.has(st.index):
		_touch_indices.erase(st.index)
		queue_redraw()
		get_viewport().set_input_as_handled()


func _gui_input(event: InputEvent) -> void:
	if _is_interaction_disabled():
		return
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index != MOUSE_BUTTON_LEFT:
			return
		var local := get_local_mouse_position()
		if not _is_point_inside(local):
			return
		if mb.pressed:
			_mouse_pressed = true
			if kind == BtnKind.ATTACK:
				MobileVirtualInput.queue_attack()
			elif kind == BtnKind.RALLY:
				_try_rally_squad()
			elif kind == BtnKind.REST:
				_try_rest_camp()
			else:
				_sync_shield_state()
			queue_redraw()
			accept_event()
		else:
			_mouse_pressed = false
			if kind == BtnKind.SHIELD:
				_sync_shield_state()
			queue_redraw()
			accept_event()


func _accent_color() -> Color:
	if _is_interaction_disabled():
		return Color(0.45, 0.48, 0.55, 0.75)
	if kind == BtnKind.ATTACK:
		return ACCENT_ATTACK
	if kind == BtnKind.RALLY:
		return ACCENT_RALLY
	if kind == BtnKind.REST:
		return ACCENT_REST
	return ACCENT_SHIELD


func _inner_fill() -> Color:
	var base: Color = BASE_INNER_SHIELD
	if kind == BtnKind.ATTACK:
		base = BASE_INNER_ATTACK
	elif kind == BtnKind.RALLY:
		base = BASE_INNER_RALLY
	elif kind == BtnKind.REST:
		base = BASE_INNER_REST
	if _is_interaction_disabled():
		return base.darkened(0.35)
	if _is_visual_pressed():
		return base.darkened(0.22)
	if _is_visual_hover():
		return base.lightened(0.12)
	return base


func _draw() -> void:
	var c := size * 0.5
	var r := mini(size.x, size.y) * 0.5
	var accent := _accent_color()

	draw_circle(c + Vector2(0, 7), r + 1.0, Color(0.0, 0.0, 0.0, 0.48))

	for i in range(5):
		var t := float(i) / 4.0
		var rad := r + 5.0 - t * 3.5
		var a := 0.24 - t * 0.04
		draw_circle(c, rad, Color(accent.r, accent.g, accent.b, a))

	draw_circle(c, r, Color(accent.r * 0.35, accent.g * 0.35, accent.b * 0.35, 0.72))
	draw_circle(c, r - 3.0, Color(accent.r, accent.g, accent.b, 0.68))

	var inner := _inner_fill()
	inner.a *= 0.82
	draw_circle(c, r - 6.0, inner)

	draw_arc(c, r - 6.5, 0.0, TAU, 64, Color(1.0, 1.0, 1.0, 0.18), 2.0, true)

	var gloss_a := 0.26
	if _is_visual_pressed():
		gloss_a = 0.1
	elif _is_visual_hover():
		gloss_a = 0.32
	draw_arc(c, (r - 6.0) * 0.72, -PI * 0.88, -PI * 0.12, 32, Color(1.0, 1.0, 1.0, gloss_a), 4.5, true)

	var tex: Texture2D = TEX_SHIELD
	if kind == BtnKind.ATTACK:
		tex = TEX_ATTACK
	elif kind == BtnKind.RALLY:
		tex = TEX_RALLY
	elif kind == BtnKind.REST:
		tex = TEX_REST
	_draw_icon_texture(tex)


func _try_rally_squad() -> void:
	if DialogueManager.is_active() or ChestLootUi.is_chest_popup_open():
		return
	if Events.current_location == Events.LOCATION.MENU:
		return
	if Events.current_location == Events.LOCATION.BASE:
		return
	GameplayFacade.try_rally_straggler_allies_to_hero()


func _try_rest_camp() -> void:
	if DialogueManager.is_active() or ChestLootUi.is_chest_popup_open():
		return
	if Events.current_location == Events.LOCATION.MENU:
		return
	if Events.current_location == Events.LOCATION.BASE:
		return
	CrownSystem.try_squad_rest()


func _draw_icon_texture(tex: Texture2D) -> void:
	if tex == null:
		return
	var pad := 12.0
	if kind == BtnKind.REST:
		pad = 2.0
	var max_w := size.x - pad * 2.0
	var max_h := size.y - pad * 2.0
	var tw := float(tex.get_width())
	var th := float(tex.get_height())
	if tw <= 0.0 or th <= 0.0:
		return
	var sc := minf(max_w / tw, max_h / th)
	var w := tw * sc
	var h := th * sc
	var pos := Vector2((size.x - w) * 0.5, (size.y - h) * 0.5)
	var mod := Color(1.05, 1.05, 1.08, 1.0)
	if _is_visual_pressed():
		mod = Color(0.88, 0.9, 0.98, 1.0)
	elif _is_visual_hover():
		mod = Color(1.12, 1.12, 1.16, 1.0)
	draw_texture_rect(tex, Rect2(pos, Vector2(w, h)), false, mod)
