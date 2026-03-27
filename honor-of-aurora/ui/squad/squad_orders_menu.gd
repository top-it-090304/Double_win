extends Control
## Два шага: реплика бойца → «Далее» → реплика героя и нумерованный выбор (как диалог с монахом).

const NAME_FONT_SIZE := 14
const NAME_FONT_COLOR := Color(1, 1, 1, 1)
const TEXT_FONT_SIZE := 22
const TEXT_FONT_COLOR := Color(1, 1, 1, 1)
const NAME_FONT_MIN := 8
const TEXT_FONT_MIN := 8
const TEXT_MEASURE_HEIGHT_TRIM := 2.0
const CHROME_OFFSET_TOP_MIN := -180.0
const CHROME_OFFSET_TOP_MAX := -320.0
const CHROME_OFFSET_BOTTOM := -16.0
const CHROME_EXTRA_PX_PER_CHOICE := 28.0

const TEX_ARCHER := preload("res://Asets/Unit_pack/UI Elements/UI Elements/Human Avatars/Avatars_03.png")
const TEX_LANCER := preload("res://Asets/Unit_pack/UI Elements/UI Elements/Human Avatars/Avatars_02.png")
const TEX_PAWN := preload("res://Asets/Unit_pack/UI Elements/UI Elements/Human Avatars/Avatars_05.png")
const TEX_HERO := preload("res://Asets/Unit_pack/UI Elements/UI Elements/Human Avatars/aa_player.png")

@onready var _dialogue_chrome: Control = $DialogueChrome
@onready var _face: TextureRect = $DialogueChrome/PanelRoot/MarginMain/VBox/Row/LeftCol/FaceFrame/face
@onready var _name_label: Label = $DialogueChrome/PanelRoot/MarginMain/VBox/Row/LeftCol/Name
@onready var _text_label: Label = $DialogueChrome/PanelRoot/MarginMain/VBox/Row/text
@onready var _close_btn: Button = $DialogueChrome/PanelRoot/MarginMain/VBox/ContinueHBox/CloseButton
@onready var _continue_btn: Button = $DialogueChrome/PanelRoot/MarginMain/VBox/ContinueHBox/ContinueButton
@onready var _choices_scroll: ScrollContainer = $DialogueChrome/PanelRoot/MarginMain/VBox/ChoicesScroll
@onready var _choices_vbox: VBoxContainer = $DialogueChrome/PanelRoot/MarginMain/VBox/ChoicesScroll/ChoicesVBox

const PATROL_BANTER_COOLDOWN_SEC := 10.0

var _context_unit: Node2D = null
## 0 — приветствие бойца; 1 — приказы героя; 2 — ответ солдата после выбора вопроса в меню (пара из SquadPatrolBanter).
var _stage: int = 0
## Время (сек, по Time.get_ticks_msec), когда снова можно взять новый случайный вопрос солдату.
var _patrol_banter_available_at: float = 0.0
var _banter_cooldown_timer: Timer = null


func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process_input(true)
	_apply_label_theme()
	_close_btn.pressed.connect(close)
	_continue_btn.pressed.connect(_on_continue_pressed)
	_setup_banter_cooldown_timer()
	_apply_choices_scroll_style()
	_apply_dialogue_chrome_height(0)


func _apply_label_theme() -> void:
	if _name_label:
		_name_label.add_theme_font_size_override("font_size", NAME_FONT_SIZE)
		_name_label.add_theme_color_override("font_color", NAME_FONT_COLOR)
		_name_label.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	if _text_label:
		_text_label.add_theme_font_size_override("font_size", TEXT_FONT_SIZE)
		_text_label.add_theme_color_override("font_color", TEXT_FONT_COLOR)
		_text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_text_label.clip_text = true


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()


func open_for(unit: Node2D) -> void:
	if unit == null or not is_instance_valid(unit):
		return
	if DialogueManager.is_active():
		return
	if SquadCombatState.is_engaged():
		return
	_context_unit = unit
	_stage = 0
	_show_squad_greeting_stage()
	SoundManager.play_menu_open()
	visible = true
	get_tree().paused = true
	MobileVirtualInput.clear_input()


func close() -> void:
	if not visible:
		return
	_stop_banter_cooldown_timer()
	_clear_choice_buttons()
	SoundManager.play_menu_close()
	visible = false
	_context_unit = null
	_stage = 0
	_apply_dialogue_chrome_height(0)
	# Кнопки «Далее»/закрытие часто на ЛКМ = действие attack; без сброса на следующем кадре снова сработает удар/меню.
	Input.action_release("attack")
	MobileVirtualInput.clear_input()
	Events.squad_orders_menu_closed.emit()
	get_tree().paused = false


func _show_squad_greeting_stage() -> void:
	var u := _context_unit
	_clear_choice_buttons()
	_choices_scroll.visible = false
	_apply_dialogue_chrome_height(0)
	_continue_btn.visible = true
	_face.texture = _portrait_for_unit(u)
	_face.visible = true
	_name_label.text = _squad_speaker_title(u)
	if u != null and u.is_in_group("story_youth_companion"):
		_text_label.text = "Слушаю, милорд. Где нужна кирка — у шахты, у дерева или у стада? Я готов."
	elif u != null and u.is_in_group("ally_pawn"):
		_text_label.text = "Слушаю, милорд. Где нужна кирка — у шахты, у дерева или у стада?"
	else:
		_text_label.text = "Какие указания, милорд?"
	call_deferred("_deferred_fit_labels")


func _show_hero_orders_stage() -> void:
	_clear_choice_buttons()
	_face.texture = TEX_HERO
	_face.visible = true
	_name_label.text = "Рыцарь"
	if _context_unit != null and _context_unit.is_in_group("story_youth_companion"):
		_text_label.text = "Что поручить юноше?"
	elif _context_unit != null and _context_unit.is_in_group("ally_pawn"):
		_text_label.text = "Что поручить рабочему?"
	else:
		_text_label.text = "Что прикажете отряду?"
	_continue_btn.visible = false
	_choices_scroll.visible = true
	_build_order_choice_buttons()
	_apply_dialogue_chrome_height(_choices_vbox.get_child_count())
	call_deferred("_deferred_fit_labels")


func _deferred_fit_labels() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	_fit_name_font()
	_fit_dialogue_text_font()


func _portrait_for_unit(u: Node2D) -> Texture2D:
	if u.is_in_group("ally_archer"):
		return TEX_ARCHER
	if u.is_in_group("ally_lancer"):
		return TEX_LANCER
	if u.is_in_group("story_youth_companion"):
		return TEX_PAWN
	if u.is_in_group("ally_pawn"):
		return TEX_PAWN
	return TEX_LANCER


func _squad_speaker_title(u: Node2D) -> String:
	if u.is_in_group("ally_archer"):
		return "Лучник"
	if u.is_in_group("ally_lancer"):
		return "Копейщик"
	if u.is_in_group("story_youth_companion"):
		return "Юноша"
	if u.is_in_group("ally_pawn"):
		return "Рабочий"
	return "Союзник"


func _on_continue_pressed() -> void:
	if _stage == 0:
		SoundManager.play_dialogue_advance()
		_stage = 1
		_show_hero_orders_stage()
	elif _stage == 2:
		SoundManager.play_dialogue_advance()
		_patrol_banter_available_at = Time.get_ticks_msec() / 1000.0 + PATROL_BANTER_COOLDOWN_SEC
		_stage = 1
		_show_hero_orders_stage()


func _clear_choice_buttons() -> void:
	for c in _choices_vbox.get_children():
		c.queue_free()
	_apply_dialogue_chrome_height(0)


func _build_order_choice_buttons() -> void:
	_clear_choice_buttons()
	var u := _context_unit
	if u != null and u.is_in_group("ally_pawn"):
		_build_pawn_worker_choice_buttons()
		return
	var idx := 1
	var at_base := Events.current_location == Events.LOCATION.BASE
	var patrolling := at_base and SquadOrders.mode == SquadOrders.Mode.PATROL
	if not patrolling:
		_stop_banter_cooldown_timer()
	if patrolling:
		idx = _add_choice_btn(idx, "Продолжить патрулирование", _apply_continue_patrol_close)
		var now: float = Time.get_ticks_msec() / 1000.0
		if now < _patrol_banter_available_at:
			_start_banter_cooldown_timer()
		else:
			_stop_banter_cooldown_timer()
			var ex: Dictionary = SquadPatrolBanter.pick_exchange()
			var q_label: String = SquadPatrolBanter.format_question_for_choice_button(str(ex.get("q", "…")), 140)
			var answer: String = str(ex.get("a", "…"))
			idx = _add_choice_btn(idx, q_label, func(): _apply_patrol_banter_answer(answer))
	idx = _add_choice_btn(idx, "Стоять", _apply_hold)
	if at_base and not patrolling:
		idx = _add_choice_btn(idx, "Патрулировать", _apply_patrol)
	idx = _add_choice_btn(idx, "Готовиться к бою", _apply_combat)
	if _should_show_healer_button():
		idx = _add_choice_btn(idx, "Сходить к целителю", _apply_healer)


func _build_pawn_worker_choice_buttons() -> void:
	var idx := 1
	var at_base := Events.current_location == Events.LOCATION.BASE
	var patrolling := at_base and SquadOrders.mode == SquadOrders.Mode.PATROL
	if not patrolling:
		_stop_banter_cooldown_timer()
	if patrolling:
		idx = _add_choice_btn(idx, "Продолжить работу", _apply_continue_patrol_close)
		var now: float = Time.get_ticks_msec() / 1000.0
		if now < _patrol_banter_available_at:
			_start_banter_cooldown_timer()
		else:
			_stop_banter_cooldown_timer()
			var ex: Dictionary = WorkerPatrolBanter.pick_exchange()
			var q_label: String = WorkerPatrolBanter.format_question_for_choice_button(str(ex.get("q", "…")), 140)
			var answer: String = str(ex.get("a", "…"))
			idx = _add_choice_btn(idx, q_label, func(): _apply_patrol_banter_answer(answer))
	if at_base and not patrolling:
		idx = _add_choice_btn(idx, "Патрулировать", _apply_patrol)
	if at_base:
		idx = _add_choice_btn(idx, "Добывать руду", _apply_pawn_job_ore)
		idx = _add_choice_btn(idx, "Добывать мясо", _apply_pawn_job_meat)
		idx = _add_choice_btn(idx, "Добывать дерево", _apply_pawn_job_wood)
	idx = _add_choice_btn(idx, "Не добывать ресурсы", _apply_pawn_job_none)
	if not at_base:
		idx = _add_choice_btn(idx, "Стоять", _apply_hold)
		idx = _add_choice_btn(idx, "Готовиться к бою", _apply_combat)


func _apply_pawn_job_none() -> void:
	var u := _context_unit
	if u != null and is_instance_valid(u) and u.has_method("set_worker_job_from_dialogue"):
		u.set_worker_job_from_dialogue("none")
	close()


func _apply_pawn_job_ore() -> void:
	var u := _context_unit
	if u != null and is_instance_valid(u) and u.has_method("set_worker_job_from_dialogue"):
		u.set_worker_job_from_dialogue("ore")
	SquadOrders.set_mode(SquadOrders.Mode.PATROL)
	close()


func _apply_pawn_job_meat() -> void:
	var u := _context_unit
	if u != null and is_instance_valid(u) and u.has_method("set_worker_job_from_dialogue"):
		u.set_worker_job_from_dialogue("meat")
	SquadOrders.set_mode(SquadOrders.Mode.PATROL)
	close()


func _apply_pawn_job_wood() -> void:
	var u := _context_unit
	if u != null and is_instance_valid(u) and u.has_method("set_worker_job_from_dialogue"):
		u.set_worker_job_from_dialogue("wood")
	SquadOrders.set_mode(SquadOrders.Mode.PATROL)
	close()


func _add_choice_btn(line_index: int, label: String, callback: Callable) -> int:
	var btn := Button.new()
	btn.text = "%d. %s" % [line_index, label]
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var captured := callback
	btn.pressed.connect(func() -> void:
		SoundManager.play_ui_button()
		captured.call()
	)
	_choices_vbox.add_child(btn)
	return line_index + 1


func _setup_banter_cooldown_timer() -> void:
	_banter_cooldown_timer = Timer.new()
	_banter_cooldown_timer.wait_time = 1.0
	_banter_cooldown_timer.one_shot = false
	add_child(_banter_cooldown_timer)
	_banter_cooldown_timer.timeout.connect(_on_banter_cooldown_tick)


func _start_banter_cooldown_timer() -> void:
	if _banter_cooldown_timer and not _banter_cooldown_timer.is_stopped():
		return
	if _banter_cooldown_timer:
		_banter_cooldown_timer.start()


func _stop_banter_cooldown_timer() -> void:
	if _banter_cooldown_timer:
		_banter_cooldown_timer.stop()


func _on_banter_cooldown_tick() -> void:
	if not visible or _stage != 1:
		_stop_banter_cooldown_timer()
		return
	var now: float = Time.get_ticks_msec() / 1000.0
	if now >= _patrol_banter_available_at:
		_stop_banter_cooldown_timer()
		_show_hero_orders_stage()


func _apply_choices_scroll_style() -> void:
	if _choices_scroll == null:
		return
	_choices_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_choices_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	var sb := _choices_scroll.get_v_scroll_bar()
	if sb == null:
		return
	sb.custom_minimum_size.x = 10
	var grab := StyleBoxFlat.new()
	grab.bg_color = Color(0.42, 0.45, 0.52, 0.88)
	grab.set_corner_radius_all(5)
	sb.add_theme_stylebox_override("grabber", grab)
	var grab_h := StyleBoxFlat.new()
	grab_h.bg_color = Color(0.52, 0.56, 0.64, 0.95)
	grab_h.set_corner_radius_all(5)
	sb.add_theme_stylebox_override("grabber_highlight", grab_h)
	var grab_p := StyleBoxFlat.new()
	grab_p.bg_color = Color(0.35, 0.38, 0.45, 0.95)
	grab_p.set_corner_radius_all(5)
	sb.add_theme_stylebox_override("grabber_pressed", grab_p)
	var track := StyleBoxFlat.new()
	track.bg_color = Color(0.12, 0.13, 0.16, 0.65)
	track.set_corner_radius_all(5)
	sb.add_theme_stylebox_override("scroll", track)


func _should_show_healer_button() -> bool:
	var unit := _context_unit
	if unit == null or not is_instance_valid(unit):
		return false
	if Events.current_location != Events.LOCATION.BASE:
		return false
	if not unit.is_in_group("ally_archer"):
		return false
	if not unit.has_method("is_health_full"):
		return false
	if unit.is_health_full():
		return false
	return true


func _apply_continue_patrol_close() -> void:
	close()


func _apply_patrol_banter_answer(answer: String) -> void:
	_stage = 2
	_clear_choice_buttons()
	_continue_btn.visible = true
	_choices_scroll.visible = false
	_apply_dialogue_chrome_height(0)
	var u := _context_unit
	if u and is_instance_valid(u):
		_face.texture = _portrait_for_unit(u)
		_name_label.text = _squad_speaker_title(u)
	else:
		_face.texture = TEX_LANCER
		_name_label.text = "Солдат"
	_face.visible = true
	_text_label.text = answer
	call_deferred("_deferred_fit_labels")


func _apply_dialogue_chrome_height(choice_count: int) -> void:
	if _dialogue_chrome == null:
		return
	var span: float = absf(CHROME_OFFSET_TOP_MAX - CHROME_OFFSET_TOP_MIN)
	var extra: float = 0.0
	if choice_count > 0:
		extra = minf(span, float(choice_count) * CHROME_EXTRA_PX_PER_CHOICE)
	_dialogue_chrome.offset_top = CHROME_OFFSET_TOP_MIN - extra
	_dialogue_chrome.offset_bottom = CHROME_OFFSET_BOTTOM


func _apply_hold() -> void:
	SquadOrders.set_mode(SquadOrders.Mode.HOLD)
	close()


func _apply_patrol() -> void:
	SquadOrders.set_mode(SquadOrders.Mode.PATROL)
	close()


func _apply_combat() -> void:
	SquadOrders.set_mode(SquadOrders.Mode.COMBAT)
	close()


func _apply_healer() -> void:
	if _context_unit and is_instance_valid(_context_unit) and _context_unit.has_method("squad_order_go_to_healer"):
		_context_unit.squad_order_go_to_healer()
	close()


func _font_for_label(label: Label) -> Font:
	var f: Font = label.get_theme_font("font")
	return f if f != null else ThemeDB.fallback_font


func _text_max_width() -> float:
	return maxf(_text_label.size.x, 8.0)


func _text_max_height() -> float:
	return maxf(_text_label.size.y - TEXT_MEASURE_HEIGHT_TRIM, 1.0)


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
	_fit_font_to_label(_name_label, _name_label.text, NAME_FONT_SIZE, NAME_FONT_MIN)


func _fit_dialogue_text_font() -> void:
	if _text_label == null:
		return
	_fit_font_to_label(_text_label, _text_label.text, TEXT_FONT_SIZE, TEXT_FONT_MIN)
