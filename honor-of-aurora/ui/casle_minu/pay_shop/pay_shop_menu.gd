extends Control


func get_hud() -> Node:
	return GameplayFacade.get_hud(get_tree())


func _ready() -> void:
	Events.ore_changed.connect(_on_ore_changed)
	Events.premium_ore_pack_purchased.connect(_on_pack_purchased)
	_rebuild_rows()
	_refresh_summary()


func _exit_tree() -> void:
	if Events.ore_changed.is_connected(_on_ore_changed):
		Events.ore_changed.disconnect(_on_ore_changed)
	if Events.premium_ore_pack_purchased.is_connected(_on_pack_purchased):
		Events.premium_ore_pack_purchased.disconnect(_on_pack_purchased)


func reset_payshop_menu_state() -> void:
	_rebuild_rows()
	_refresh_summary()


func _on_ore_changed(_value: int) -> void:
	if visible:
		_refresh_summary()


func _on_pack_purchased(_pack_id: String, _ore_added: int) -> void:
	_refresh_summary()


func _refresh_summary() -> void:
	var subtitle := get_node_or_null("PayShopPanel/PayShopSubtitle") as Label
	if subtitle:
		subtitle.text = "Премиум-магазин руды. Покупки: %d · Куплено руды: %d · На балансе: %d" % [
			SaveManager.premium_ore_purchase_count,
			SaveManager.premium_ore_purchased_total,
			SaveManager.ore_count,
		]


func _rebuild_rows() -> void:
	var rows := get_node_or_null("PayShopPanel/Scroll/Rows") as VBoxContainer
	if rows == null:
		return
	for c in rows.get_children():
		c.queue_free()
	for pack_id in BalanceConfig.get_premium_ore_pack_ids():
		var pack := BalanceConfig.get_premium_ore_pack(pack_id)
		if pack.is_empty():
			continue
		rows.add_child(_make_pack_row(pack_id, pack))


func _make_pack_row(pack_id: String, pack: Dictionary) -> Control:
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(0, 64)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 14)

	var info := Label.new()
	var ore := int(pack.get("ore", 0))
	var bonus := int(pack.get("bonus_ore", 0))
	var total := ore + bonus
	info.text = "%s · %d + %d бонус = %d руды" % [String(pack.get("title", pack_id)), ore, bonus, total]
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(info)

	var price := Label.new()
	price.text = String(pack.get("price_label", "0 ₽"))
	price.custom_minimum_size = Vector2(92, 0)
	price.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	price.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(price)

	var btn := Button.new()
	btn.text = "Купить"
	btn.custom_minimum_size = Vector2(132, 48)
	btn.pressed.connect(_on_buy_pack_pressed.bind(pack_id))
	row.add_child(btn)
	return row


func _on_buy_pack_pressed(pack_id: String) -> void:
	SoundManager.play_ui_button()
	GameplayFacade.purchase_premium_ore_pack(pack_id)


func _on_back_pressed() -> void:
	SoundManager.play_ui_button()
	var hud := get_hud()
	if hud and hud.has_method("hide_payshop_menu"):
		hud.hide_payshop_menu()
