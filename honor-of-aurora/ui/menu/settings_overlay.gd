extends Control
## Полноэкранные настройки: сложность, звук, экран, сенсорное управление. Сохранение в SaveManager.
## При emulate_mouse_from_touch=false жест по ScrollContainer не доходит от дочерних контролов — дублируем скролл в _input.

@onready var _scroll: ScrollContainer = $OuterMargin/Center/MenuCard/InnerMargin/MainVBox/Scroll
@onready var _difficulty: OptionButton = %DifficultyOption
@onready var _difficulty_desc: Label = %DifficultyDesc
@onready var _music_slider: HSlider = %MusicSlider
@onready var _sfx_slider: HSlider = %SfxSlider
@onready var _ui_slider: HSlider = %UiSlider
@onready var _dialogue_slider: HSlider = %DialogueSlider
@onready var _dialogue_text_scale_slider: HSlider = %DialogueTextScaleSlider
@onready var _perf_option: OptionButton = %PerformanceModeOption
@onready var _perf_desc: Label = %PerformanceDesc
@onready var _auto_fit_phone_check: CheckButton = %AutoFitPhoneCheck
@onready var _ui_scale_slider: HSlider = %UiScaleSlider
@onready var _touch_scale: HSlider = %TouchScaleSlider
@onready var _touch_opacity: HSlider = %TouchOpacitySlider

var _settings_scroll_touch_index: int = -1


func _ready() -> void:
	theme = GameUITheme.create_theme()
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process_input(true)
	set_process_unhandled_input(true)
	if _scroll:
		_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_fill_difficulty_options()
	_fill_performance_options()
	_music_slider.value_changed.connect(_on_music_changed)
	_sfx_slider.value_changed.connect(_on_sfx_changed)
	_ui_slider.value_changed.connect(_on_ui_changed)
	_dialogue_slider.value_changed.connect(_on_dialogue_changed)
	_dialogue_text_scale_slider.value_changed.connect(_on_dialogue_text_scale_changed)
	_difficulty.item_selected.connect(_on_difficulty_selected)
	_perf_option.item_selected.connect(_on_performance_mode_selected)
	_auto_fit_phone_check.toggled.connect(_on_auto_fit_phone_toggled)
	_ui_scale_slider.value_changed.connect(_on_ui_scale_changed)
	_touch_scale.value_changed.connect(_on_touch_scale_changed)
	_touch_opacity.value_changed.connect(_on_touch_opacity_changed)


func _fill_difficulty_options() -> void:
	_difficulty.clear()
	for p in DifficultyConfig.get_all_presets():
		_difficulty.add_item(str(p.get(DifficultyConfig.KEY_DISPLAY_NAME, "?")))


func _fill_performance_options() -> void:
	_perf_option.clear()
	_perf_option.add_item("Минимальный")
	_perf_option.add_item("Средний")
	_perf_option.add_item("Максимальный")


func show_settings() -> void:
	_load_all_from_save()
	_settings_scroll_touch_index = -1
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = true


func _load_all_from_save() -> void:
	_block_sliders(true)
	_difficulty.set_block_signals(true)
	_perf_option.set_block_signals(true)
	_auto_fit_phone_check.set_block_signals(true)
	if SaveManager.auto_fit_phone_ui:
		SaveManager.apply_auto_phone_ui_settings()
	_music_slider.value = SaveManager.volume_music * 100.0
	_sfx_slider.value = SaveManager.volume_sfx * 100.0
	_ui_slider.value = SaveManager.volume_ui * 100.0
	_dialogue_slider.value = SaveManager.volume_dialogue * 100.0
	_dialogue_text_scale_slider.value = float(SaveManager.dialogue_text_scale_percent)
	_difficulty.select(clampi(SaveManager.difficulty_id, 0, _difficulty.item_count - 1))
	_update_difficulty_desc()
	_perf_option.select(clampi(SaveManager.performance_mode, 0, _perf_option.item_count - 1))
	_update_performance_desc()
	_auto_fit_phone_check.button_pressed = SaveManager.auto_fit_phone_ui
	_ui_scale_slider.value = float(SaveManager.ui_scale_percent)
	_touch_scale.value = float(SaveManager.touch_scale_percent)
	_touch_opacity.value = float(SaveManager.touch_opacity_percent)
	_difficulty.set_block_signals(false)
	_perf_option.set_block_signals(false)
	_auto_fit_phone_check.set_block_signals(false)
	_sync_ui_controls_locked_from_auto_fit()
	_block_sliders(false)


func _block_sliders(block: bool) -> void:
	for s in [_music_slider, _sfx_slider, _ui_slider, _dialogue_slider, _dialogue_text_scale_slider, _ui_scale_slider, _touch_scale, _touch_opacity]:
		s.set_block_signals(block)


func _update_difficulty_desc() -> void:
	var idx := clampi(_difficulty.selected, 0, 2)
	var p := DifficultyConfig.get_preset_by_index(idx)
	_difficulty_desc.text = str(p.get(DifficultyConfig.KEY_DESCRIPTION, ""))


func _on_difficulty_selected(_idx: int) -> void:
	SaveManager.difficulty_id = clampi(_difficulty.selected, 0, 2)
	_update_difficulty_desc()
	SaveManager.save_game()


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


func _on_dialogue_text_scale_changed(v: float) -> void:
	SaveManager.dialogue_text_scale_percent = clampi(int(round(v)), 75, 130)
	SaveManager.save_game()


func _update_performance_desc() -> void:
	if _perf_desc == null:
		return
	match clampi(SaveManager.performance_mode, 0, 2):
		PerformancePreset.Mode.MINIMAL:
			_perf_desc.text = "Минимальный: 30 FPS, физика 30 Гц, редкий пересчёт слоёв по Y (4 кадра), VSync — максимум экономии."
		PerformancePreset.Mode.MAXIMUM:
			_perf_desc.text = "Максимальный: без лимита FPS, физика 60 Гц, Y-sort раз в 2 кадра, VSync — упор на плавность."
		_:
			_perf_desc.text = "Средний: 60 FPS, физика 30 Гц (меньше нагрузки), Y-sort раз в 4 кадра, VSync — ближе к слабому железу при цели 60 FPS."


func _sync_ui_controls_locked_from_auto_fit() -> void:
	var locked := SaveManager.auto_fit_phone_ui
	_ui_scale_slider.editable = not locked
	_touch_scale.editable = not locked
	_touch_opacity.editable = not locked


func _on_performance_mode_selected(_idx: int) -> void:
	SaveManager.performance_mode = clampi(_perf_option.selected, 0, _perf_option.item_count - 1)
	_update_performance_desc()
	SaveManager.save_game()
	SaveManager.apply_window_and_engine_settings()


func _on_ui_scale_changed(v: float) -> void:
	if SaveManager.auto_fit_phone_ui:
		return
	SaveManager.ui_scale_percent = clampi(int(round(v)), 75, 130)
	SaveManager.save_game()
	SaveManager.apply_window_and_engine_settings()


func _on_touch_scale_changed(v: float) -> void:
	if SaveManager.auto_fit_phone_ui:
		return
	SaveManager.touch_scale_percent = clampi(int(round(v)), 70, 150)
	SaveManager.save_game()
	get_tree().call_group("touch_controls", "apply_user_touch_settings")


func _on_touch_opacity_changed(v: float) -> void:
	if SaveManager.auto_fit_phone_ui:
		return
	SaveManager.touch_opacity_percent = clampi(int(round(v)), 25, 100)
	SaveManager.save_game()
	get_tree().call_group("touch_controls", "apply_user_touch_settings")


func _on_auto_fit_phone_toggled(on: bool) -> void:
	SaveManager.auto_fit_phone_ui = on
	if on:
		SaveManager.apply_auto_phone_ui_settings()
		_ui_scale_slider.set_block_signals(true)
		_touch_scale.set_block_signals(true)
		_touch_opacity.set_block_signals(true)
		_ui_scale_slider.value = float(SaveManager.ui_scale_percent)
		_touch_scale.value = float(SaveManager.touch_scale_percent)
		_touch_opacity.value = float(SaveManager.touch_opacity_percent)
		_ui_scale_slider.set_block_signals(false)
		_touch_scale.set_block_signals(false)
		_touch_opacity.set_block_signals(false)
	SaveManager.save_game()
	SaveManager.apply_window_and_engine_settings()
	get_tree().call_group("touch_controls", "apply_user_touch_settings")
	_sync_ui_controls_locked_from_auto_fit()


func _on_back_pressed() -> void:
	SoundManager.play_ui_button()
	_settings_scroll_touch_index = -1
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _settings_scroll_touch_blocks_scroll(global_pos: Vector2) -> bool:
	## Не перехватывать жест, если палец на слайдере/списке/чекбоксе — иначе будет конфликт с их drag.
	for c in [
		_difficulty,
		_music_slider,
		_sfx_slider,
		_ui_slider,
		_dialogue_slider,
		_dialogue_text_scale_slider,
		_perf_option,
		_auto_fit_phone_check,
		_ui_scale_slider,
		_touch_scale,
		_touch_opacity,
	]:
		if c != null and is_instance_valid(c) and c.visible and c.get_global_rect().has_point(global_pos):
			return true
	return false


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventScreenDrag:
		if _scroll and _settings_scroll_touch_index >= 0:
			var sd := event as InputEventScreenDrag
			if sd.index == _settings_scroll_touch_index:
				_scroll.scroll_vertical -= int(sd.relative.y)
				get_viewport().set_input_as_handled()
		return
	if event is InputEventScreenTouch:
		if _scroll:
			var st := event as InputEventScreenTouch
			if st.pressed:
				if _scroll.get_global_rect().has_point(st.position):
					if _settings_scroll_touch_blocks_scroll(st.position):
						_settings_scroll_touch_index = -1
					else:
						_settings_scroll_touch_index = st.index
				else:
					_settings_scroll_touch_index = -1
			elif st.index == _settings_scroll_touch_index:
				_settings_scroll_touch_index = -1
		return


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		_on_back_pressed()
		get_viewport().set_input_as_handled()
