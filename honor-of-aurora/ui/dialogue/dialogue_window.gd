extends Control

const NAME_FONT_MIN := 8
const TEXT_FONT_MIN := 8
const TEXT_MEASURE_HEIGHT_TRIM := 2.0
## После открытия диалога тем же кликом, что был «атакой», UI успевает нажать первую кнопку — кратко игнорируем мышь.
const CHOICE_MOUSE_ARM_DELAY_SEC := 0.12
## Минимальная высота строки варианта (компактнее — больше пунктов в видимой области скролла).
const CHOICE_BUTTON_MIN_HEIGHT := 32
## Минимальная ширина под именем; фактическая ширина колонки = max(это, ширина строки имени). Портрет не растягивается (как у целителя).
const NAME_LABEL_MIN_WIDTH := 72.0
const NAME_LABEL_WIDTH_PAD_PX := 10.0
## Высота полосы диалога: якорь снизу, offset_top отрицательный — чем меньше, тем выше панель.
const CHROME_OFFSET_TOP_MIN := -180.0
## Нижняя граница offset_top (ещё выше панель) — больше |разница| = больший запас под варианты без скролла.
const CHROME_OFFSET_TOP_MAX := -400.0
const CHROME_OFFSET_BOTTOM := -16.0
## Базовый шаг роста панели на вариант (если контент ниже — берётся высота по кнопкам).
const CHROME_EXTRA_PX_PER_CHOICE := 28.0
## Совпадает с separation у ChoicesVBox в dialogue_window.tscn.
const CHOICE_VBOX_SEP := 6
## Запас под рамку ScrollPad и обводку кнопок.
const CHOICE_SCROLL_PAD_PX := 12.0
## Сколько вариантов ответа «растят» высоту окна; при большем числе панель не удлиняется — лишние пункты в скролле списка.
const MAX_CHOICE_COUNT_FOR_WINDOW_EXPAND := 3
## Жёсткий потолок высоты одной «страницы» при разбиении (пиксели). Раньше max_h завышался (растянутый Label,
## fallback 11% viewport, min width 240) → весь абзац в одном элементе _text_pages → «Далее» = advance_line().
const TEXT_PAGE_HEIGHT_BUDGET_MAX := 96.0
## Базовая высота колонки текста рядом с портретом (мини-высота строки до расширения).
const REPLICA_TEXT_ROW_BASELINE_H := 72.0
## Максимум дополнительного роста панели вверх (|offset_top|) под длинную реплику.
const CHROME_DYN_EXPAND_MAX_PX := 420.0
## Отступ под обводку/хвосты букв при расчёте высоты блока текста.
const REPLICA_TEXT_PAD_PX := 12.0

const TEX_HEALER := preload("res://Asets/Unit_pack/UI Elements/UI Elements/Human Avatars/aa_healler.png")
const TEX_PLAYER := preload("res://Asets/Unit_pack/UI Elements/UI Elements/Human Avatars/aa_player.png")
## Тот же аватар, что у рабочего в меню отряда (squad_orders_menu TEX_PAWN).
const TEX_WORKER := preload("res://Asets/Unit_pack/UI Elements/UI Elements/Human Avatars/Avatars_05.png")
const TEX_VETERAN := preload("res://Asets/Unit_pack/UI Elements/UI Elements/Human Avatars/Avatars_08.png")
## Портрет интенданта (speaker_id caravan); в окне — отражение по X.
const TEX_INTENDANT := preload("res://Asets/Unit_pack/Units/моряк.png")

const SPEAKER_LABELS := {
	"healer": "Целитель",
	"hero": "Рыцарь",
	"pawn_worker": "Рабочий",
	"young_worker": "Мирон",
	"narrator": "Повествование",
	"letter": "Письмо",
	"veteran": "Бран",
	"caravan": "Интендант",
}

const SPEAKER_FACES := {
	"healer": TEX_HEALER,
	"hero": TEX_PLAYER,
	"pawn_worker": TEX_WORKER,
	"young_worker": TEX_WORKER,
	"veteran": TEX_VETERAN,
	"caravan": TEX_INTENDANT,
}

## Горизонтальное отражение портрета (лицо смотрит в сторону текста).
const SPEAKER_FACE_FLIP_H := {
	"caravan": true,
}

@onready var _dialogue_chrome: Control = $DialogueChrome
@onready var _face_frame: PanelContainer = $DialogueChrome/PanelRoot/MarginMain/VBox/ContentVBox/Row/LeftCol/FaceFrame
@onready var _face: TextureRect = $DialogueChrome/PanelRoot/MarginMain/VBox/ContentVBox/Row/LeftCol/FaceFrame/face
@onready var _name_label: Label = $DialogueChrome/PanelRoot/MarginMain/VBox/ContentVBox/Row/LeftCol/Name
@onready var _text_label: Label = $DialogueChrome/PanelRoot/MarginMain/VBox/ContentVBox/Row/text
@onready var _close_btn: Button = $DialogueChrome/PanelRoot/MarginMain/VBox/ContinueHBox/CloseButton
@onready var _continue_btn: Button = $DialogueChrome/PanelRoot/MarginMain/VBox/ContinueHBox/ContinueButton
@onready var _choices_scroll: ScrollContainer = $DialogueChrome/PanelRoot/MarginMain/VBox/ContentVBox/ChoicesScroll
@onready var _choices_vbox: VBoxContainer = $DialogueChrome/PanelRoot/MarginMain/VBox/ContentVBox/ChoicesScroll/ScrollPad/ChoicesVBox

var _text_pages: PackedStringArray = []
var _text_page_index: int = 0
var _choice_buttons: Array[Button] = []
## Касание, начатое в области списка вариантов (при emulate_mouse_from_touch=false дочерние Button не отдают drag в ScrollContainer).
var _choice_scroll_touch_index: int = -1
## Сбрасывается при новой строке и при dialogue_ended — чтобы await в _on_line_changed не продолжался без дерева / устаревшим.
var _line_change_epoch: int = 0
## Дополнительный рост DialogueChrome вверх (px), чтобы в колонке поместилась вся реплика по метрикам шрифта.
var _chrome_dyn_extra_px: float = 0.0


func _dialogue_layout_scale() -> float:
	return clampf(float(SaveManager.dialogue_text_scale_percent) / 100.0, 0.75, 1.3)


func _scaled_choice_btn_min_h() -> int:
	return maxi(28, int(round(float(CHOICE_BUTTON_MIN_HEIGHT) * _dialogue_layout_scale())))


func _refresh_dialogue_visual_scale() -> void:
	_apply_label_theme()
	_apply_chrome_button_fonts()
	_sync_face_frame_size()


func _apply_chrome_button_fonts() -> void:
	var fs: int = maxi(14, int(round(16.0 * _dialogue_layout_scale())))
	if _continue_btn:
		_continue_btn.add_theme_font_size_override("font_size", fs)
	if _close_btn:
		_close_btn.add_theme_font_size_override("font_size", fs)


func _sync_face_frame_size() -> void:
	if _face_frame == null:
		return
	var wh: int = maxi(56, int(round(72.0 * _dialogue_layout_scale())))
	_face_frame.custom_minimum_size = Vector2(wh, wh)


func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process_input(true)
	if _continue_btn:
		_continue_btn.pressed.connect(_on_continue_pressed)
	if _close_btn:
		_close_btn.pressed.connect(_force_close_dialogue)
	if _face_frame == null or _face == null or _name_label == null or _text_label == null or _choices_scroll == null or _choices_vbox == null:
		push_error("DialogueWindow: не найдены узлы FaceFrame / face / Name / text / ChoicesScroll / ChoicesVBox под ContentVBox — проверьте дерево сцены.")
	## Рамка портрета 72×72 не растягивается; портрет и подпись по центру колонки — общая вертикальная ось.
	if _face_frame:
		_face_frame.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	if _choices_scroll:
		_choices_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		_choices_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_refresh_dialogue_visual_scale()
	_apply_dialogue_chrome_height(0)
	DialogueManager.dialogue_started.connect(_on_dialogue_started)
	DialogueManager.line_changed.connect(_on_line_changed)
	DialogueManager.dialogue_ended.connect(_on_dialogue_ended)


func _exit_tree() -> void:
	_line_change_epoch += 1
	## Сцена с HUD уничтожена, а DialogueManager — autoload: без сброса await в _on_line_changed падает с data.tree null и остаётся is_active().
	if DialogueManager.is_active():
		DialogueManager.end_dialogue()


func _apply_label_theme() -> void:
	if _name_label == null or _text_label == null:
		return
	_name_label.add_theme_font_size_override("font_size", DialogueUiConstants.get_name_font_size())
	_name_label.add_theme_color_override("font_color", DialogueUiConstants.NAME_FONT_COLOR)
	_name_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	_name_label.clip_text = false
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_label.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_text_label.add_theme_font_size_override("font_size", DialogueUiConstants.get_text_font_size())
	_text_label.add_theme_color_override("font_color", DialogueUiConstants.TEXT_FONT_COLOR)
	_text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text_label.clip_text = true
	_text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	## Сверху: нижние строки страницы предсказуемо у нижней границы видимой области (не «центр» при clip).
	_text_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP


func _reset_chrome_dynamic_expand() -> void:
	_chrome_dyn_extra_px = 0.0
	if _text_label:
		_text_label.custom_minimum_size = Vector2.ZERO


func _choice_area_min_height(choice_count: int) -> float:
	if choice_count <= 0:
		return 0.0
	return float(choice_count) * float(_scaled_choice_btn_min_h()) + float(max(0, choice_count - 1)) * float(CHOICE_VBOX_SEP) + CHOICE_SCROLL_PAD_PX * _dialogue_layout_scale()


func _choice_count_for_window_height(choice_count: int) -> int:
	return clampi(choice_count, 0, MAX_CHOICE_COUNT_FOR_WINDOW_EXPAND)


func _apply_dialogue_chrome_height(choice_count: int) -> void:
	if _dialogue_chrome == null:
		return
	var span: float = absf(CHROME_OFFSET_TOP_MAX - CHROME_OFFSET_TOP_MIN)
	var extra: float = 0.0
	if choice_count > 0:
		var n: int = _choice_count_for_window_height(choice_count)
		var linear_extra: float = float(n) * CHROME_EXTRA_PX_PER_CHOICE * _dialogue_layout_scale()
		var content_extra: float = _choice_area_min_height(n)
		## Раньше только linear_extra (2×28=56) — меньше реальной высоты двух кнопок (32+6+32), появлялся скролл.
		## n ограничен сверху — при 4+ вариантах окно не растёт бесконечно, лишнее листается в ScrollContainer.
		extra = minf(span, maxf(linear_extra, content_extra))
	_dialogue_chrome.offset_top = CHROME_OFFSET_TOP_MIN - extra - _chrome_dyn_extra_px
	_dialogue_chrome.offset_bottom = CHROME_OFFSET_BOTTOM


func _normalize_dialogue_plain(full_text: String) -> String:
	var t: String = full_text.strip_edges().replace("\n", " ")
	while t.contains("  "):
		t = t.replace("  ", " ")
	return t


## Подбирает высоту панели и custom_minimum_size текста по всей строке реплики, чтобы layout выделил место (иначе Label остаётся «нулевым» при росте только offset).
func _apply_replica_window_for_full_line_text(full_text: String, choice_count: int) -> void:
	if _text_label == null:
		return
	var t: String = _normalize_dialogue_plain(full_text)
	if t.is_empty():
		_reset_chrome_dynamic_expand()
		_apply_dialogue_chrome_height(choice_count)
		return
	var font: Font = _font_for_label(_text_label)
	var max_w: float = maxf(_pagination_max_width(), 48.0)
	var vp_h: float = 800.0
	var vp: Viewport = get_viewport()
	if vp:
		vp_h = vp.get_visible_rect().size.y
	## Не даём блоку текста съесть весь экран — при необходимости уменьшаем кегль до умещения.
	var scl: float = _dialogue_layout_scale()
	var max_block_h: float = clampf(vp_h * 0.42, 140.0 * scl, 520.0 * scl)
	var fs: int = DialogueUiConstants.get_text_font_size()
	var sz: Vector2
	while fs >= TEXT_FONT_MIN:
		sz = font.get_multiline_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, max_w, fs, -1)
		if float(sz.y) <= max_block_h + 1.0:
			break
		fs -= 1
	_text_label.add_theme_font_size_override("font_size", fs)
	var text_h: float = ceilf(float(sz.y)) + REPLICA_TEXT_PAD_PX * scl
	_text_label.custom_minimum_size = Vector2(0, text_h)
	var baseline: float = REPLICA_TEXT_ROW_BASELINE_H * scl
	var delta: float = maxf(0.0, text_h - baseline)
	_chrome_dyn_extra_px = minf(delta, CHROME_DYN_EXPAND_MAX_PX * scl)
	_apply_dialogue_chrome_height(choice_count)


func _input(event: InputEvent) -> void:
	if not visible or not DialogueManager.is_active():
		return
	if event.is_action_pressed("ui_cancel"):
		_force_close_dialogue()
		get_viewport().set_input_as_handled()
		return
	if event is InputEventScreenDrag:
		if DialogueManager.is_current_line_choice() and _choices_scroll and _choices_scroll.visible:
			var sd := event as InputEventScreenDrag
			if sd.index == _choice_scroll_touch_index and _choice_scroll_touch_index >= 0:
				_choices_scroll.scroll_vertical -= int(sd.relative.y)
				get_viewport().set_input_as_handled()
		return
	if event is InputEventScreenTouch:
		if DialogueManager.is_current_line_choice() and _choices_scroll and _choices_scroll.visible:
			var st := event as InputEventScreenTouch
			if st.pressed:
				if _choices_scroll.get_global_rect().has_point(st.position):
					_choice_scroll_touch_index = st.index
				else:
					_choice_scroll_touch_index = -1
			else:
				if st.index == _choice_scroll_touch_index:
					_choice_scroll_touch_index = -1
		return


func _gui_input(event: InputEvent) -> void:
	if not visible or not DialogueManager.is_active():
		return
	if not _continue_btn.visible:
		return
	if event is InputEventScreenTouch:
		var st := event as InputEventScreenTouch
		if st.pressed:
			_advance_dialogue_or_page()
			accept_event()


func _on_continue_pressed() -> void:
	_advance_dialogue_or_page()


func _force_close_dialogue() -> void:
	if not DialogueManager.is_active():
		return
	SoundManager.play_ui_button()
	DialogueManager.end_dialogue()


func _refresh_continue_button() -> void:
	if _continue_btn == null:
		return
	if not DialogueManager.is_active():
		_continue_btn.visible = false
		if _close_btn:
			_close_btn.visible = false
		return
	if _close_btn:
		_close_btn.visible = true
	if DialogueManager.is_current_line_choice():
		## Есть ещё страница текста (достаточно size >= 2 и index не на последней).
		if _text_page_index + 1 < _text_pages.size():
			_continue_btn.visible = true
		else:
			_continue_btn.visible = false
	else:
		_continue_btn.visible = true


func _advance_dialogue_or_page() -> void:
	if DialogueManager.is_current_line_choice():
		if _text_page_index + 1 < _text_pages.size():
			SoundManager.play_dialogue_page_turn()
			_text_page_index += 1
			_text_label.text = _text_pages[_text_page_index]
			_fit_dialogue_text_font()
			_refresh_continue_button()
		return
	if _text_page_index + 1 < _text_pages.size():
		SoundManager.play_dialogue_page_turn()
		_text_page_index += 1
		_text_label.text = _text_pages[_text_page_index]
		_fit_dialogue_text_font()
		_refresh_continue_button()
		return
	DialogueManager.advance_line()


func _on_dialogue_started(_sequence: DialogueSequence) -> void:
	visible = true
	_refresh_dialogue_visual_scale()
	MobileVirtualInput.clear_input()


func _on_line_changed(line: DialogueLine, _index: int, _line_count: int) -> void:
	## До входа в дерево `get_tree()` в Godot 4 даёт ошибку (data.tree null), не null.
	if not is_inside_tree():
		return
	_line_change_epoch += 1
	var epoch := _line_change_epoch
	_refresh_dialogue_visual_scale()
	_reset_chrome_dynamic_expand()
	_clear_choice_ui()
	var sid: String = line.speaker_id
	var sid_key := sid.strip_edges().to_lower()
	_name_label.text = SPEAKER_LABELS.get(sid_key, sid.capitalize() if not sid.is_empty() else "?")
	_update_name_label_min_width_for_current_text()
	var face_key := sid_key
	var tex: Texture2D = SPEAKER_FACES.get(face_key, null)
	if tex:
		_face.texture = tex
		_face.flip_h = bool(SPEAKER_FACE_FLIP_H.get(face_key, false))
		_face.visible = true
	else:
		_face.texture = null
		_face.flip_h = false
		_face.visible = false

	if line is DialogueChoiceLine:
		var dcl := line as DialogueChoiceLine
		_choices_scroll.visible = true
		_choices_scroll.scroll_vertical = 0
		if not is_inside_tree():
			return
		var tree := get_tree()
		if tree == null:
			return
		await tree.process_frame
		if epoch != _line_change_epoch or not is_inside_tree():
			return
		await tree.process_frame
		if epoch != _line_change_epoch or not is_inside_tree():
			return
		_apply_replica_window_for_full_line_text(line.text, dcl.options.size())
		await tree.process_frame
		if epoch != _line_change_epoch or not is_inside_tree():
			return
		_text_pages = _build_text_pages(line.text)
		_text_page_index = 0
		_text_label.text = _text_pages[0] if not _text_pages.is_empty() else ""
		_fit_name_font()
		_fit_dialogue_text_font()
		_split_pages_if_still_overflow_after_fit(line.text)
		for i in dcl.options.size():
			var opt: DialogueChoiceOption = dcl.options[i]
			var btn := Button.new()
			btn.text = "%d. %s" % [i + 1, opt.label]
			btn.custom_minimum_size = Vector2(0, _scaled_choice_btn_min_h())
			btn.add_theme_font_size_override("font_size", DialogueUiConstants.get_choice_button_font_size())
			btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
			btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			btn.mouse_filter = Control.MOUSE_FILTER_IGNORE
			var captured: int = i
			btn.pressed.connect(func() -> void:
				SoundManager.play_ui_button()
				_clear_choice_ui()
				DialogueManager.pick_dialogue_choice(captured)
			)
			_choices_vbox.add_child(btn)
			_choice_buttons.append(btn)
		if _choices_scroll:
			_choices_scroll.custom_minimum_size = Vector2(0, _choice_area_min_height(_choice_count_for_window_height(dcl.options.size())))
		_refresh_continue_button()
		if epoch == _line_change_epoch and is_inside_tree():
			SoundManager.play_dialogue_speaker_blip(line.speaker_id)
		## process_always: таймер срабатывает даже при паузе дерева (диалог с pause_game).
		if not is_inside_tree():
			return
		tree = get_tree()
		if tree == null:
			return
		await tree.create_timer(CHOICE_MOUSE_ARM_DELAY_SEC, true, false, true).timeout
		if epoch != _line_change_epoch or not is_inside_tree():
			return
		for b in _choice_buttons:
			if is_instance_valid(b):
				b.mouse_filter = Control.MOUSE_FILTER_STOP
		return

	if not is_inside_tree():
		return
	var tree_nc := get_tree()
	if tree_nc == null:
		return
	await tree_nc.process_frame
	if epoch != _line_change_epoch or not is_inside_tree():
		return
	await tree_nc.process_frame
	if epoch != _line_change_epoch or not is_inside_tree():
		return
	_apply_replica_window_for_full_line_text(line.text, 0)
	await tree_nc.process_frame
	if epoch != _line_change_epoch or not is_inside_tree():
		return
	_fit_name_font()
	_text_pages = _build_text_pages(line.text)
	_text_page_index = 0
	_text_label.text = _text_pages[0] if not _text_pages.is_empty() else ""
	_fit_dialogue_text_font()
	_split_pages_if_still_overflow_after_fit(line.text)
	_refresh_continue_button()
	if epoch == _line_change_epoch and is_inside_tree():
		SoundManager.play_dialogue_speaker_blip(line.speaker_id)


func _clear_choice_ui() -> void:
	_choice_buttons.clear()
	_choice_scroll_touch_index = -1
	for c in _choices_vbox.get_children():
		c.queue_free()
	if _choices_scroll:
		_choices_scroll.visible = false
		_choices_scroll.scroll_vertical = 0
		_choices_scroll.custom_minimum_size = Vector2.ZERO


func _on_dialogue_ended(_sequence: DialogueSequence) -> void:
	_line_change_epoch += 1
	_clear_choice_ui()
	_reset_chrome_dynamic_expand()
	_apply_dialogue_chrome_height(0)
	visible = false
	_text_label.text = ""
	_name_label.text = ""
	_reset_name_label_min_width()
	_face.texture = null
	_face.flip_h = false
	_text_pages = []
	_text_page_index = 0
	_refresh_continue_button()


func _reset_name_label_min_width() -> void:
	if _name_label:
		_name_label.custom_minimum_size = Vector2(NAME_LABEL_MIN_WIDTH, 0)


func _update_name_label_min_width_for_current_text() -> void:
	if _name_label == null:
		return
	var t: String = _name_label.text
	if t.is_empty():
		_reset_name_label_min_width()
		return
	var font: Font = _font_for_label(_name_label)
	var fs: int = _name_label.get_theme_font_size("font_size")
	if fs <= 0:
		fs = DialogueUiConstants.get_name_font_size()
	var sz: Vector2 = font.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
	var w: float = maxf(NAME_LABEL_MIN_WIDTH, float(sz.x) + NAME_LABEL_WIDTH_PAD_PX)
	_name_label.custom_minimum_size = Vector2(w, 0)


func _font_for_label(label: Label) -> Font:
	var f: Font = label.get_theme_font("font")
	return f if f != null else ThemeDB.fallback_font


func _pagination_max_width() -> float:
	var w: float = _text_label.size.x
	if w < 48.0:
		var row: Control = _text_label.get_parent() as Control
		if row:
			w = row.size.x
	if w < 48.0:
		var vp: Viewport = get_viewport()
		if vp:
			w = vp.get_visible_rect().size.x * 0.5
	return maxf(w, 48.0)


## Бюджет высоты для одной страницы. Если уже задан custom_minimum_size под полную реплику — используем его (иначе снова режет на ~96 px).
func _pagination_page_height_budget() -> float:
	if _text_label != null and _text_label.custom_minimum_size.y > 1.0:
		return maxf(_text_label.custom_minimum_size.y - TEXT_MEASURE_HEIGHT_TRIM, float(DialogueUiConstants.get_text_font_size()) * 1.6)
	var h: float = _text_label.size.y - TEXT_MEASURE_HEIGHT_TRIM
	if h < 32.0:
		h = 96.0
	var budget: float = minf(h, TEXT_PAGE_HEIGHT_BUDGET_MAX * _dialogue_layout_scale())
	return maxf(budget, float(DialogueUiConstants.get_text_font_size()) * 1.6)


func _label_effective_size(label: Label) -> Vector2:
	var s: Vector2 = label.size
	return Vector2(maxf(s.x, 4.0), maxf(s.y, 4.0))


func _fit_font_to_label(label: Label, text: String, max_fs: int, min_fs: int) -> void:
	if label == null:
		return
	if text.is_empty():
		label.add_theme_font_size_override("font_size", max_fs)
		return
	var font: Font = _font_for_label(label)
	var dim: Vector2 = _label_effective_size(label)
	var max_w: float = maxf(dim.x, 4.0)
	var max_h: float = maxf(dim.y, float(min_fs))
	var chosen: int = min_fs
	var fs: int = max_fs
	while fs >= min_fs:
		var sz: Vector2 = font.get_multiline_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, max_w, fs, -1)
		if float(sz.y) <= max_h + 1.0:
			chosen = fs
			break
		fs -= 1
	label.add_theme_font_size_override("font_size", chosen)


func _fit_name_font() -> void:
	if _name_label == null:
		return
	_name_label.visible = true
	_name_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	_fit_font_to_label(_name_label, _name_label.text, DialogueUiConstants.get_name_font_size(), NAME_FONT_MIN)
	_update_name_label_min_width_for_current_text()


func _fit_dialogue_text_font() -> void:
	if _text_label == null:
		return
	_fit_font_to_label(_text_label, _text_label.text, DialogueUiConstants.get_text_font_size(), TEXT_FONT_MIN)


func _build_text_pages(full_text: String) -> PackedStringArray:
	var t: String = full_text.strip_edges().replace("\n", " ")
	while t.contains("  "):
		t = t.replace("  ", " ")
	if t.is_empty():
		return PackedStringArray([""])
	var font: Font = _font_for_label(_text_label)
	var max_w: float = maxf(_pagination_max_width(), 8.0)
	var page_budget: float = _pagination_page_height_budget()
	var fs: int = DialogueUiConstants.get_text_font_size()
	## Сравниваем с тем же max_w/fs, что и _take_text_page.
	var full_h: float = _text_block_height(t, font, fs, max_w)
	if full_h <= page_budget + 1.0:
		return PackedStringArray([t])
	var pages: Array[String] = []
	var rest: String = t
	while not rest.is_empty():
		var page: String = _take_text_page(rest, font, fs, max_w, page_budget)
		if page.is_empty():
			page = rest.substr(0, 1)
		pages.append(page)
		rest = rest.substr(page.length()).strip_edges()
	return PackedStringArray(pages)


## Если после подгонки шрифта блок всё ещё выше лейбла — режем страницу (редкий расхождение метрик Label vs Font).
func _split_pages_if_still_overflow_after_fit(full_text: String) -> void:
	var t: String = full_text.strip_edges().replace("\n", " ")
	while t.contains("  "):
		t = t.replace("  ", " ")
	if t.is_empty() or _text_pages.is_empty():
		return
	if _text_pages.size() != 1:
		return
	if _text_pages[0] != t:
		return
	var font: Font = _font_for_label(_text_label)
	var fs: int = _text_label.get_theme_font_size("font_size")
	var max_w: float = maxf(_label_effective_size(_text_label).x, 48.0)
	var dim_h: float = _label_effective_size(_text_label).y
	var sz: Vector2 = font.get_multiline_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, max_w, fs, -1)
	if float(sz.y) <= dim_h + 2.0:
		return
	var tight_h: float = maxf(dim_h - TEXT_MEASURE_HEIGHT_TRIM, float(fs) * 2.0)
	tight_h = minf(tight_h, TEXT_PAGE_HEIGHT_BUDGET_MAX * _dialogue_layout_scale())
	var pages: Array[String] = []
	var rest: String = t
	while not rest.is_empty():
		var page: String = _take_text_page(rest, font, fs, max_w, tight_h)
		if page.is_empty():
			page = rest.substr(0, 1)
		pages.append(page)
		rest = rest.substr(page.length()).strip_edges()
	if pages.size() <= 1:
		return
	_text_pages = PackedStringArray(pages)
	_text_page_index = 0
	_text_label.text = _text_pages[0]
	_fit_dialogue_text_font()


func _text_block_height(text: String, font: Font, font_size: int, max_width: float) -> float:
	if text.is_empty():
		return 0.0
	var sz: Vector2 = font.get_multiline_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, max_width, font_size, -1)
	return float(sz.y)


func _take_text_page(rest: String, font: Font, font_size: int, max_width: float, max_height: float) -> String:
	rest = rest.strip_edges()
	if rest.is_empty():
		return ""
	if _text_block_height(rest, font, font_size, max_width) <= max_height:
		return rest
	var words: PackedStringArray = rest.split(" ", false)
	if words.is_empty():
		return _take_by_chars(rest, font, font_size, max_width, max_height)
	var acc: String = ""
	for i in words.size():
		var w: String = words[i]
		var candidate: String = w if acc.is_empty() else acc + " " + w
		if _text_block_height(candidate, font, font_size, max_width) > max_height:
			if not acc.is_empty():
				return acc
			return _take_by_chars(w, font, font_size, max_width, max_height)
		acc = candidate
	return acc


func _take_by_chars(rest: String, font: Font, font_size: int, max_width: float, max_height: float) -> String:
	if rest.is_empty():
		return ""
	var lo: int = 1
	var hi: int = rest.length()
	var best: String = ""
	while lo <= hi:
		var mid: int = (lo + hi) >> 1
		var sub: String = rest.substr(0, mid)
		if _text_block_height(sub, font, font_size, max_width) <= max_height:
			best = sub
			lo = mid + 1
		else:
			hi = mid - 1
	if best.is_empty():
		return rest.substr(0, 1)
	return best
