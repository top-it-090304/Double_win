extends Control

const _BarracksQuotes := preload("res://ui/casle_minu/barracks/barracks_quotes.gd")

var _armor_wear_block: PanelContainer
var _armor_status_prefix: Label
var _armor_status_pct: Label
var _armor_penalty_label: Label
var _armor_repair_btn: Button
var _armor_repair_cost_label: Label
var _supply_status_label: Label


func get_hud() -> Node:
	return GameplayFacade.get_hud(get_tree())


## Тот же силуэт, что у `barracks_back_btn` / нижних кнопок меню (StyleBoxFlat_menu_btn*).
func _armor_row_button_style(state: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.set_border_width_all(1)
	s.set_corner_radius_all(8.0)
	s.content_margin_left = 12.0
	s.content_margin_top = 5.0
	s.content_margin_right = 12.0
	s.content_margin_bottom = 5.0
	match state:
		1:
			s.bg_color = Color(0.2, 0.24, 0.33, 1)
			s.border_color = Color(0.45, 0.55, 0.68, 0.95)
			s.shadow_color = Color(0, 0, 0, 0.3)
			s.shadow_size = 5
			s.shadow_offset = Vector2(0, 2)
		2:
			s.bg_color = Color(0.11, 0.13, 0.18, 1)
			s.border_color = Color(0.25, 0.3, 0.4, 1)
			s.shadow_color = Color(0, 0, 0, 0.25)
			s.shadow_size = 4
			s.shadow_offset = Vector2(0, 2)
		_:
			s.bg_color = Color(0.16, 0.19, 0.26, 0.96)
			s.border_color = Color(0.32, 0.4, 0.52, 0.9)
			s.shadow_color = Color(0, 0, 0, 0.25)
			s.shadow_size = 4
			s.shadow_offset = Vector2(0, 2)
	return s


func _durability_theme_color(color_hex: String) -> Color:
	return Color("#" + color_hex)


func _ready() -> void:
	Events.gold_changed.connect(_on_resources_changed)
	Events.ore_changed.connect(_on_resources_changed)
	Events.armor_durability_changed.connect(_on_armor_changed)
	Events.crown_displeasure_changed.connect(_on_crown_changed)
	Events.crown_favor_changed.connect(_on_crown_changed)
	_build_armor_repair_ui()
	_refresh_quote()
	_refresh_buttons()


func _exit_tree() -> void:
	if Events.gold_changed.is_connected(_on_resources_changed):
		Events.gold_changed.disconnect(_on_resources_changed)
	if Events.ore_changed.is_connected(_on_resources_changed):
		Events.ore_changed.disconnect(_on_resources_changed)
	if Events.armor_durability_changed.is_connected(_on_armor_changed):
		Events.armor_durability_changed.disconnect(_on_armor_changed)
	if Events.crown_displeasure_changed.is_connected(_on_crown_changed):
		Events.crown_displeasure_changed.disconnect(_on_crown_changed)
	if Events.crown_favor_changed.is_connected(_on_crown_changed):
		Events.crown_favor_changed.disconnect(_on_crown_changed)


func _on_resources_changed(_value: int) -> void:
	if visible:
		_refresh_buttons()


func _on_armor_changed(_d: int) -> void:
	if visible:
		_refresh_buttons()


func _on_crown_changed(_level: int) -> void:
	if visible:
		_refresh_buttons()


func reset_barracks_menu_state() -> void:
	_refresh_quote()
	_refresh_buttons()


func _refresh_quote() -> void:
	var lbl := get_node_or_null("BarracksPanel/BodyVBox/BarracksSubtitle") as Label
	if lbl:
		lbl.text = _BarracksQuotes.pick_next()


func _refresh_buttons() -> void:
	const SLOT_SWORD := "BarracksPanel/BodyVBox/SlotsRow/slot_sword/ColumnSword/"
	const SLOT_SHIELD := "BarracksPanel/BodyVBox/SlotsRow/slot_shield/ColumnShield/"
	var sword := get_node_or_null(SLOT_SWORD + "BtnSharpenSword") as Button
	var shield := get_node_or_null(SLOT_SHIELD + "BtnRepairShield") as Button
	var sword_desc := get_node_or_null(SLOT_SWORD + "SwordBuffDesc") as Label
	var shield_desc := get_node_or_null(SLOT_SHIELD + "ShieldBuffDesc") as Label

	var dmg: int = GameManager.get_armory_sword_buff_damage_preview()
	var sword_cost: int = GameManager.get_armory_sword_buff_cost()
	if sword_desc:
		sword_desc.text = "+%d к урону атаки" % dmg
	if sword:
		sword.text = str(sword_cost)

	var shield_delta_pct: float = GameManager.get_armory_shield_buff_delta_ratio() * 100.0
	if shield_desc:
		shield_desc.text = "+%.1f%% к блоку" % shield_delta_pct

	var shield_cost: int = GameManager.get_armory_shield_buff_cost()
	if shield:
		shield.text = str(shield_cost)

	var can_sword := SaveManager.gold >= sword_cost and not GameManager.armory_sword_prepared
	var can_shield := SaveManager.gold >= shield_cost and not GameManager.armory_shield_prepared
	PaidServiceButtonAppearance.set_interactive(sword, can_sword)
	PaidServiceButtonAppearance.set_interactive(shield, can_shield)

	_refresh_armor_repair_section()
	_refresh_supply_status()


func _build_armor_repair_ui() -> void:
	var body := get_node_or_null("BarracksPanel/BodyVBox") as VBoxContainer
	if body == null:
		return

	var section := VBoxContainer.new()
	section.name = "ArmorRepairSection"
	section.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	section.clip_contents = true
	section.add_theme_constant_override("separation", 3)
	body.add_child(section)

	var divider := ColorRect.new()
	divider.custom_minimum_size = Vector2(0, 1)
	divider.color = Color(0.28, 0.35, 0.46, 0.55)
	divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
	section.add_child(divider)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	section.add_child(row)

	_armor_wear_block = PanelContainer.new()
	_armor_wear_block.add_theme_stylebox_override("panel", _armor_row_button_style(0))
	_armor_wear_block.custom_minimum_size = Vector2(0, 28)
	_armor_wear_block.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_armor_wear_block.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(_armor_wear_block)

	var wear_row := HBoxContainer.new()
	wear_row.add_theme_constant_override("separation", 6)
	wear_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_armor_wear_block.add_child(wear_row)

	_armor_status_prefix = Label.new()
	_armor_status_prefix.text = "Снаряжение:"
	_armor_status_prefix.add_theme_font_size_override("font_size", 20)
	_armor_status_prefix.add_theme_color_override("font_color", Color(0.78, 0.82, 0.9, 0.95))
	wear_row.add_child(_armor_status_prefix)

	_armor_status_pct = Label.new()
	_armor_status_pct.add_theme_font_size_override("font_size", 20)
	wear_row.add_child(_armor_status_pct)

	_armor_penalty_label = Label.new()
	_armor_penalty_label.add_theme_font_size_override("font_size", 16)
	_armor_penalty_label.add_theme_color_override("font_color", Color(0.72, 0.76, 0.82, 0.85))
	wear_row.add_child(_armor_penalty_label)

	_armor_repair_cost_label = Label.new()
	_armor_repair_cost_label.add_theme_color_override("font_color", Color(0.72, 0.76, 0.82, 0.82))
	_armor_repair_cost_label.add_theme_font_size_override("font_size", 18)
	row.add_child(_armor_repair_cost_label)

	_armor_repair_btn = Button.new()
	_armor_repair_btn.custom_minimum_size = Vector2(132, 30)
	_armor_repair_btn.add_theme_font_size_override("font_size", 22)
	_armor_repair_btn.add_theme_color_override("font_color", Color(0.98, 0.95, 0.88, 1))
	_armor_repair_btn.add_theme_stylebox_override("normal", _armor_row_button_style(0))
	_armor_repair_btn.add_theme_stylebox_override("hover", _armor_row_button_style(1))
	_armor_repair_btn.add_theme_stylebox_override("pressed", _armor_row_button_style(2))
	_armor_repair_btn.add_theme_stylebox_override("disabled", _armor_row_button_style(0))
	_armor_repair_btn.pressed.connect(_on_repair_armor_pressed)
	row.add_child(_armor_repair_btn)

	_supply_status_label = Label.new()
	_supply_status_label.add_theme_color_override("font_color", Color(0.72, 0.76, 0.82, 0.75))
	_supply_status_label.add_theme_font_size_override("font_size", 16)
	_supply_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	section.add_child(_supply_status_label)


func _refresh_armor_repair_section() -> void:
	if _armor_status_pct == null:
		return
	var dur := CrownSystem.get_armor_durability()
	var max_dur := BalanceConfig.ARMOR_MAX_DURABILITY
	var pct := int(round(float(dur) / float(max_dur) * 100.0))

	var color_hex: String
	if dur <= BalanceConfig.ARMOR_CRITICAL_THRESHOLD:
		color_hex = "ff4444"
	elif dur <= BalanceConfig.ARMOR_WORN_THRESHOLD:
		color_hex = "ffaa33"
	else:
		color_hex = "88cc88"

	_armor_status_pct.text = "%d%%" % pct
	_armor_status_pct.add_theme_color_override("font_color", _durability_theme_color(color_hex))

	var penalty := CrownSystem.get_armor_block_penalty()
	if penalty > 0.001:
		_armor_penalty_label.text = "  (блок +%.0f%% урона)" % (penalty * 100.0)
	else:
		_armor_penalty_label.text = ""

	var cost := CrownSystem.get_armor_repair_cost()
	var g: int = int(cost.get("gold", 0))
	var o: int = int(cost.get("ore", 0))

	if dur >= max_dur:
		_armor_repair_btn.text = "В порядке"
		_armor_repair_btn.disabled = true
		_armor_repair_cost_label.text = ""
	else:
		_armor_repair_btn.text = "Починить"
		_armor_repair_cost_label.text = "%d зол. + %d руды" % [g, o]
		_armor_repair_btn.disabled = not GameplayFacade.can_afford_gold_plus_ore(g, o)


func _refresh_supply_status() -> void:
	if _supply_status_label == null:
		return
	var d := SaveManager.crown_displeasure
	var f := SaveManager.crown_favor
	if d > 0:
		var texts: Array[String] = [
			"Немилость I — снабжение урезано",
			"Немилость II — снабжение сильно урезано",
			"Немилость III — критический дефицит",
		]
		_supply_status_label.text = texts[clampi(d - 1, 0, 2)]
		_supply_status_label.add_theme_color_override("font_color", Color(0.9, 0.5, 0.4, 0.85))
	elif f > 0:
		var texts: Array[String] = [
			"Одобрение I — улучшенное снабжение",
			"Одобрение II — усиленное снабжение",
			"Одобрение III — элитное снабжение",
		]
		_supply_status_label.text = texts[clampi(f - 1, 0, 2)]
		_supply_status_label.add_theme_color_override("font_color", Color(0.5, 0.85, 0.6, 0.85))
	else:
		_supply_status_label.text = "Снабжение: стандартное"
		_supply_status_label.add_theme_color_override("font_color", Color(0.72, 0.76, 0.82, 0.65))


func _on_back_pressed() -> void:
	SoundManager.play_ui_button()
	var hud := get_hud()
	if hud == null or not hud.has_method("hide_barracks_menu"):
		return
	hud.hide_barracks_menu()


func _on_sharpen_sword_pressed() -> void:
	SoundManager.play_ui_button()
	if not GameManager.try_prepare_armory_sword():
		return
	_refresh_buttons()


func _on_repair_shield_pressed() -> void:
	SoundManager.play_ui_button()
	if not GameManager.try_prepare_armory_shield():
		return
	_refresh_buttons()


func _on_repair_armor_pressed() -> void:
	SoundManager.play_ui_button()
	if not CrownSystem.try_repair_armor():
		return
	_refresh_buttons()
