extends Control


func get_hud():
	return get_tree().get_first_node_in_group("hud")


func _teleport(loc: Events.LOCATION) -> void:
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
	if not _can_access_last_island():
		DialogueRegistry.try_start("gate_lv5_blocked", true)
		return
	_teleport(Events.LOCATION.LVL5)


func _can_access_last_island() -> bool:
	if StoryState.has_flag("hero_chose_refuse_chain"):
		return false
	if StoryState.has_flag("hero_chose_finish_chain") and StoryState.has_flag("truth_and_choice_done"):
		return true
	if StoryState.has_flag("story_island_5_cleared"):
		return true
	return false


func _on_button_6_pressed() -> void:
	var hud = get_hud()
	if hud:
		hud.hide_teleport_menu()


func _on_button_7_pressed() -> void:
	_teleport(Events.LOCATION.BASE)
