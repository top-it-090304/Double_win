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


func reset_archery_menu_state() -> void:
	_refresh_ui()


func _refresh_ui() -> void:
	var passive := get_node_or_null("ArcheryPanel/ArcherySubtitle") as Label
	if passive:
		var hp_passive := GameManager.get_archery_passive_hp_ratio() * 100.0
		var as_passive := GameManager.get_archery_passive_attack_speed_ratio() * 100.0
		passive.text = "Пассив от тира: +%.0f%% HP лучников, +%.0f%% к темпу стрельбы." % [hp_passive, as_passive]

	var volley_desc := get_node_or_null("ArcheryPanel/MainActions/SlotsRow/slot_volley/ColumnVolley/VolleyDesc") as Label
	if volley_desc:
		volley_desc.text = "Боевой приказ: +%.0f%% к темпу стрельбы (поход)." % (GameManager.get_archery_volley_ratio_preview() * 100.0)
	var guard_desc := get_node_or_null("ArcheryPanel/MainActions/SlotsRow/slot_guard/ColumnGuard/GuardDesc") as Label
	if guard_desc:
		guard_desc.text = "Боевой приказ: +%.0f%% к HP лучников (поход)." % (GameManager.get_archery_guard_ratio_preview() * 100.0)

	var cost_v_gold := BalanceConfig.get_archery_volley_gold_cost()
	var cost_v_ore := BalanceConfig.get_archery_volley_ore_cost()
	var cost_g_gold := BalanceConfig.get_archery_guard_gold_cost()
	var cost_g_ore := BalanceConfig.get_archery_guard_ore_cost()
	_set_cost_button("ArcheryPanel/MainActions/SlotsRow/slot_volley/ColumnVolley/BtnVolleyOrder", cost_v_gold, cost_v_ore)
	_set_cost_button("ArcheryPanel/MainActions/SlotsRow/slot_guard/ColumnGuard/BtnGuardOrder", cost_g_gold, cost_g_ore)

	var btn_v := get_node_or_null("ArcheryPanel/MainActions/SlotsRow/slot_volley/ColumnVolley/BtnVolleyOrder") as Button
	var btn_g := get_node_or_null("ArcheryPanel/MainActions/SlotsRow/slot_guard/ColumnGuard/BtnGuardOrder") as Button
	var can_v := not GameManager.archery_volley_prepared and SaveManager.gold >= cost_v_gold and SaveManager.ore_count >= cost_v_ore
	var can_g := not GameManager.archery_guard_prepared and SaveManager.gold >= cost_g_gold and SaveManager.ore_count >= cost_g_ore
	if btn_v:
		btn_v.disabled = not can_v
	if btn_g:
		btn_g.disabled = not can_g


func _set_cost_button(path: String, gold_cost: int, ore_cost: int) -> void:
	var b := get_node_or_null(path) as Button
	if b == null:
		return
	b.text = "%d + %d" % [gold_cost, ore_cost]


func _on_back_pressed() -> void:
	SoundManager.play_ui_button()
	var hud := get_hud()
	if hud and hud.has_method("hide_archery_menu"):
		hud.hide_archery_menu()


func _on_volley_order_pressed() -> void:
	SoundManager.play_ui_button()
	if not GameManager.try_prepare_archery_volley():
		return
	_refresh_ui()


func _on_guard_order_pressed() -> void:
	SoundManager.play_ui_button()
	if not GameManager.try_prepare_archery_guard():
		return
	_refresh_ui()
