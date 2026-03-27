extends Control

const _BarracksQuotes := preload("res://ui/casle_minu/barracks/barracks_quotes.gd")


func get_hud() -> Node:
	return GameplayFacade.get_hud(get_tree())


func _ready() -> void:
	Events.gold_changed.connect(_on_gold_changed)
	_refresh_quote()
	_refresh_buttons()


func _exit_tree() -> void:
	if Events.gold_changed.is_connected(_on_gold_changed):
		Events.gold_changed.disconnect(_on_gold_changed)


func _on_gold_changed(_new_gold: int) -> void:
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
