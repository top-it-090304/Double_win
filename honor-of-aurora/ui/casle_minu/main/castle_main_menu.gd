extends Control

enum HireKind { ARCHER, LANCER, PAWN }


func get_hud() -> Node:
	return GameplayFacade.get_hud(get_tree())

## Одна цена на любой тип юнита из меню найма.
@export var unit_hire_cost: int = 150
@export var archer_scene: PackedScene
@export var lancer_scene: PackedScene
@export var pawn_scene: PackedScene
@export var spawn_offset: Vector2 = Vector2(80, 0)
## Совпадает с `building_template.upgrade_cost_step` (для подписей цен в меню).
@export var building_upgrade_cost_step: int = 200


func _ready() -> void:
	_refresh_hire_buy_ui()


func reset_castle_menu_state() -> void:
	_close_upgrade_select()
	_close_hire_select()


func _refresh_hire_buy_ui() -> void:
	var price_lbl := get_node_or_null("HireSelectPanel/HirePanel/HirePriceLabel") as Label
	if price_lbl:
		price_lbl.text = "Все типы — %d зол." % unit_hire_cost
	for path in [
		"HireSelectPanel/HirePanel/slot_archer/ColumnArcher/BuyArcher",
		"HireSelectPanel/HirePanel/slot_lancer/ColumnLancer/BuyLancer",
		"HireSelectPanel/HirePanel/slot_pawn/ColumnPawn/BuyPawn",
	]:
		var b := get_node_or_null(path) as Button
		if b:
			b.text = str(unit_hire_cost)


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
	# Старое оформление (тайлмап из лент/баннеров) отключено — остаётся только модальный UI.
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
	var info_panel := get_node_or_null("InfoPanel") as Control
	if info_panel:
		info_panel.visible = false
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


func _refresh_upgrade_building_buttons() -> void:
	for type_key in ["Monastery", "Castle", "Barracks", "Archery"]:
		var btn := get_node_or_null("UpgradeSelectPanel/UpgradePanel/UpgradeActions/Btn%s" % type_key) as Button
		if btn == null:
			continue
		var tier: int = SaveManager.get_building_tier(type_key)
		if tier >= 4:
			btn.disabled = true
			btn.text = _upgrade_button_title(type_key) + " — макс."
			continue
		btn.disabled = false
		var cost: int = building_upgrade_cost_step * (tier + 1)
		btn.text = "%s — %d зол." % [_upgrade_button_title(type_key), cost]


func _upgrade_button_title(building_type: String) -> String:
	match building_type:
		"Monastery":
			return "Монастырь (церковь)"
		"Castle":
			return "Замок (штаб)"
		"Barracks":
			return "Оружейная"
		"Archery":
			return "Стрельбище"
	return building_type


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
	var info_panel := get_node_or_null("InfoPanel") as Control
	if info_panel:
		info_panel.visible = false
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


func _on_info_pressed() -> void:
	SoundManager.play_ui_button()
	_show_castle_info()


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


func _hire_unit(kind: HireKind) -> void:
	var scene := _resolve_scene_for_hire(kind)
	if not scene:
		return
	if not GameplayFacade.try_spend_gold(unit_hire_cost):
		return
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if not player:
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
	unit.global_position = positions[0]
	if kind == HireKind.ARCHER and Events.current_location == Events.LOCATION.BASE:
		unit.set("stationary_guard", true)
	SaveManager.save_game()
	_close_hire_select()


func _show_castle_info() -> void:
	var info_panel := get_node_or_null("InfoPanel") as Control
	if info_panel:
		info_panel.visible = not info_panel.visible


func _on_info_back_pressed() -> void:
	SoundManager.play_ui_button()
	var info_panel := get_node_or_null("InfoPanel") as Control
	if info_panel:
		info_panel.visible = false
