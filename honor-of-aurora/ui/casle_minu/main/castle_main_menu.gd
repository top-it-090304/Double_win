extends Control

enum HireKind { ARCHER, LANCER, PAWN }


func get_hud() -> Node:
	return GameplayFacade.get_hud(get_tree())

## Одна цена на любой тип юнита из меню найма (по умолчанию из BalanceConfig).
@export var unit_hire_cost: int = 340
@export var archer_scene: PackedScene
@export var lancer_scene: PackedScene
@export var pawn_scene: PackedScene
@export var spawn_offset: Vector2 = Vector2(80, 0)


func _ready() -> void:
	unit_hire_cost = BalanceConfig.get_unit_hire_cost()
	_refresh_hire_buy_ui()


func reset_castle_menu_state() -> void:
	_close_upgrade_select()
	_close_hire_select()
	var main_panel := get_node_or_null("CastleMenuPanel") as CanvasItem
	if main_panel:
		main_panel.visible = true


func _refresh_hire_buy_ui() -> void:
	var ore_cost := BalanceConfig.get_unit_hire_ore_cost()
	var price_lbl := get_node_or_null("HireSelectPanel/HirePanel/HirePriceLabel") as Label
	if price_lbl:
		price_lbl.text = "Все типы — %d зол. + %d руды" % [unit_hire_cost, ore_cost]
	for path in [
		"HireSelectPanel/HirePanel/slot_archer/ColumnArcher/BuyArcher",
		"HireSelectPanel/HirePanel/slot_lancer/ColumnLancer/BuyLancer",
		"HireSelectPanel/HirePanel/slot_pawn/ColumnPawn/BuyPawn",
	]:
		var b := get_node_or_null(path) as Button
		if b:
			b.text = "%d + %d" % [unit_hire_cost, ore_cost]


func try_close_hire_submenu() -> bool:
	var upgrade := get_node_or_null("UpgradeSelectPanel") as Control
	if upgrade != null and upgrade.visible:
		_close_upgrade_select()
		return true
	var panel := get_node_or_null("HireSelectPanel") as Control
	if panel == null or not panel.visible:
		return false
	_close_hire_select()
	return true


func _set_main_castle_chrome_visible(_visible_chrome: bool) -> void:
	var bg := get_node_or_null("background") as CanvasItem
	if bg:
		bg.visible = false


func _close_hire_select() -> void:
	var hire := get_node_or_null("HireSelectPanel") as Control
	var main_panel := get_node_or_null("CastleMenuPanel") as CanvasItem
	if hire:
		hire.visible = false
	if main_panel:
		main_panel.visible = true
	_set_main_castle_chrome_visible(true)


func _close_upgrade_select() -> void:
	var upgrade := get_node_or_null("UpgradeSelectPanel") as Control
	var main_panel := get_node_or_null("CastleMenuPanel") as CanvasItem
	if upgrade:
		upgrade.visible = false
	if main_panel:
		main_panel.visible = true
	_set_main_castle_chrome_visible(true)


func _open_upgrade_select() -> void:
	_refresh_upgrade_building_buttons()
	var hire := get_node_or_null("HireSelectPanel") as Control
	var upgrade := get_node_or_null("UpgradeSelectPanel") as Control
	var main_panel := get_node_or_null("CastleMenuPanel") as CanvasItem
	if hire:
		hire.visible = false
	if upgrade:
		upgrade.visible = true
	if main_panel:
		main_panel.visible = false
	_set_main_castle_chrome_visible(false)


const _UPGRADE_SLOTS := [
	{"type": "Monastery", "slot": "slot_monastery", "column": "ColumnMonastery", "btn": "BtnMonastery"},
	{"type": "Castle", "slot": "slot_castle", "column": "ColumnCastle", "btn": "BtnCastle"},
	{"type": "Barracks", "slot": "slot_barracks", "column": "ColumnBarracks", "btn": "BtnBarracks"},
	{"type": "Archery", "slot": "slot_archery", "column": "ColumnArchery", "btn": "BtnArchery"},
]


func _refresh_upgrade_building_buttons() -> void:
	for entry in _UPGRADE_SLOTS:
		var type_key: String = entry.type
		var b_tier: int = SaveManager.get_building_tier(type_key)
		var base := "UpgradeSelectPanel/UpgradePanel/UpgradeGrid/%s/%s" % [entry.slot, entry.column]
		var btn := get_node_or_null("%s/%s" % [base, entry.btn]) as Button
		var cost_row := get_node_or_null("%s/%s/CostRow" % [base, entry.btn]) as HBoxContainer
		var gold_lbl := get_node_or_null("%s/%s/CostRow/GoldCostRow/GoldCostLabel" % [base, entry.btn]) as Label
		var wood_lbl := get_node_or_null("%s/%s/CostRow/WoodCostRow/WoodCostLabel" % [base, entry.btn]) as Label
		var ore_lbl := get_node_or_null("%s/%s/CostRow/OreCostRow/OreCostLabel" % [base, entry.btn]) as Label
		var tier_lbl := get_node_or_null("%s/LabelTier" % base) as Label
		var preview := get_node_or_null("%s/BuildingPreview" % base) as TextureRect
		if preview:
			var tex := _building_preview_texture(type_key)
			preview.texture = tex
			preview.visible = tex != null
		if tier_lbl:
			tier_lbl.text = "Уровень %d / 5" % (b_tier + 1)
		if btn == null:
			continue
		if b_tier >= 4:
			btn.disabled = true
			btn.icon = null
			btn.text = "Максимум"
			if cost_row:
				cost_row.visible = false
			continue
		btn.disabled = false
		btn.icon = null
		btn.text = ""
		if cost_row:
			cost_row.visible = true
		var gold_cost: int = BalanceConfig.get_building_upgrade_step() * (b_tier + 1)
		var wood_cost: int = BalanceConfig.get_building_upgrade_wood_cost(b_tier)
		var ore_cost: int = BalanceConfig.get_building_upgrade_ore_cost(b_tier)
		if gold_lbl:
			gold_lbl.text = "%d" % gold_cost
		if wood_lbl:
			wood_lbl.text = "%d" % wood_cost
		if ore_lbl:
			ore_lbl.text = "%d" % ore_cost


func _building_preview_texture(building_type: String) -> Texture2D:
	var tier: int = SaveManager.get_building_tier(building_type)
	var folders := ["Black Buildings", "Blue Buildings", "Red Buildings", "Purple Buildings", "Yellow Buildings"]
	var folder: String = folders[clampi(tier, 0, 4)]
	var path := "res://Asets/Unit_pack/Buildings/%s/%s.png" % [folder, building_type]
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	return null


func _find_building_on_base(building_type: String) -> Node:
	var scene := get_tree().current_scene
	if scene == null:
		return null
	var buildings_root := scene.get_node_or_null("buildings") as Node
	if buildings_root == null:
		return null
	for child in buildings_root.get_children():
		if child.get("building_type") == building_type:
			return child
	return null


func _try_upgrade_building(building_type: String) -> void:
	var b := _find_building_on_base(building_type)
	if b == null or not b.has_method("upgrade_building"):
		return
	if not b.call("upgrade_building"):
		return
	if building_type == "Archery":
		GameManager.refresh_archery_modifiers_for_active_units()
	GameManager.refresh_all_companion_progression()
	_refresh_upgrade_building_buttons()


func _on_upgrade_pick_back_pressed() -> void:
	SoundManager.play_ui_button()
	_close_upgrade_select()


func _on_upgrade_monastery_pressed() -> void:
	SoundManager.play_ui_button()
	_try_upgrade_building("Monastery")


func _on_upgrade_castle_pressed() -> void:
	SoundManager.play_ui_button()
	_try_upgrade_building("Castle")


func _on_upgrade_barracks_pressed() -> void:
	SoundManager.play_ui_button()
	_try_upgrade_building("Barracks")


func _on_upgrade_archery_pressed() -> void:
	SoundManager.play_ui_button()
	_try_upgrade_building("Archery")


func _open_hire_select() -> void:
	var upgrade := get_node_or_null("UpgradeSelectPanel") as Control
	if upgrade:
		upgrade.visible = false
	_refresh_hire_buy_ui()
	var quote_lbl := get_node_or_null("HireSelectPanel/HirePanel/SubtitleHire") as Label
	if quote_lbl:
		quote_lbl.text = HireQuoteRotator.pick_next()
	var hire := get_node_or_null("HireSelectPanel") as Control
	var main_panel := get_node_or_null("CastleMenuPanel") as CanvasItem
	if hire:
		hire.visible = true
	if main_panel:
		main_panel.visible = false
	_set_main_castle_chrome_visible(false)


func _on_back_pressed() -> void:
	SoundManager.play_ui_button()
	var hud := get_hud()
	if hud == null or not hud.has_method("hide_castle_menu"):
		return
	hud.hide_castle_menu()


func _on_hire_pressed() -> void:
	SoundManager.play_ui_button()
	_open_hire_select()


func _on_hire_pick_back_pressed() -> void:
	SoundManager.play_ui_button()
	_close_hire_select()


func _on_hire_archer_pressed() -> void:
	SoundManager.play_ui_button()
	_hire_unit(HireKind.ARCHER)


func _on_hire_lancer_pressed() -> void:
	SoundManager.play_ui_button()
	_hire_unit(HireKind.LANCER)


func _on_hire_pawn_pressed() -> void:
	SoundManager.play_ui_button()
	_hire_unit(HireKind.PAWN)


func _on_upgreat_pressed() -> void:
	SoundManager.play_ui_button()
	_open_upgrade_select()


func _resolve_archer_scene() -> PackedScene:
	if archer_scene != null:
		return archer_scene
	return load("res://ally/archer/arche_baser.tscn") as PackedScene


func _resolve_lancer_scene() -> PackedScene:
	if lancer_scene != null:
		return lancer_scene
	return load("res://ally/lancer/scenes/lancer_base.tscn") as PackedScene


func _resolve_pawn_scene() -> PackedScene:
	if pawn_scene != null:
		return pawn_scene
	return load("res://ally/pawn/scenes/pawn_base.tscn") as PackedScene


func _resolve_scene_for_hire(kind: HireKind) -> PackedScene:
	match kind:
		HireKind.ARCHER:
			return _resolve_archer_scene()
		HireKind.LANCER:
			return _resolve_lancer_scene()
		HireKind.PAWN:
			return _resolve_pawn_scene()
	return null


func _show_hire_fail(msg: String) -> void:
	var quote_lbl := get_node_or_null("HireSelectPanel/HirePanel/SubtitleHire") as Label
	if quote_lbl:
		quote_lbl.text = msg


func _hire_unit(kind: HireKind) -> void:
	var scene := _resolve_scene_for_hire(kind)
	if not scene:
		return
	if kind == HireKind.ARCHER or kind == HireKind.LANCER:
		if SaveManager.archer_count + SaveManager.lancer_count >= GameManager.get_max_warriors_allowed():
			_show_hire_fail("Нужен запас мяса: добывайте на базе (овцы), чтобы увеличить лимит лучников и копейщиков.")
			return
	var hire_ore_cost := BalanceConfig.get_unit_hire_ore_cost()
	if not GameplayFacade.try_spend_gold_plus_ore(unit_hire_cost, hire_ore_cost):
		_show_hire_fail("Недостаточно золота/руды.")
		return
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if not player:
		_show_hire_fail("Герой не найден в сцене.")
		return
	var unit := scene.instantiate() as Node2D
	if not unit:
		return
	match kind:
		HireKind.ARCHER:
			SaveManager.archer_count += 1
		HireKind.LANCER:
			SaveManager.lancer_count += 1
		HireKind.PAWN:
			SaveManager.pawn_count += 1
	var avoid: Array[Vector2] = [player.global_position]
	for node in get_tree().get_nodes_in_group("ally"):
		if node is Node2D:
			avoid.append((node as Node2D).global_position)
	var positions := GameManager.pick_archer_spawn_positions(get_tree().current_scene, 1, avoid)
	get_tree().current_scene.add_child(unit)
	if unit.has_method("apply_building_progression_from_manager"):
		unit.apply_building_progression_from_manager()
	unit.global_position = positions[0]
	unit.add_to_group("squad_member")
	SaveManager.save_game()
	_close_hire_select()
