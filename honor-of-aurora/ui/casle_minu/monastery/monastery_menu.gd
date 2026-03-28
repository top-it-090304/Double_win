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

	var fortitude_desc := get_node_or_null("MonasteryPanel/MainActions/SlotsRow/slot_revive/ColumnRevive/ReviveDesc") as Label
	if fortitude_desc:
		var reduction := GameManager.get_monastery_fortitude_ratio_preview() * 100.0
		fortitude_desc.text = "−%.0f%% входящего урона по отряду (поход)" % reduction

	var cost_v_gold := BalanceConfig.get_monastery_vitality_gold_cost()
	var cost_v_ore := BalanceConfig.get_monastery_vitality_ore_cost()
	var cost_f_gold := BalanceConfig.get_monastery_revive_gold_cost()
	var cost_f_ore := BalanceConfig.get_monastery_revive_ore_cost()

	_set_cost_button("MonasteryPanel/MainActions/SlotsRow/slot_vitality/ColumnVitality/BtnBlessVitality", cost_v_gold, cost_v_ore)
	_set_cost_button("MonasteryPanel/MainActions/SlotsRow/slot_revive/ColumnRevive/BtnReviveFallen", cost_f_gold, cost_f_ore)

	var can_vitality := (not GameManager.monastery_vitality_prepared) and GameplayFacade.can_afford_gold_plus_ore(cost_v_gold, cost_v_ore)
	var can_fortitude := (not GameManager.monastery_fortitude_prepared) and GameplayFacade.can_afford_gold_plus_ore(cost_f_gold, cost_f_ore)
	var btn_v := get_node_or_null("MonasteryPanel/MainActions/SlotsRow/slot_vitality/ColumnVitality/BtnBlessVitality") as Button
	var btn_f := get_node_or_null("MonasteryPanel/MainActions/SlotsRow/slot_revive/ColumnRevive/BtnReviveFallen") as Button
	if btn_v:
		btn_v.disabled = not can_vitality
	if btn_f:
		btn_f.disabled = not can_fortitude


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
	if not GameManager.try_prepare_monastery_fortitude():
		return
	_refresh_ui()
