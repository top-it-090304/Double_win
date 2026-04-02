extends Control

@onready var _btn_lvl1: Button = $TextureRect/buttons/Button
@onready var _btn_lvl2: Button = $TextureRect/buttons/Button2
@onready var _btn_lvl3: Button = $TextureRect/buttons/Button3
@onready var _btn_lvl4: Button = $TextureRect/buttons/Button4
@onready var _btn_lvl5: Button = $TextureRect/buttons/Button5
@onready var _btn_base: Button = $TextureRect/buttons/Button7

var _tp_usage_label: Label


func _ready() -> void:
	_setup_teleport_usage_label()
	_refresh_teleport_usage_label()
	if not Events.teleport_usage_count_changed.is_connected(_on_teleport_usage_count_changed):
		Events.teleport_usage_count_changed.connect(_on_teleport_usage_count_changed)
	_refresh_teleport_buttons_disabled()


func _setup_teleport_usage_label() -> void:
	_tp_usage_label = Label.new()
	_tp_usage_label.name = "TeleportUsageLabel"
	_tp_usage_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_tp_usage_label.add_theme_font_size_override("font_size", 15)
	add_child(_tp_usage_label)
	_tp_usage_label.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_tp_usage_label.offset_left = 12.0
	_tp_usage_label.offset_top = 8.0
	_tp_usage_label.offset_right = 420.0
	_tp_usage_label.offset_bottom = 72.0


func _refresh_teleport_usage_label() -> void:
	if _tp_usage_label == null:
		return
	var n: int = SaveManager.teleport_usage_count
	var line2: String = "Дождь + x2 лут (каждый 5-й телепорт, до следующего)" if RainSystem.is_rain_weather_active() else "След. дождь + x2 на 5-м, 10-м, 15-м… телепорте"
	_tp_usage_label.text = "Телепортаций: %d\n%s" % [n, line2]


func _on_teleport_usage_count_changed(_c: int) -> void:
	_refresh_teleport_usage_label()


## Вызывается из HUD при входе в зону телепорта; `_location` оставлен для совместимости с TeleportZone.
func set_target_location(_location: Events.LOCATION) -> void:
	_refresh_teleport_usage_label()
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
