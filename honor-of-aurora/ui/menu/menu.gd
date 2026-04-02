extends Control

const SettingsOverlayScene := preload("res://ui/menu/settings_overlay.tscn")
const NewGameConfirmScene := preload("res://objects/YouthLetterDockZone/youth_letter_dock_offer_panel.tscn")
var _settings: Control
var _settings_canvas: CanvasLayer


func _ready() -> void:
	# Отдельный слой поверх кнопок: экранные координаты (не мир Node2D).
	_settings_canvas = CanvasLayer.new()
	_settings_canvas.layer = 100
	add_child(_settings_canvas)
	_settings = SettingsOverlayScene.instantiate()
	_settings_canvas.add_child(_settings)


func _on_new_game_pressed() -> void:
	SoundManager.play_ui_button()
	if SaveManager.is_saved_progress_equivalent_to_new_game():
		_begin_new_game()
	else:
		_show_new_game_confirm()


func _begin_new_game() -> void:
	SaveManager.reset_data()
	SaveManager.apply_resume_position_on_next_scene = false
	Events.location_changed.emit(Events.LOCATION.BASE)


func _show_new_game_confirm() -> void:
	var panel: Control = NewGameConfirmScene.instantiate()
	add_child(panel)
	if panel.has_method("setup"):
		panel.setup(
			"Новая игра",
			"Вы уверены, что хотите начать новую игру? Текущий прогресс будет сброшен.",
			"Да, начать",
			"Отмена"
		)
	if panel.has_signal("offer_confirmed"):
		panel.offer_confirmed.connect(_on_new_game_confirm_confirmed, CONNECT_ONE_SHOT)


func _on_new_game_confirm_confirmed() -> void:
	SoundManager.play_ui_button()
	_begin_new_game()


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
