extends Control

@onready var _btn_lvl1: Button = $TextureRect/buttons/Button
@onready var _btn_lvl2: Button = $TextureRect/buttons/Button2
@onready var _btn_lvl3: Button = $TextureRect/buttons/Button3
@onready var _btn_lvl4: Button = $TextureRect/buttons/Button4
@onready var _btn_lvl5: Button = $TextureRect/buttons/Button5
@onready var _btn_base: Button = $TextureRect/buttons/Button7


func _ready() -> void:
	_refresh_teleport_buttons_disabled()


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
