extends Control

enum HireKind { ARCHER, LANCER, PAWN }

enum InfoLayer { MAIN, STATS, STORY, HEROES_HUB, HERO_DETAIL }

const TEX_INFO_HERO := preload("res://Asets/Unit_pack/UI Elements/UI Elements/Human Avatars/aa_player.png")
const TEX_INFO_HEALER := preload("res://Asets/Unit_pack/UI Elements/UI Elements/Human Avatars/aa_healler.png")

const INFO_HERO_DETAIL := "Рыцарь Авроры — основной герой: ближний бой, щит, прогрессия уровней. Ведёт отряд и исследует острова."

const INFO_MONK_DETAIL := "Целитель — монах монастыря на базе: восстанавливает здоровье героя и союзников, сюжетные диалоги. Новые союзники появятся здесь позже."

var _info_layer: InfoLayer = InfoLayer.MAIN


func get_hud() -> Node:
	return GameplayFacade.get_hud(get_tree())

## Одна цена на любой тип юнита из меню найма (по умолчанию из BalanceConfig).
@export var unit_hire_cost: int = 220
@export var archer_scene: PackedScene
@export var lancer_scene: PackedScene
@export var pawn_scene: PackedScene
@export var spawn_offset: Vector2 = Vector2(80, 0)
func _ready() -> void:
	unit_hire_cost = BalanceConfig.get_unit_hire_cost()
	_refresh_hire_buy_ui()
	_refresh_info_hub_portraits()


func reset_castle_menu_state() -> void:
	_close_upgrade_select()
	_close_hire_select()
	var info := get_node_or_null("InfoPanel") as Control
	if info:
		_show_info_main_internal()
		info.visible = false
	var main_panel := get_node_or_null("CastleMenuPanel") as CanvasItem
	if main_panel:
		main_panel.visible = true


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
	var info := get_node_or_null("InfoPanel") as Control
	if info != null and info.visible:
		_on_info_back_pressed()
		return true
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
			btn.text = "Максимум"
			continue
		btn.disabled = false
		var cost: int = BalanceConfig.get_building_upgrade_step() * (b_tier + 1)
		btn.text = "%d зол." % cost


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
	_open_info_panel()


func _close_info_panel() -> void:
	_show_info_main_internal()
	var info_panel := get_node_or_null("InfoPanel") as Control
	var main_panel := get_node_or_null("CastleMenuPanel") as CanvasItem
	if info_panel:
		info_panel.visible = false
	if main_panel:
		main_panel.visible = true
	_set_main_castle_chrome_visible(true)


func _sync_info_panel_visibility() -> void:
	var layers: Array[String] = [
		"InfoMain",
		"InfoStatsDetail",
		"InfoStoryDetail",
		"InfoHeroesHub",
		"InfoHeroDetail",
	]
	var active: int = int(_info_layer)
	for i in layers.size():
		var n := get_node_or_null("InfoPanel/%s" % layers[i]) as CanvasItem
		if n:
			n.visible = (i == active)


func _show_info_main_internal() -> void:
	_info_layer = InfoLayer.MAIN
	_sync_info_panel_visibility()


func _open_info_panel() -> void:
	_show_info_main_internal()
	var hire := get_node_or_null("HireSelectPanel") as Control
	var upgrade := get_node_or_null("UpgradeSelectPanel") as Control
	if hire:
		hire.visible = false
	if upgrade:
		upgrade.visible = false
	var info_panel := get_node_or_null("InfoPanel") as Control
	var main_panel := get_node_or_null("CastleMenuPanel") as CanvasItem
	if info_panel:
		info_panel.visible = true
	if main_panel:
		main_panel.visible = false
	_set_main_castle_chrome_visible(false)


func _refresh_info_hub_portraits() -> void:
	var ph := get_node_or_null(
		"InfoPanel/InfoHeroesHub/MarginHeroHub/HeroHubRow/BtnOpenHeroWarrior/HeroWarriorVBox/PortraitHero"
	) as TextureRect
	if ph:
		ph.texture = TEX_INFO_HERO
	var pm := get_node_or_null(
		"InfoPanel/InfoHeroesHub/MarginHeroHub/HeroHubRow/BtnOpenHeroMonk/HeroMonkVBox/PortraitMonk"
	) as TextureRect
	if pm:
		pm.texture = TEX_INFO_HEALER


func _refresh_stats_detail_label() -> void:
	var vb := get_node_or_null("InfoPanel/InfoStatsDetail/ScrollStats/MarginStats/StatsContent") as VBoxContainer
	if vb == null:
		return
	for c in vb.get_children():
		c.queue_free()
	var sections: Array = _build_stats_sections()
	var first := true
	for s in sections:
		if not first:
			_add_stats_spacer(vb, 6)
		first = false
		var sd: Dictionary = s
		_add_stats_section_header(vb, sd["title"])
		for item in sd["items"]:
			var row: Dictionary = item
			_add_stats_kv_row(vb, row["label"], row["value"])


func _add_stats_section_header(parent: VBoxContainer, title: String) -> void:
	var l := Label.new()
	l.text = title
	l.add_theme_font_size_override("font_size", 22)
	l.add_theme_color_override("font_color", Color(0.88, 0.92, 0.98))
	parent.add_child(l)


func _add_stats_kv_row(parent: VBoxContainer, label: String, value: String) -> void:
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 16)
	var nl := Label.new()
	nl.text = label
	nl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	nl.add_theme_font_size_override("font_size", 18)
	nl.add_theme_color_override("font_color", Color(0.62, 0.68, 0.78))
	var vl := Label.new()
	vl.text = value
	vl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	vl.add_theme_font_size_override("font_size", 18)
	vl.add_theme_color_override("font_color", Color(0.9, 0.92, 0.96))
	hb.add_child(nl)
	hb.add_child(vl)
	parent.add_child(hb)


func _add_stats_spacer(parent: VBoxContainer, px: int) -> void:
	var sp := Control.new()
	sp.custom_minimum_size = Vector2(0, float(px))
	parent.add_child(sp)


func _build_stats_sections() -> Array:
	var p := get_tree().get_first_node_in_group("player")
	var tier := HeroProgression.get_tier_for_level(SaveManager.current_level)
	var max_hp: int = tier.max_health
	var dmg: int = tier.attack_damage
	if p:
		if p.get("max_health") != null:
			max_hp = int(p.max_health)
		if p.get("attack_damage") != null:
			dmg = int(p.attack_damage)
	var need_exp := 0
	var need_exp_label := ""
	if p and p.has_method("get_exp_to_next_level"):
		if SaveManager.current_level >= BalanceConfig.MAX_HERO_LEVEL:
			need_exp_label = "Максимум"
		else:
			need_exp = maxi(0, p.get_exp_to_next_level() - SaveManager.current_exp)
			need_exp_label = "%d опыта" % need_exp
	var sections: Array = []
	var prog: Dictionary = {"title": "Прогресс", "items": []}
	prog["items"].append({"label": "Уровень героя", "value": str(SaveManager.current_level)})
	prog["items"].append({"label": "Опыт", "value": str(SaveManager.current_exp)})
	prog["items"].append({"label": "До следующего уровня", "value": need_exp_label})
	sections.append(prog)
	var combat: Dictionary = {"title": "Бой и защита", "items": []}
	combat["items"].append({"label": "Здоровье (сохранение)", "value": "%d / %d" % [SaveManager.current_health, max_hp]})
	combat["items"].append({"label": "Урон атаки", "value": str(dmg)})
	if GameManager.armory_attack_bonus != 0:
		combat["items"].append({"label": "Бонус оружейной (выезд)", "value": "+%d к урону" % GameManager.armory_attack_bonus})
	combat["items"].append(
		{"label": "Щит при блоке", "value": "×%.2f входящего (меньше — лучше)" % GameManager.armory_shield_damage_factor}
	)
	sections.append(combat)
	var meta: Dictionary = {"title": "Ресурсы и статистика", "items": []}
	meta["items"].append({"label": "Золото", "value": str(SaveManager.gold)})
	meta["items"].append({"label": "Побеждено боссов", "value": str(SaveManager.boss_kill)})
	meta["items"].append({"label": "Смертей героя", "value": str(SaveManager.death_count)})
	meta["items"].append({"label": "Завершённых походов", "value": str(SaveManager.expedition_return_count)})
	sections.append(meta)
	var base: Dictionary = {"title": "База и армия", "items": []}
	base["items"].append(
		{
			"label": "Нанято всего",
			"value": "лучники %d · копейщики %d · пешки %d" % [SaveManager.archer_count, SaveManager.lancer_count, SaveManager.pawn_count],
		}
	)
	base["items"].append({"label": "Отмеченных зон на островах", "value": str(SaveManager.island_zone_state.size())})
	base["items"].append(
		{
			"label": "Здания (уровень)",
			"value": "монастырь %d · замок %d · оружейная %d · стрельбище %d"
			% [
				SaveManager.get_building_tier("Monastery") + 1,
				SaveManager.get_building_tier("Castle") + 1,
				SaveManager.get_building_tier("Barracks") + 1,
				SaveManager.get_building_tier("Archery") + 1,
			],
		}
	)
	sections.append(base)
	return sections


func _story_bbcode() -> String:
	return (
		"[font_size=24][b]Мир Авроры[/b][/font_size]\n\n"
		+ "[color=#aab8cc]Архипелаг назван не в честь дворца: в лоциях и песнях «Аврора» — примета, будто море светлеет раньше неба, а острова — бусины на цепи первого света. В орденских текстах к тому же слову прибавляли устав: не будить узлы до часа. Поход по островам — это и политика короны, и разжимание старой клятвы.[/color]\n\n"
		+ "[font_size=20][b]Дальше[/b][/font_size]\n"
		+ "• Главы кампании и кат-сцены\n"
		+ "• События между выездами на базе\n"
		+ "• Новые союзники и диалоги"
	)


func _refresh_story_detail_label() -> void:
	var rtl := get_node_or_null("InfoPanel/InfoStoryDetail/ScrollStory/InfoStoryBody") as RichTextLabel
	if rtl:
		rtl.bbcode_text = _story_bbcode()


func _hero_detail_bbcode(hero_kind: String) -> String:
	match hero_kind:
		"hero":
			return (
				"[font_size=26][b]Рыцарь Авроры[/b][/font_size]\n"
				+ "[color=#8899aa]Роль · ближний бой, щит, капитан отряда[/color]\n\n"
				+ INFO_HERO_DETAIL
			)
		"monk":
			return (
				"[font_size=26][b]Целитель[/b][/font_size]\n"
				+ "[color=#8899aa]Роль · поддержка, монастырь на базе[/color]\n\n"
				+ INFO_MONK_DETAIL
			)
	return ""


func _on_info_open_stats_pressed() -> void:
	SoundManager.play_ui_button()
	_refresh_stats_detail_label()
	_info_layer = InfoLayer.STATS
	_sync_info_panel_visibility()


func _on_info_open_story_pressed() -> void:
	SoundManager.play_ui_button()
	_refresh_story_detail_label()
	_info_layer = InfoLayer.STORY
	_sync_info_panel_visibility()


func _on_info_open_heroes_pressed() -> void:
	SoundManager.play_ui_button()
	_info_layer = InfoLayer.HEROES_HUB
	_sync_info_panel_visibility()


func _on_info_open_hero_warrior_pressed() -> void:
	SoundManager.play_ui_button()
	_show_info_hero_detail("hero")


func _on_info_open_hero_monk_pressed() -> void:
	SoundManager.play_ui_button()
	_show_info_hero_detail("monk")


func _show_info_hero_detail(hero_kind: String) -> void:
	var portrait := get_node_or_null(
		"InfoPanel/InfoHeroDetail/HeroDetailRow/PortraitFrameHeroDetail/HeroDetailPortrait"
	) as TextureRect
	var title := get_node_or_null("InfoPanel/InfoHeroDetail/TitleHeroDetail") as Label
	var body := get_node_or_null("InfoPanel/InfoHeroDetail/HeroDetailRow/ScrollHeroDetail/MarginHeroDetail/InfoHeroDetailBody") as RichTextLabel
	match hero_kind:
		"hero":
			if portrait:
				portrait.texture = TEX_INFO_HERO
			if title:
				title.text = "Рыцарь"
			if body:
				body.bbcode_text = _hero_detail_bbcode("hero")
		"monk":
			if portrait:
				portrait.texture = TEX_INFO_HEALER
			if title:
				title.text = "Целитель"
			if body:
				body.bbcode_text = _hero_detail_bbcode("monk")
	_info_layer = InfoLayer.HERO_DETAIL
	_sync_info_panel_visibility()


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
	unit.add_to_group("squad_member")
	SaveManager.save_game()
	_close_hire_select()


func _on_info_back_pressed() -> void:
	SoundManager.play_ui_button()
	match _info_layer:
		InfoLayer.MAIN:
			_close_info_panel()
		InfoLayer.HERO_DETAIL:
			_info_layer = InfoLayer.HEROES_HUB
			_sync_info_panel_visibility()
		InfoLayer.HEROES_HUB, InfoLayer.STATS, InfoLayer.STORY:
			_show_info_main_internal()
