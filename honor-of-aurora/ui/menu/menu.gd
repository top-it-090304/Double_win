extends Control


func _on_new_game_pressed() -> void:
	Events.location_changed.emit(Events.LOCATION.BASE)
