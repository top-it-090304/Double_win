extends Control


func get_hud() -> Node:
	return GameplayFacade.get_hud(get_tree())


func _ready() -> void:
	Events.gold_changed.connect(_on_resources_changed)
	Events.ore_changed.connect(_on_resources_changed)
	_refresh_ui()


func _exit_tree() -> void:
	if Events.gold_changed.is_connected(_on_resources_changed):
		Events.gold_changed.disconnect(_on_resources_changed)
	if Events.ore_changed.is_connected(_on_resources_changed):
		Events.ore_changed.disconnect(_on_resources_changed)


func _on_resources_changed(_value: int) -> void:
	if visible:
		_refresh_ui()


func reset_monastery_menu_state() -> void:
	_refresh_ui()


func _refresh_ui() -> void:
	var hp_label := get_node_or_null("MonasteryPanel/MainActions/SlotsRow/slot_vitality/ColumnVitality/VitalityDesc") as Label
	var hp_pct := GameManager.get_monastery_vitality_ratio_preview() * 100.0
	if hp_label:
		hp_label.text = "+%.0f%% к макс. здоровью героя (поход)" % hp_pct

	var revive_desc := get_node_or_null("MonasteryPanel/MainActions/SlotsRow/slot_revive/ColumnRevive/ReviveDesc") as Label
	if revive_desc:
		var chance := GameManager.get_monastery_revive_chance_preview() * 100.0
		revive_desc.text = "Шанс %.0f%%. %s" % [chance, GameManager.get_pending_revival_text()]

	var cost_v_gold := BalanceConfig.get_monastery_vitality_gold_cost()
	var cost_v_ore := BalanceConfig.get_monastery_vitality_ore_cost()
	var cost_r_gold := BalanceConfig.get_monastery_revive_gold_cost()
	var cost_r_ore := BalanceConfig.get_monastery_revive_ore_cost()

	_set_cost_button("MonasteryPanel/MainActions/SlotsRow/slot_vitality/ColumnVitality/BtnBlessVitality", cost_v_gold, cost_v_ore)
	_set_cost_button("MonasteryPanel/MainActions/SlotsRow/slot_revive/ColumnRevive/BtnReviveFallen", cost_r_gold, cost_r_ore)

	var can_vitality := (not GameManager.monastery_vitality_prepared) and SaveManager.gold >= cost_v_gold and SaveManager.ore_count >= cost_v_ore
	var can_revive := (not GameManager.monastery_revive_used_for_return) and GameManager.has_pending_revival_losses() and SaveManager.gold >= cost_r_gold and SaveManager.ore_count >= cost_r_ore
	var btn_v := get_node_or_null("MonasteryPanel/MainActions/SlotsRow/slot_vitality/ColumnVitality/BtnBlessVitality") as Button
	var btn_r := get_node_or_null("MonasteryPanel/MainActions/SlotsRow/slot_revive/ColumnRevive/BtnReviveFallen") as Button
	if btn_v:
		btn_v.disabled = not can_vitality
	if btn_r:
		btn_r.disabled = not can_revive


func _set_cost_button(path: String, gold_cost: int, ore_cost: int) -> void:
	var b := get_node_or_null(path) as Button
	if b == null:
		return
	b.text = "%d + %d" % [gold_cost, ore_cost]


func _on_back_pressed() -> void:
	SoundManager.play_ui_button()
	var hud := get_hud()
	if hud and hud.has_method("hide_monastery_menu"):
		hud.hide_monastery_menu()


func _on_bless_vitality_pressed() -> void:
	SoundManager.play_ui_button()
	if not GameManager.try_prepare_monastery_vitality():
		return
	_refresh_ui()


func _on_revive_fallen_pressed() -> void:
	SoundManager.play_ui_button()
	if not GameManager.try_monastery_revive_after_return():
		return
	_refresh_ui()
