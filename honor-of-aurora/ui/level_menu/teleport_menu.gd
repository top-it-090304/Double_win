extends Control

## Логический макет сцены телепорта (как при полноэкранной раскладке). В режиме «На тапке» панель центрируем
## и масштабируем от центра, чтобы заполнить экран без clip_contents (обрезки).
const _DESIGN_VIEW_W := 1280.0
const _DESIGN_VIEW_H := 720.0
const _SLIPPER_EDGE_MARGIN_PX := 10.0

@onready var _texture_root: TextureRect = $TextureRect
@onready var _btn_lvl1: Button = $TextureRect/buttons/Button
@onready var _btn_lvl2: Button = $TextureRect/buttons/Button2
@onready var _btn_lvl3: Button = $TextureRect/buttons/Button3
@onready var _btn_lvl4: Button = $TextureRect/buttons/Button4
@onready var _btn_lvl5: Button = $TextureRect/buttons/Button5
@onready var _btn_base: Button = $TextureRect/buttons/Button7


func _ready() -> void:
	_refresh_teleport_buttons_disabled()
	var vp := get_viewport()
	if vp and not vp.size_changed.is_connected(_on_viewport_size_changed_tp):
		vp.size_changed.connect(_on_viewport_size_changed_tp)
	call_deferred("_refit_slipper_teleport_panel")


func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED and visible:
		call_deferred("_refit_slipper_teleport_panel")


func _on_viewport_size_changed_tp() -> void:
	_refit_slipper_teleport_panel()


func _refit_slipper_teleport_panel() -> void:
	if not is_inside_tree() or _texture_root == null:
		return
	if not PerformancePreset.is_slipper_mode(SaveManager):
		_reset_texture_root_fullscreen_layout()
		return
	var vp := get_viewport()
	if vp == null:
		return
	var r := vp.get_visible_rect()
	var vw := maxf(r.size.x, 1.0)
	var vh := maxf(r.size.y, 1.0)
	var design_w := float(ProjectSettings.get_setting("display/window/size/viewport_width", _DESIGN_VIEW_W))
	var design_h := float(ProjectSettings.get_setting("display/window/size/viewport_height", _DESIGN_VIEW_H))
	var m := _SLIPPER_EDGE_MARGIN_PX
	var avail_w := maxf(vw - m * 2.0, 1.0)
	var avail_h := maxf(vh - m * 2.0, 1.0)
	## Максимальный масштаб, чтобы вся панель помещалась; без верхнего искусственного «потолка» — крупно.
	var s := minf(avail_w / design_w, avail_h / design_h)
	s = maxf(s, 0.2)
	## 1 = режим якорей (Control.LayoutMode в редакторе); не `Control.LAYOUT_MODE_ANCHORS` — в GDScript такого члена нет.
	_texture_root.layout_mode = 1
	_texture_root.anchor_left = 0.5
	_texture_root.anchor_right = 0.5
	_texture_root.anchor_top = 0.5
	_texture_root.anchor_bottom = 0.5
	var half_w := design_w * 0.5
	var half_h := design_h * 0.5
	_texture_root.offset_left = -half_w
	_texture_root.offset_right = half_w
	_texture_root.offset_top = -half_h
	_texture_root.offset_bottom = half_h
	_texture_root.pivot_offset = Vector2(half_w, half_h)
	_texture_root.scale = Vector2(s, s)
	_texture_root.rotation = 0.0


func _reset_texture_root_fullscreen_layout() -> void:
	if _texture_root == null:
		return
	_texture_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_texture_root.offset_left = 0.0
	_texture_root.offset_top = 0.0
	_texture_root.offset_right = 0.0
	_texture_root.offset_bottom = 0.0
	_texture_root.scale = Vector2.ONE
	_texture_root.pivot_offset = Vector2.ZERO
	_texture_root.rotation = 0.0


## Вызывается из HUD при входе в зону телепорта; `_location` оставлен для совместимости с TeleportZone.
func set_target_location(_location: Events.LOCATION) -> void:
	_refresh_teleport_buttons_disabled()


func _refresh_teleport_buttons_disabled() -> void:
	var here := Events.current_location
	_btn_lvl1.disabled = here == Events.LOCATION.LVL1 or not GameManager.can_teleport_to_location(Events.LOCATION.LVL1)
	_btn_lvl2.disabled = here == Events.LOCATION.LVL2 or not GameManager.can_teleport_to_location(Events.LOCATION.LVL2)
	_btn_lvl3.disabled = here == Events.LOCATION.LVL3 or not GameManager.can_teleport_to_location(Events.LOCATION.LVL3)
	_btn_lvl4.disabled = here == Events.LOCATION.LVL4 or not GameManager.can_teleport_to_location(Events.LOCATION.LVL4)
	# Остров 5: блок только по прогрессии (босс 4); сюжетный замок — по клику и диалогу gate_lv5_blocked.
	_btn_lvl5.disabled = here == Events.LOCATION.LVL5 or not StoryState.has_flag("story_island_4_cleared")
	_btn_base.disabled = here == Events.LOCATION.BASE


func get_hud() -> Node:
	return GameplayFacade.get_hud(get_tree())


func _teleport(loc: Events.LOCATION) -> void:
	if Events.current_location == loc:
		return
	if not GameManager.can_teleport_to_location(loc):
		return
	SoundManager.play_ui_button()
	SoundManager.play_teleport()
	var hud = get_hud()
	if hud:
		hud.teleport_to(loc)


func _on_button_pressed() -> void:
	_teleport(Events.LOCATION.LVL1)


func _on_button_2_pressed() -> void:
	_teleport(Events.LOCATION.LVL2)


func _on_button_3_pressed() -> void:
	_teleport(Events.LOCATION.LVL3)


func _on_button_4_pressed() -> void:
	_teleport(Events.LOCATION.LVL4)


func _on_button_5_pressed() -> void:
	if not GameManager.can_access_last_island_lv5():
		DialogueRegistry.try_start("gate_lv5_blocked")
		return
	_teleport(Events.LOCATION.LVL5)


func _on_button_6_pressed() -> void:
	var hud = get_hud()
	if hud:
		hud.hide_teleport_menu()


func _on_button_7_pressed() -> void:
	_teleport(Events.LOCATION.BASE)
