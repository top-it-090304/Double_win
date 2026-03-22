extends Control

## Панель громкости: Music / SFX / UI / Dialogue. Значения в SaveManager, шины — SoundManager.

@onready var _music_slider: HSlider = %MusicSlider
@onready var _sfx_slider: HSlider = %SfxSlider
@onready var _ui_slider: HSlider = %UiSlider
@onready var _dialogue_slider: HSlider = %DialogueSlider


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_process_unhandled_input(true)
	_music_slider.value_changed.connect(_on_music_changed)
	_sfx_slider.value_changed.connect(_on_sfx_changed)
	_ui_slider.value_changed.connect(_on_ui_changed)
	_dialogue_slider.value_changed.connect(_on_dialogue_changed)


func show_settings() -> void:
	_load_sliders_from_save()
	visible = true


func _load_sliders_from_save() -> void:
	for s in [_music_slider, _sfx_slider, _ui_slider, _dialogue_slider]:
		s.set_block_signals(true)
	_music_slider.value = SaveManager.volume_music * 100.0
	_sfx_slider.value = SaveManager.volume_sfx * 100.0
	_ui_slider.value = SaveManager.volume_ui * 100.0
	_dialogue_slider.value = SaveManager.volume_dialogue * 100.0
	for s in [_music_slider, _sfx_slider, _ui_slider, _dialogue_slider]:
		s.set_block_signals(false)


func _on_music_changed(v: float) -> void:
	SaveManager.volume_music = clampf(v / 100.0, 0.0, 1.0)
	SoundManager.apply_user_volume_settings()
	SaveManager.save_game()


func _on_sfx_changed(v: float) -> void:
	SaveManager.volume_sfx = clampf(v / 100.0, 0.0, 1.0)
	SoundManager.apply_user_volume_settings()
	SaveManager.save_game()


func _on_ui_changed(v: float) -> void:
	SaveManager.volume_ui = clampf(v / 100.0, 0.0, 1.0)
	SoundManager.apply_user_volume_settings()
	SaveManager.save_game()


func _on_dialogue_changed(v: float) -> void:
	SaveManager.volume_dialogue = clampf(v / 100.0, 0.0, 1.0)
	SoundManager.apply_user_volume_settings()
	SaveManager.save_game()


func _on_back_pressed() -> void:
	SoundManager.play_ui_button()
	visible = false


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		_on_back_pressed()
		get_viewport().set_input_as_handled()
