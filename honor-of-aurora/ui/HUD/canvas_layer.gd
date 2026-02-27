extends CanvasLayer

func _on_button_pressed() -> void:
	Events.location_changed.emit(Events.LOCATION.MENU)
