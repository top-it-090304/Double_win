extends Control


func _on_new_game_pressed() -> void:
	SaveManager.reset_data()
	Events.location_changed.emit(Events.LOCATION.BASE)


func _on_continue_pressed() -> void:
	Events.location_changed.emit(Events.LOCATION.BASE)


func _on_settings_pressed() -> void:
	pass # Replace with function body.


func _on_quit_pressed() -> void:
	get_tree().quit()
