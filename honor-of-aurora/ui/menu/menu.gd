extends Control

const SettingsOverlayScene := preload("res://ui/menu/settings_overlay.tscn")
var _settings: Control


func _ready() -> void:
	_settings = SettingsOverlayScene.instantiate()
	add_child(_settings)


func _on_new_game_pressed() -> void:
	SoundManager.play_ui_button()
	SaveManager.reset_data()
	SaveManager.apply_resume_position_on_next_scene = false
	Events.location_changed.emit(Events.LOCATION.BASE)


func _on_continue_pressed() -> void:
	SoundManager.play_ui_button()
	SaveManager.apply_resume_position_on_next_scene = true
	Events.location_changed.emit(SaveManager.get_resume_location_enum())


func _on_settings_pressed() -> void:
	SoundManager.play_ui_button()
	if _settings:
		_settings.show_settings()


func _on_quit_pressed() -> void:
	SoundManager.play_ui_button()
	get_tree().quit()
