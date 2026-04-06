@tool
extends "res://ui/HUD/game_hud.gd"
## В редакторе HUD скрыт (не отвлекает от сцены); в игре включается в _ready.

@export var teleport_menu: Control
@export var castle_menu: Control
@export var barracks_menu: Control
@export var monastery_menu: Control
@export var archery_menu: Control
@export var payshop_menu: Control
@export var squad_orders_menu: Control
@export var debug_menu: Control
@export var camp_codex_panel: Control
@export var camp_codex_open_button: Button

var _codex_badge: TextureRect
var _armor_hud_root: Control
var _armor_hud_label: Label
## SLIPPER (TASK-016): реже обновлять процент брони — не критичный индикатор относительно HP.
var _slipper_armor_hud_refresh_timer: Timer
var _ui_scale_base_rects: Dictionary = {}
var _ui_scale_cached: bool = false

const _TOP_HUD_BAR_PATH := "TopHudBar"
const _TOP_HUD_SEP_BASE := 8
const _TOP_HUD_OFF_L := 16.0
const _TOP_HUD_OFF_R := -16.0
## Верхняя полоса HUD (высота полосы = OFF_BOT − OFF_TOP).
const _TOP_HUD_OFF_TOP := -6.0
const _TOP_HUD_OFF_BOT := 78.0
const _TOP_HUD_EVEN_GAP_COUNT := 7
## Сумма custom_minimum_size.x по TopHudBar (tscn) + 7 зазоров по 8 px — минимальная ширина ряда при scale=1.
## Нельзя масштабировать дочерние Control по отдельности: HBox раскладывает по несжатым размерам, визуал вылезает за слоты.
const _TOP_HUD_ROW_MIN_WIDTH := 1248.0


func _set_tree_paused(p: bool) -> void:
	## На Wayland/Aurora при сбоях GLES или во время смены сцены `get_tree()` может быть null — без проверки падение в `paused`.
	var st := get_tree()
	if st:
		st.paused = p


func _connect_top_hud_resize_for_pivot() -> void:
	var bar := get_node_or_null(_TOP_HUD_BAR_PATH) as Control
	if bar == null:
		return
	if bar.resized.is_connected(_on_top_hud_bar_resized):
		return
	bar.resized.connect(_on_top_hud_bar_resized)


func _on_top_hud_bar_resized() -> void:
	## Масштаб от центра: при смене ширины полосы обновляем pivot, иначе полоса «уезжает» в сторону.
	if Engine.is_editor_hint():
		return
	var bar := get_node_or_null(_TOP_HUD_BAR_PATH) as Control
	if bar == null:
		return
	_update_top_hud_pivot_to_center(bar)


func _update_top_hud_pivot_to_center(bar: Control) -> void:
	var w := bar.size.x
	var h := bar.size.y
	if w < 2.0 or h < 2.0:
		var cms := bar.get_combined_minimum_size()
		if w < 2.0:
			w = maxf(cms.x, _TOP_HUD_ROW_MIN_WIDTH)
		if h < 2.0:
			h = maxf(cms.y, 1.0)
	bar.pivot_offset = Vector2(w * 0.5, h * 0.5)


func set_target_location(location: Events.LOCATION) -> void:
	if teleport_menu and teleport_menu.has_method("set_target_location"):
		teleport_menu.call("set_target_location", location)


func _on_button_pressed() -> void:
	GameManager.defer_location_changed(Events.LOCATION.MENU)


func _on_codex_button_pressed() -> void:
	SoundManager.play_ui_button()
	show_camp_codex_menu()


func _ready() -> void:
	visible = not Engine.is_editor_hint()
	## @tool: в редакторе автозагрузки — placeholder без методов/сигналов; не трогаем SaveManager, Events, DialogueManager.
	if Engine.is_editor_hint():
		return
	var vp := get_viewport()
	if vp and not vp.size_changed.is_connected(_on_viewport_size_changed_hud_scale):
		vp.size_changed.connect(_on_viewport_size_changed_hud_scale)
	set_process_input(true)
	_slipper_armor_hud_refresh_timer = Timer.new()
	_slipper_armor_hud_refresh_timer.one_shot = true
	_slipper_armor_hud_refresh_timer.wait_time = 0.12
	_slipper_armor_hud_refresh_timer.timeout.connect(_on_slipper_armor_hud_debounce_timeout)
	add_child(_slipper_armor_hud_refresh_timer)
	if teleport_menu:
		teleport_menu.hide()
	if debug_menu:
		debug_menu.hide()
	if camp_codex_open_button:
		camp_codex_open_button.pressed.connect(_on_codex_button_pressed)
		if not camp_codex_open_button.resized.is_connected(_on_codex_open_button_resized):
			camp_codex_open_button.resized.connect(_on_codex_open_button_resized)
		_setup_codex_badge()
	Events.location_changed.connect(_on_location_changed_codex_button)
	Events.location_changed.connect(_on_location_changed_armor_hud)
	Events.armor_durability_changed.connect(_on_armor_hud_data_changed)
	_on_location_changed_codex_button(Events.current_location)
	DialogueManager.dialogue_ended.connect(_on_any_dialogue_ended_for_badge)
	_setup_armor_hud_nodes()
	_refresh_armor_hud()
	_cache_ui_scale_base_rects_if_needed()
	_connect_top_hud_resize_for_pivot()
	apply_user_ui_scale()


func _on_viewport_size_changed_hud_scale() -> void:
	apply_user_ui_scale()


func _setup_codex_badge() -> void:
	if camp_codex_open_button == null:
		return
	_codex_badge = TextureRect.new()
	_codex_badge.texture = CodexNewMarker.get_badge_texture()
	_codex_badge.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_codex_badge.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_codex_badge.custom_minimum_size = Vector2(20, 24)
	_codex_badge.size = Vector2(20, 24)
	_codex_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_codex_badge.visible = false
	camp_codex_open_button.add_child(_codex_badge)
	_position_codex_badge()
	_update_codex_badge()


func _position_codex_badge() -> void:
	if _codex_badge == null or camp_codex_open_button == null:
		return
	_codex_badge.position = Vector2(maxi(4.0, camp_codex_open_button.size.x - 22.0), 4.0)


func _on_codex_open_button_resized() -> void:
	_position_codex_badge()


func _update_codex_badge() -> void:
	if Engine.is_editor_hint():
		return
	if _codex_badge == null:
		return
	_codex_badge.visible = SaveManager.has_unseen_codex_content()


func _on_any_dialogue_ended_for_badge(_seq: Variant) -> void:
	call_deferred("_update_codex_badge")


func _on_location_changed_codex_button(_loc: Events.LOCATION) -> void:
	if camp_codex_open_button == null:
		return
	## В главном меню с героем у сундука — кодекс нужен, чтобы читать письмо из «Предметы».
	if (
		Events.current_location == Events.LOCATION.MENU
		and GameManager.current_scene_player != null
		and is_instance_valid(GameManager.current_scene_player)
	):
		camp_codex_open_button.visible = true
		return
	camp_codex_open_button.visible = Events.current_location != Events.LOCATION.MENU


## Меню после финала: скрыть верхнюю полосу (HP, ресурсы, телепорт); тач и кнопка кодекса остаются.
func apply_epilogue_menu_minimal_top_hud() -> void:
	if Engine.is_editor_hint():
		return
	if Events.current_location != Events.LOCATION.MENU:
		return
	if GameManager.current_scene_player == null or not is_instance_valid(GameManager.current_scene_player):
		return
	var bar := get_node_or_null(_TOP_HUD_BAR_PATH) as Control
	if bar == null:
		return
	bar.visible = true
	for child in bar.get_children():
		if child == camp_codex_open_button:
			if child is Control:
				(child as Control).visible = true
		elif child is Control:
			(child as Control).visible = false


func _setup_armor_hud_nodes() -> void:
	_armor_hud_root = get_node_or_null("TopHudBar/ArmorDurabilityHud") as Control
	_armor_hud_label = get_node_or_null("TopHudBar/ArmorDurabilityHud/ArmorPctLabel") as Label


func _armor_hud_should_show() -> bool:
	## Броня нужна на базе и на всех островах; в главном меню скрываем.
	return Events.current_location != Events.LOCATION.MENU


func _refresh_armor_hud() -> void:
	var show_armor := _armor_hud_should_show()
	if _armor_hud_root:
		_armor_hud_root.visible = show_armor
	if not show_armor:
		return
	if _armor_hud_label:
		var dur := CrownSystem.get_armor_durability()
		var pct := int(round(float(dur) / float(BalanceConfig.ARMOR_MAX_DURABILITY) * 100.0))
		var c: Color
		if dur <= BalanceConfig.ARMOR_CRITICAL_THRESHOLD:
			c = Color(0.95, 0.3, 0.3)
		elif dur <= BalanceConfig.ARMOR_WORN_THRESHOLD:
			c = Color(0.95, 0.7, 0.25)
		else:
			## Светлый стальной (не зелёный): на типичном тёмном HUD зелёный 0.55/0.8/0.55 почти теряется.
			c = Color(0.82, 0.9, 0.98)
		_armor_hud_label.add_theme_color_override("font_color", c)
		_armor_hud_label.text = "%d%%" % pct


func _cache_ui_scale_base_rects_if_needed() -> void:
	if _ui_scale_cached:
		return
	for p in [
		"TopHudBar/hp_bar",
		"TopHudBar/ArmorDurabilityHud",
		"TopHudBar/Gold",
		"TopHudBar/OreCounter",
		"TopHudBar/MeatCounter",
		"TopHudBar/WoodCounter",
		"TopHudBar/Button",
		"TopHudBar/CodexOpenButton",
	]:
		var c := get_node_or_null(p) as Control
		if c == null:
			continue
		var sz: Vector2 = c.size
		if sz.x < 1.0 or sz.y < 1.0:
			sz = c.get_combined_minimum_size()
		_ui_scale_base_rects[p] = {
			"position": c.position,
			"size": sz,
			"pivot": c.pivot_offset,
		}
	_ui_scale_cached = true


func _hud_skip_manual_position_size(c: Control) -> bool:
	if c == null:
		return false
	if camp_codex_open_button != null and c == camp_codex_open_button:
		return true
	var p := c.get_parent()
	return p != null and p.name == _TOP_HUD_BAR_PATH


func _apply_top_hud_bar_margins() -> void:
	var bar := get_node_or_null(_TOP_HUD_BAR_PATH) as HBoxContainer
	if bar == null:
		return
	bar.add_theme_constant_override("separation", 0)
	## Отступы в логических координатах; итоговый визуальный масштаб — только `TopHudBar.scale` (см. apply_user_ui_scale).
	bar.offset_left = _TOP_HUD_OFF_L
	bar.offset_right = _TOP_HUD_OFF_R
	bar.offset_top = _TOP_HUD_OFF_TOP
	bar.offset_bottom = _TOP_HUD_OFF_BOT
	var gap_w := float(_TOP_HUD_SEP_BASE)
	for i in range(_TOP_HUD_EVEN_GAP_COUNT):
		var g := bar.get_node_or_null("HudEvenGap%d" % i) as Control
		if g:
			g.custom_minimum_size.x = gap_w


func apply_user_ui_scale() -> void:
	_cache_ui_scale_base_rects_if_needed()
	_apply_top_hud_bar_margins()
	var bar := get_node_or_null(_TOP_HUD_BAR_PATH) as Control
	if bar:
		bar.scale = Vector2.ONE
		bar.pivot_offset = Vector2.ZERO
	for p in _ui_scale_base_rects.keys():
		var c := get_node_or_null(str(p)) as Control
		if c == null:
			continue
		var d: Dictionary = _ui_scale_base_rects[p]
		var base_size := d.get("size", Vector2.ZERO) as Vector2
		if not _hud_skip_manual_position_size(c):
			var base_pos := d.get("position", Vector2.ZERO) as Vector2
			c.position = base_pos
			c.size = base_size
		var pivot_sz := base_size
		if _hud_skip_manual_position_size(c) and c.size.x > 0.5 and c.size.y > 0.5:
			pivot_sz = c.size
		c.pivot_offset = pivot_sz * 0.5
		c.scale = Vector2.ONE
	## После раскладки HBox: min_width по факту (лейблы/цифры шире минимума) + pivot по центру, иначе scale тянет всё к левому краю.
	call_deferred("_deferred_apply_top_hud_scale_and_pivot")
	if is_instance_valid(castle_menu) and castle_menu.has_method("refit_slipper_castle_layout"):
		castle_menu.refit_slipper_castle_layout()


func _viewport_width_px_safe(bar: Control) -> float:
	## `get_viewport()` у CanvasLayer иногда null в отложенном кадре — сначала вьюпорт с `Control` полосы HUD.
	var vp := bar.get_viewport()
	if vp == null:
		vp = get_viewport()
	if vp == null and is_inside_tree():
		var r := get_tree().root
		if r is Viewport:
			vp = r as Viewport
	if vp != null:
		return vp.get_visible_rect().size.x
	var ws := DisplayServer.window_get_size()
	if ws.x > 0:
		return float(ws.x)
	return float(ProjectSettings.get_setting("display/window/size/viewport_width", 1280))


func _deferred_apply_top_hud_scale_and_pivot() -> void:
	if Engine.is_editor_hint():
		return
	var bar := get_node_or_null(_TOP_HUD_BAR_PATH) as Control
	if bar == null:
		return
	var s := clampf(float(SaveManager.ui_scale_percent) / 100.0, 0.75, 1.3)
	var cms := bar.get_combined_minimum_size()
	var min_w := maxf(_TOP_HUD_ROW_MIN_WIDTH, cms.x)
	var vw := _viewport_width_px_safe(bar)
	if Events.current_location != Events.LOCATION.MENU:
		var inner := maxf(0.0, vw - _TOP_HUD_OFF_L - abs(_TOP_HUD_OFF_R))
		if inner > 1.0 and min_w > 0.001:
			s = minf(s, inner / min_w)
	_update_top_hud_pivot_to_center(bar)
	bar.scale = Vector2(s, s)


func _on_location_changed_armor_hud(_loc: Events.LOCATION) -> void:
	if _slipper_armor_hud_refresh_timer != null and is_instance_valid(_slipper_armor_hud_refresh_timer):
		_slipper_armor_hud_refresh_timer.stop()
	_refresh_armor_hud()


func _on_slipper_armor_hud_debounce_timeout() -> void:
	_refresh_armor_hud()


func _on_armor_hud_data_changed(_value: int) -> void:
	if PerformancePreset.is_slipper_mode(SaveManager):
		if _slipper_armor_hud_refresh_timer != null and is_instance_valid(_slipper_armor_hud_refresh_timer):
			_slipper_armor_hud_refresh_timer.start()
		return
	_refresh_armor_hud()


func _suppress_camp_codex_for_other_modal() -> void:
	if camp_codex_panel and camp_codex_panel.visible:
		camp_codex_panel.visible = false


func _input(event: InputEvent) -> void:
	if get_viewport() == null:
		return
	if CrownTitlePreview.visible and event.is_action_pressed("ui_cancel"):
		CrownTitlePreview.hide_preview()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("toggle_debug_menu"):
		if debug_menu == null:
			return
		if debug_menu.visible:
			hide_debug_menu()
		else:
			show_debug_menu()
		get_viewport().set_input_as_handled()
		return
	if debug_menu != null and debug_menu.visible and event.is_action_pressed("ui_cancel"):
		hide_debug_menu()
		get_viewport().set_input_as_handled()
		return
	if teleport_menu.visible:
		if event.is_action_pressed("ui_cancel"):
			hide_teleport_menu()
			get_viewport().set_input_as_handled()
		return
	if barracks_menu != null and barracks_menu.visible and event.is_action_pressed("ui_cancel"):
		hide_barracks_menu()
		get_viewport().set_input_as_handled()
		return
	if monastery_menu != null and monastery_menu.visible and event.is_action_pressed("ui_cancel"):
		hide_monastery_menu()
		get_viewport().set_input_as_handled()
		return
	if archery_menu != null and archery_menu.visible and event.is_action_pressed("ui_cancel"):
		hide_archery_menu()
		get_viewport().set_input_as_handled()
		return
	if payshop_menu != null and payshop_menu.visible and event.is_action_pressed("ui_cancel"):
		hide_payshop_menu()
		get_viewport().set_input_as_handled()
		return
	if squad_orders_menu != null and squad_orders_menu.visible and event.is_action_pressed("ui_cancel"):
		if squad_orders_menu.has_method("close"):
			squad_orders_menu.close()
		get_viewport().set_input_as_handled()
		return
	if camp_codex_panel != null and camp_codex_panel.visible and event.is_action_pressed("ui_cancel"):
		if camp_codex_panel.has_method("try_handle_back") and camp_codex_panel.try_handle_back():
			get_viewport().set_input_as_handled()
			return
		hide_camp_codex_menu()
		get_viewport().set_input_as_handled()
		return
	if castle_menu != null and castle_menu.visible and event.is_action_pressed("ui_cancel"):
		if castle_menu.has_method("try_close_crown_mood_effects_modal") and castle_menu.try_close_crown_mood_effects_modal():
			get_viewport().set_input_as_handled()
			return
		if castle_menu.has_method("try_close_hire_submenu") and castle_menu.try_close_hire_submenu():
			get_viewport().set_input_as_handled()
			return
		hide_castle_menu()
		get_viewport().set_input_as_handled()


func show_teleport_menu():
	if teleport_menu.visible:
		return
	if debug_menu and debug_menu.visible:
		hide_debug_menu()
	if squad_orders_menu and squad_orders_menu.visible and squad_orders_menu.has_method("close"):
		squad_orders_menu.close()
	_suppress_camp_codex_for_other_modal()
	if barracks_menu:
		barracks_menu.hide()
	if monastery_menu:
		monastery_menu.hide()
	if archery_menu:
		archery_menu.hide()
	if payshop_menu:
		payshop_menu.hide()
	if castle_menu:
		castle_menu.hide()
	SoundManager.play_menu_open()
	teleport_menu.show()
	_set_tree_paused(true)


func hide_teleport_menu():
	if not teleport_menu.visible:
		return
	SoundManager.play_menu_close()
	teleport_menu.hide()
	_set_tree_paused(false)


func teleport_to(location: Events.LOCATION):
	if location == Events.current_location:
		return
	if not GameManager.can_teleport_to_location(location):
		return
	if teleport_menu.visible:
		hide_teleport_menu()
	else:
		_set_tree_paused(false)
	RainSystem.register_teleport_use()
	GameManager.defer_location_changed(location)


func show_castle_menu():
	SoundManager.play_menu_open()
	if debug_menu and debug_menu.visible:
		hide_debug_menu()
	if squad_orders_menu and squad_orders_menu.visible and squad_orders_menu.has_method("close"):
		squad_orders_menu.close()
	_suppress_camp_codex_for_other_modal()
	if barracks_menu:
		barracks_menu.hide()
	if monastery_menu:
		monastery_menu.hide()
	if archery_menu:
		archery_menu.hide()
	if payshop_menu:
		payshop_menu.hide()
	if castle_menu == null:
		return
	if castle_menu.has_method("reset_castle_menu_state"):
		castle_menu.reset_castle_menu_state()
	castle_menu.show()
	_set_tree_paused(true)


func hide_castle_menu():
	SoundManager.play_menu_close()
	if castle_menu == null:
		return
	castle_menu.hide()
	_set_tree_paused(false)


func show_barracks_menu():
	if teleport_menu and teleport_menu.visible:
		hide_teleport_menu()
	SoundManager.play_menu_open()
	if debug_menu and debug_menu.visible:
		hide_debug_menu()
	if squad_orders_menu and squad_orders_menu.visible and squad_orders_menu.has_method("close"):
		squad_orders_menu.close()
	_suppress_camp_codex_for_other_modal()
	if castle_menu:
		castle_menu.hide()
	if monastery_menu:
		monastery_menu.hide()
	if archery_menu:
		archery_menu.hide()
	if payshop_menu:
		payshop_menu.hide()
	if barracks_menu == null:
		return
	if barracks_menu.has_method("reset_barracks_menu_state"):
		barracks_menu.reset_barracks_menu_state()
	barracks_menu.show()
	_set_tree_paused(true)


func hide_barracks_menu():
	SoundManager.play_menu_close()
	if barracks_menu == null:
		return
	barracks_menu.hide()
	_set_tree_paused(false)


func show_monastery_menu():
	if teleport_menu and teleport_menu.visible:
		hide_teleport_menu()
	SoundManager.play_menu_open()
	if debug_menu and debug_menu.visible:
		hide_debug_menu()
	if squad_orders_menu and squad_orders_menu.visible and squad_orders_menu.has_method("close"):
		squad_orders_menu.close()
	_suppress_camp_codex_for_other_modal()
	if castle_menu:
		castle_menu.hide()
	if barracks_menu:
		barracks_menu.hide()
	if archery_menu:
		archery_menu.hide()
	if payshop_menu:
		payshop_menu.hide()
	if monastery_menu == null:
		return
	if monastery_menu.has_method("reset_monastery_menu_state"):
		monastery_menu.reset_monastery_menu_state()
	monastery_menu.show()
	_set_tree_paused(true)


func hide_monastery_menu():
	SoundManager.play_menu_close()
	if monastery_menu == null:
		return
	monastery_menu.hide()
	_set_tree_paused(false)


func show_archery_menu():
	if teleport_menu and teleport_menu.visible:
		hide_teleport_menu()
	SoundManager.play_menu_open()
	if debug_menu and debug_menu.visible:
		hide_debug_menu()
	if squad_orders_menu and squad_orders_menu.visible and squad_orders_menu.has_method("close"):
		squad_orders_menu.close()
	_suppress_camp_codex_for_other_modal()
	if castle_menu:
		castle_menu.hide()
	if barracks_menu:
		barracks_menu.hide()
	if monastery_menu:
		monastery_menu.hide()
	if payshop_menu:
		payshop_menu.hide()
	if archery_menu == null:
		return
	if archery_menu.has_method("reset_archery_menu_state"):
		archery_menu.reset_archery_menu_state()
	archery_menu.show()
	_set_tree_paused(true)


func hide_archery_menu():
	SoundManager.play_menu_close()
	if archery_menu == null:
		return
	archery_menu.hide()
	_set_tree_paused(false)


func show_payshop_menu():
	if teleport_menu and teleport_menu.visible:
		hide_teleport_menu()
	SoundManager.play_menu_open()
	if debug_menu and debug_menu.visible:
		hide_debug_menu()
	if squad_orders_menu and squad_orders_menu.visible and squad_orders_menu.has_method("close"):
		squad_orders_menu.close()
	_suppress_camp_codex_for_other_modal()
	if castle_menu:
		castle_menu.hide()
	if barracks_menu:
		barracks_menu.hide()
	if monastery_menu:
		monastery_menu.hide()
	if archery_menu:
		archery_menu.hide()
	if payshop_menu == null:
		return
	if payshop_menu.has_method("reset_payshop_menu_state"):
		payshop_menu.reset_payshop_menu_state()
	payshop_menu.show()
	_set_tree_paused(true)


func hide_payshop_menu():
	SoundManager.play_menu_close()
	if payshop_menu == null:
		return
	payshop_menu.hide()
	_set_tree_paused(false)


func show_camp_codex_menu() -> void:
	if DialogueManager.is_active():
		return
	if ChestLootUi.is_chest_popup_open():
		return
	SoundManager.play_menu_open()
	if debug_menu and debug_menu.visible:
		hide_debug_menu()
	if squad_orders_menu and squad_orders_menu.visible and squad_orders_menu.has_method("close"):
		squad_orders_menu.close()
	if teleport_menu and teleport_menu.visible:
		hide_teleport_menu()
	if castle_menu:
		castle_menu.hide()
	if barracks_menu:
		barracks_menu.hide()
	if monastery_menu:
		monastery_menu.hide()
	if archery_menu:
		archery_menu.hide()
	if payshop_menu:
		payshop_menu.hide()
	if camp_codex_panel == null:
		return
	if camp_codex_panel.has_method("prepare_on_open"):
		camp_codex_panel.prepare_on_open()
	camp_codex_panel.visible = true
	_set_tree_paused(true)


## Открывает кодекс лагеря на вкладке «Справка» и прокручивает к карточке с указанным заголовком (как в CampCodexGlossary).
func show_camp_codex_menu_at_help_entry(entry_title: String) -> void:
	if DialogueManager.is_active():
		return
	if ChestLootUi.is_chest_popup_open():
		return
	SoundManager.play_menu_open()
	if debug_menu and debug_menu.visible:
		hide_debug_menu()
	if squad_orders_menu and squad_orders_menu.visible and squad_orders_menu.has_method("close"):
		squad_orders_menu.close()
	if teleport_menu and teleport_menu.visible:
		hide_teleport_menu()
	if castle_menu:
		castle_menu.hide()
	if barracks_menu:
		barracks_menu.hide()
	if monastery_menu:
		monastery_menu.hide()
	if archery_menu:
		archery_menu.hide()
	if payshop_menu:
		payshop_menu.hide()
	if camp_codex_panel == null:
		return
	if camp_codex_panel.has_method("prepare_on_open"):
		camp_codex_panel.prepare_on_open(entry_title)
	camp_codex_panel.visible = true
	_set_tree_paused(true)


func hide_camp_codex_menu() -> void:
	SoundManager.play_menu_close()
	if camp_codex_panel == null:
		return
	camp_codex_panel.visible = false
	_set_tree_paused(false)
	_update_codex_badge()


func try_open_squad_orders_menu(unit: Node2D) -> bool:
	if DialogueManager.is_active():
		return false
	if SquadCombatState.is_engaged():
		return false
	if unit == null or not is_instance_valid(unit):
		return false
	if unit.has_method("is_pawn_in_ore_mine") and unit.is_pawn_in_ore_mine():
		return false
	if squad_orders_menu == null or not squad_orders_menu.has_method("open_for"):
		return false
	if squad_orders_menu.visible:
		return false
	if teleport_menu and teleport_menu.visible:
		return false
	if barracks_menu and barracks_menu.visible:
		return false
	if monastery_menu and monastery_menu.visible:
		return false
	if archery_menu and archery_menu.visible:
		return false
	if payshop_menu and payshop_menu.visible:
		return false
	if castle_menu and castle_menu.visible:
		return false
	if camp_codex_panel and camp_codex_panel.visible:
		return false
	if debug_menu and debug_menu.visible:
		return false
	squad_orders_menu.open_for(unit)
	return true


func show_debug_menu() -> void:
	if debug_menu == null or debug_menu.visible:
		return
	if squad_orders_menu and squad_orders_menu.visible and squad_orders_menu.has_method("close"):
		squad_orders_menu.close()
	if barracks_menu and barracks_menu.visible:
		hide_barracks_menu()
	if castle_menu and castle_menu.visible:
		hide_castle_menu()
	if payshop_menu and payshop_menu.visible:
		hide_payshop_menu()
	if camp_codex_panel and camp_codex_panel.visible:
		hide_camp_codex_menu()
	if teleport_menu and teleport_menu.visible:
		hide_teleport_menu()
	SoundManager.play_menu_open()
	debug_menu.show()
	_set_tree_paused(true)


func hide_debug_menu() -> void:
	if debug_menu == null or not debug_menu.visible:
		return
	SoundManager.play_menu_close()
	debug_menu.hide()
	_set_tree_paused(false)
