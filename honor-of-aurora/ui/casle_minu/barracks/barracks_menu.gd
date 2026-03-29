extends Control

const _BarracksQuotes := preload("res://ui/casle_minu/barracks/barracks_quotes.gd")

var _armor_status_label: Label
var _armor_repair_btn: Button
var _armor_repair_cost_label: Label
var _supply_status_label: Label


func get_hud() -> Node:
	return GameplayFacade.get_hud(get_tree())


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
	var lbl := get_node_or_null("BarracksPanel/BarracksSubtitle") as Label
	if lbl:
		lbl.text = _BarracksQuotes.pick_next()


func _refresh_buttons() -> void:
	const SLOT_SWORD := "BarracksPanel/MainActions/SlotsRow/slot_sword/ColumnSword/"
	const SLOT_SHIELD := "BarracksPanel/MainActions/SlotsRow/slot_shield/ColumnShield/"
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

	var can_sword := (SaveManager.gold >= sword_cost or GameplayFacade.can_afford_gold_plus_ore(sword_cost, 0)) and not GameManager.armory_sword_prepared
	var can_shield := (SaveManager.gold >= shield_cost or GameplayFacade.can_afford_gold_plus_ore(shield_cost, 0)) and not GameManager.armory_shield_prepared
	if sword:
		sword.disabled = not can_sword
	if shield:
		shield.disabled = not can_shield

	_refresh_armor_repair_section()
	_refresh_supply_status()


func _build_armor_repair_ui() -> void:
	var panel := get_node_or_null("BarracksPanel") as Control
	if panel == null:
		return

	var section := VBoxContainer.new()
	section.name = "ArmorRepairSection"
	section.add_theme_constant_override("separation", 6)
	section.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	section.offset_top = -82.0
	section.offset_left = 32.0
	section.offset_right = -32.0
	section.offset_bottom = -6.0
	panel.add_child(section)

	var divider := ColorRect.new()
	divider.custom_minimum_size = Vector2(0, 1)
	divider.color = Color(0.28, 0.35, 0.46, 0.55)
	divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
	section.add_child(divider)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	section.add_child(row)

	_armor_status_label = Label.new()
	_armor_status_label.add_theme_color_override("font_color", Color(0.78, 0.82, 0.9, 0.95))
	_armor_status_label.add_theme_font_size_override("font_size", 22)
	_armor_status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(_armor_status_label)

	_armor_repair_cost_label = Label.new()
	_armor_repair_cost_label.add_theme_color_override("font_color", Color(0.72, 0.76, 0.82, 0.82))
	_armor_repair_cost_label.add_theme_font_size_override("font_size", 20)
	row.add_child(_armor_repair_cost_label)

	_armor_repair_btn = Button.new()
	_armor_repair_btn.custom_minimum_size = Vector2(160, 38)
	_armor_repair_btn.add_theme_font_size_override("font_size", 24)
	_armor_repair_btn.add_theme_color_override("font_color", Color(0.98, 0.95, 0.88, 1))
	_armor_repair_btn.pressed.connect(_on_repair_armor_pressed)
	row.add_child(_armor_repair_btn)

	_supply_status_label = Label.new()
	_supply_status_label.add_theme_color_override("font_color", Color(0.72, 0.76, 0.82, 0.75))
	_supply_status_label.add_theme_font_size_override("font_size", 18)
	_supply_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	section.add_child(_supply_status_label)


func _refresh_armor_repair_section() -> void:
	if _armor_status_label == null:
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

	var penalty := CrownSystem.get_armor_block_penalty()
	var penalty_text := ""
	if penalty > 0.001:
		penalty_text = "  (блок +%.0f%% урона)" % (penalty * 100.0)

	_armor_status_label.text = "Снаряжение: [color=%s]%d%%[/color]%s" % [color_hex, pct, penalty_text]

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
