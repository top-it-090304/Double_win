extends Control


func _on_new_game_pressed() -> void:
	SaveManager.reset_data()
	var player := get_tree().get_first_node_in_group("player")
	if player and player.has_method("sync_from_save"):
		player.sync_from_save()
	Events.location_changed.emit(Events.LOCATION.BASE)


func _on_continue_pressed() -> void:
	Events.location_changed.emit(Events.LOCATION.BASE)


func _on_settings_pressed() -> void:
	pass


func _on_quit_pressed() -> void:
	get_tree().quit()
