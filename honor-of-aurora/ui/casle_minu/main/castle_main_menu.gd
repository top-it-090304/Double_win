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

const _CROWN_TITLE_ICONS := {
	"recruit": "res://Asets/Unit_pack/UI Elements/UI Elements/Icons/Icon_01.png",
	"scout": "res://Asets/Unit_pack/UI Elements/UI Elements/Icons/Icon_03.png",
	"guardian": "res://Asets/Unit_pack/UI Elements/UI Elements/Icons/Icon_08.png",
	"knight": "res://Asets/Unit_pack/UI Elements/UI Elements/Icons/Icon_11.png",
	"keeper": "res://Asets/Unit_pack/UI Elements/UI Elements/Human Avatars/Avatars_03.png",
	"hero": "res://Asets/Unit_pack/UI Elements/UI Elements/Human Avatars/Avatars_05.png",
}

const _PATH_MAIN_ACTIONS := "CastleMenuPanel/Center/Frame/InnerMargin/InnerVBox/MainActions"
const _PATH_HIRE_VBOX := "HireSelectPanel/HCenter/HirePanel/HireInner/HireVBox"
const _PATH_UPGRADE_GRID := "UpgradeSelectPanel/UCenter/UpgradePanel/UpgradeInner/UpgradeVBox/UpgradeScroll/UpgradeGrid"
const _PATH_CARAVAN_VBOX := "CaravanSelectPanel/CCenter/CaravanPanel/CaravanInner/CaravanVBox"

var _crown_help_layer: CanvasLayer
var _crown_icon_aspect: AspectRatioContainer
var _crown_title_icon: TextureRect
var _crown_title_name_lbl: Label
var _crown_title_sub_lbl: Label
var _caravan_brief: RichTextLabel


func _apply_dialogue_default_font_to_richtext(rtl: RichTextLabel) -> void:
	## Тот же источник, что у подписей в dialogue_window (без override — ThemeDB.fallback_font).
	var f := ThemeDB.fallback_font
	if f:
		rtl.add_theme_font_override("normal_font", f)
		rtl.add_theme_font_override("bold_font", f)


func _ready() -> void:
	unit_hire_cost = BalanceConfig.get_unit_hire_cost()
	_refresh_hire_buy_ui()
	_build_crown_title_strip()
	_build_crown_help_modal()
	_bind_caravan_brief()
	_refresh_crown_title_strip()
	if not Events.crown_title_changed.is_connected(_on_crown_title_changed_ui):
		Events.crown_title_changed.connect(_on_crown_title_changed_ui)
	if not Events.crown_displeasure_changed.is_connected(_on_crown_displeasure_changed_ui):
		Events.crown_displeasure_changed.connect(_on_crown_displeasure_changed_ui)
	if not visibility_changed.is_connected(_on_castle_root_visibility_changed):
		visibility_changed.connect(_on_castle_root_visibility_changed)


func _on_castle_root_visibility_changed() -> void:
	if not visible:
		_close_crown_help()
		return
	_refresh_crown_title_strip()


func _on_crown_title_changed_ui(_idx: int, _name: String) -> void:
	_refresh_crown_title_strip()
	if _caravan_brief:
		var csp := get_node_or_null("CaravanSelectPanel") as Control
		if csp and csp.visible:
			_refresh_caravan_ui()


func _on_crown_displeasure_changed_ui(_lvl: int) -> void:
	_refresh_crown_title_strip()
	if _caravan_brief:
		var csp := get_node_or_null("CaravanSelectPanel") as Control
		if csp and csp.visible:
			_refresh_caravan_ui()


func reset_castle_menu_state() -> void:
	if CrownTitlePreview.visible:
		CrownTitlePreview.hide_preview()
	_close_crown_help()
	_close_upgrade_select()
	_close_hire_select()
	_close_caravan_select()
	var main_panel := get_node_or_null("CastleMenuPanel") as CanvasItem
	if main_panel:
		main_panel.visible = true
	_refresh_crown_title_strip()


func _refresh_hire_buy_ui() -> void:
	var ore_cost := BalanceConfig.get_unit_hire_ore_cost()
	var price_lbl := get_node_or_null("%s/HirePriceLabel" % _PATH_HIRE_VBOX) as Label
	if price_lbl:
		price_lbl.text = "Все типы — %d зол. + %d руды" % [unit_hire_cost, ore_cost]
	for path in [
		"%s/HireSlotsRow/slot_archer/ColumnArcher/BuyArcher" % _PATH_HIRE_VBOX,
		"%s/HireSlotsRow/slot_lancer/ColumnLancer/BuyLancer" % _PATH_HIRE_VBOX,
		"%s/HireSlotsRow/slot_pawn/ColumnPawn/BuyPawn" % _PATH_HIRE_VBOX,
	]:
		var b := get_node_or_null(path) as Button
		if b:
			b.text = "%d + %d" % [unit_hire_cost, ore_cost]


func try_close_hire_submenu() -> bool:
	var caravan := get_node_or_null("CaravanSelectPanel") as Control
	if caravan != null and caravan.visible:
		_close_caravan_select()
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
	_close_crown_help()
	_refresh_upgrade_building_buttons()
	var hire := get_node_or_null("HireSelectPanel") as Control
	var upgrade := get_node_or_null("UpgradeSelectPanel") as Control
	var caravan := get_node_or_null("CaravanSelectPanel") as Control
	var main_panel := get_node_or_null("CastleMenuPanel") as CanvasItem
	if hire:
		hire.visible = false
	if caravan:
		caravan.visible = false
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
		var base := "%s/%s/%s" % [_PATH_UPGRADE_GRID, entry.slot, entry.column]
		var btn := get_node_or_null("%s/%s" % [base, entry.btn]) as Button
		var cost_row := get_node_or_null("%s/%s/CostRow" % [base, entry.btn]) as Control
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
	_close_crown_help()
	var upgrade := get_node_or_null("UpgradeSelectPanel") as Control
	var caravan := get_node_or_null("CaravanSelectPanel") as Control
	if upgrade:
		upgrade.visible = false
	if caravan:
		caravan.visible = false
	_refresh_hire_buy_ui()
	var quote_lbl := get_node_or_null("%s/SubtitleHire" % _PATH_HIRE_VBOX) as Label
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
	if _crown_help_layer and _crown_help_layer.visible:
		_close_crown_help()
		return
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


func _close_crown_help() -> void:
	if CrownTitlePreview.visible:
		CrownTitlePreview.hide_preview()
	if _crown_help_layer:
		_crown_help_layer.hide()


func _on_crown_help_close_pressed() -> void:
	SoundManager.play_ui_button()
	_close_crown_help()


func _on_crown_help_btn_pressed() -> void:
	SoundManager.play_ui_button()
	if _crown_help_layer == null:
		return
	_crown_help_layer.show()
	_populate_crown_help_panel()


func _build_crown_title_strip_style() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.09, 0.12, 0.96)
	sb.set_border_width_all(1)
	sb.border_color = Color(0.55, 0.48, 0.32, 0.5)
	sb.set_corner_radius_all(12)
	sb.shadow_color = Color(0, 0, 0, 0.45)
	sb.shadow_size = 10
	sb.shadow_offset = Vector2(0, 4)
	sb.content_margin_left = 14
	sb.content_margin_top = 10
	sb.content_margin_right = 14
	sb.content_margin_bottom = 10
	return sb


func _build_crown_title_strip() -> void:
	var main_actions := get_node_or_null(_PATH_MAIN_ACTIONS) as VBoxContainer
	if main_actions == null or main_actions.get_node_or_null("CrownTitleStrip"):
		return
	var wrap := MarginContainer.new()
	wrap.name = "CrownTitleStrip"
	wrap.add_theme_constant_override("margin_bottom", 8)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _build_crown_title_strip_style())
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	var icon_frame := PanelContainer.new()
	var icon_sb := StyleBoxFlat.new()
	icon_sb.bg_color = Color(0.12, 0.14, 0.2, 1)
	icon_sb.set_border_width_all(1)
	icon_sb.border_color = Color(0.78, 0.65, 0.35, 0.45)
	icon_sb.set_corner_radius_all(10)
	icon_sb.content_margin_left = 6
	icon_sb.content_margin_top = 6
	icon_sb.content_margin_right = 6
	icon_sb.content_margin_bottom = 6
	icon_frame.add_theme_stylebox_override("panel", icon_sb)
	icon_frame.custom_minimum_size = Vector2(76, 76)
	icon_frame.mouse_filter = Control.MOUSE_FILTER_STOP
	icon_frame.gui_input.connect(_on_crown_title_strip_icon_gui_input)
	_crown_icon_aspect = AspectRatioContainer.new()
	_crown_icon_aspect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_crown_icon_aspect.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_crown_icon_aspect.size_flags_vertical = Control.SIZE_EXPAND_FILL
	icon_frame.add_child(_crown_icon_aspect)
	_crown_title_icon = TextureRect.new()
	_crown_title_icon.set_anchors_preset(Control.PRESET_FULL_RECT)
	_crown_title_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_crown_title_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_crown_title_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_crown_icon_aspect.add_child(_crown_title_icon)
	row.add_child(icon_frame)
	var text_col := VBoxContainer.new()
	text_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_col.add_theme_constant_override("separation", 4)
	_crown_title_name_lbl = Label.new()
	_crown_title_name_lbl.add_theme_color_override("font_color", Color(0.94, 0.9, 0.78, 1))
	_crown_title_name_lbl.add_theme_font_size_override("font_size", 26)
	_crown_title_sub_lbl = Label.new()
	_crown_title_sub_lbl.add_theme_color_override("font_color", Color(0.72, 0.78, 0.88, 0.95))
	_crown_title_sub_lbl.add_theme_font_size_override("font_size", 17)
	_crown_title_sub_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_col.add_child(_crown_title_name_lbl)
	text_col.add_child(_crown_title_sub_lbl)
	row.add_child(text_col)
	var help_btn := Button.new()
	help_btn.text = "Справка"
	help_btn.focus_mode = Control.FOCUS_NONE
	help_btn.custom_minimum_size = Vector2(120, 44)
	help_btn.add_theme_font_size_override("font_size", 20)
	var hb := StyleBoxFlat.new()
	hb.bg_color = Color(0.14, 0.16, 0.22, 0.98)
	hb.set_border_width_all(1)
	hb.border_color = Color(0.45, 0.5, 0.62, 0.75)
	hb.set_corner_radius_all(8)
	hb.content_margin_left = 14
	hb.content_margin_top = 8
	hb.content_margin_right = 14
	hb.content_margin_bottom = 8
	var hb_h := hb.duplicate() as StyleBoxFlat
	hb_h.bg_color = Color(0.2, 0.23, 0.32, 1)
	var hb_p := hb.duplicate() as StyleBoxFlat
	hb_p.bg_color = Color(0.09, 0.1, 0.14, 1)
	help_btn.add_theme_stylebox_override("normal", hb)
	help_btn.add_theme_stylebox_override("hover", hb_h)
	help_btn.add_theme_stylebox_override("pressed", hb_p)
	help_btn.add_theme_color_override("font_color", Color(0.92, 0.9, 0.84, 1))
	help_btn.pressed.connect(_on_crown_help_btn_pressed)
	row.add_child(help_btn)
	panel.add_child(row)
	wrap.add_child(panel)
	main_actions.add_child(wrap)
	main_actions.move_child(wrap, 0)


func _crown_title_texture() -> Texture2D:
	var art := CrownSystem.load_current_crown_title_texture()
	if art:
		return art
	var t: Dictionary = CrownSystem.get_current_title()
	var tid := str(t.get("id", "recruit"))
	var path: String = str(_CROWN_TITLE_ICONS.get(tid, _CROWN_TITLE_ICONS["recruit"]))
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	return null


func _next_title_threshold_after(total: int) -> int:
	var next := -1
	for title in BalanceConfig.CROWN_TITLES:
		if title is Dictionary:
			var th := int(title.get("ore_threshold", 0))
			if th > total:
				if next < 0 or th < next:
					next = th
	return next


func _crown_progress_subline() -> String:
	var sent := SaveManager.ore_sent_to_crown_total
	var next_th := _next_title_threshold_after(sent)
	if next_th < 0:
		return "Отправлено руды Короне: %d — высшая ступень титула." % sent
	var need := next_th - sent
	return "Отправлено руды Короне: %d  ·  до следующего титула: %d" % [sent, need]


func _crown_effect_subline() -> String:
	var t: Dictionary = CrownSystem.get_current_title()
	var mine_b := int(t.get("mine_ore_bonus", 0))
	if mine_b > 0:
		return "Шахта при возврате с похода: +%d к руде" % mine_b
	return "Шахта: без титульного бонуса (следующие ступени дадут +руду)"


func _on_crown_title_strip_icon_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			CrownTitlePreview.show_texture(_crown_title_texture())


func _refresh_crown_title_strip() -> void:
	if _crown_title_icon == null or _crown_title_name_lbl == null:
		return
	var tex := _crown_title_texture()
	_crown_title_icon.texture = tex
	if _crown_icon_aspect:
		if tex:
			var gs := tex.get_size()
			_crown_icon_aspect.ratio = float(gs.x) / float(maxi(1, int(gs.y)))
		else:
			_crown_icon_aspect.ratio = 1.0
	_crown_title_name_lbl.text = CrownSystem.get_current_title_name()
	var dis := SaveManager.crown_displeasure
	var dis_s := ""
	if dis > 0:
		dis_s = "  ·  немилость Короны: %d" % dis
	_crown_title_sub_lbl.text = "%s%s\n%s" % [_crown_progress_subline(), dis_s, _crown_effect_subline()]


func _build_crown_help_modal() -> void:
	_crown_help_layer = CanvasLayer.new()
	_crown_help_layer.layer = 12
	_crown_help_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	_crown_help_layer.visible = false
	add_child(_crown_help_layer)
	var root := Control.new()
	root.name = "Root"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_crown_help_layer.add_child(root)
	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.02, 0.03, 0.06, 0.72)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(dim)
	var margin := MarginContainer.new()
	margin.name = "Margin"
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_top", 36)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_bottom", 36)
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(margin)
	var panel := PanelContainer.new()
	panel.name = "Panel"
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var psb := StyleBoxFlat.new()
	psb.bg_color = Color(0.08, 0.09, 0.12, 0.98)
	psb.set_border_width_all(1)
	psb.border_color = Color(0.55, 0.48, 0.32, 0.55)
	psb.set_corner_radius_all(14)
	psb.shadow_color = Color(0, 0, 0, 0.55)
	psb.shadow_size = 14
	psb.shadow_offset = Vector2(0, 6)
	psb.content_margin_left = 20
	psb.content_margin_top = 18
	psb.content_margin_right = 20
	psb.content_margin_bottom = 18
	panel.add_theme_stylebox_override("panel", psb)
	margin.add_child(panel)
	var vbox := VBoxContainer.new()
	vbox.name = "MarginVBox"
	vbox.add_theme_constant_override("separation", 12)
	panel.add_child(vbox)
	var header := HBoxContainer.new()
	var ht := Label.new()
	ht.text = "Титулы Короны"
	ht.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ht.add_theme_color_override("font_color", Color(0.94, 0.92, 0.88, 1))
	ht.add_theme_font_size_override("font_size", 32)
	var close_b := Button.new()
	close_b.text = "Закрыть"
	close_b.focus_mode = Control.FOCUS_NONE
	close_b.add_theme_font_size_override("font_size", 20)
	close_b.pressed.connect(_on_crown_help_close_pressed)
	header.add_child(ht)
	header.add_child(close_b)
	vbox.add_child(header)
	var scroll := ScrollContainer.new()
	scroll.name = "Scroll"
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(scroll)
	var scroll_v := VBoxContainer.new()
	scroll_v.name = "HelpScrollVBox"
	scroll_v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll_v.add_theme_constant_override("separation", 10)
	scroll.add_child(scroll_v)
	var rtl_intro := RichTextLabel.new()
	rtl_intro.name = "HelpIntro"
	rtl_intro.bbcode_enabled = true
	rtl_intro.fit_content = true
	rtl_intro.scroll_active = false
	rtl_intro.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rtl_intro.add_theme_color_override("default_color", Color(0.78, 0.82, 0.9, 0.98))
	rtl_intro.add_theme_font_size_override("normal_font_size", 16)
	_apply_dialogue_default_font_to_richtext(rtl_intro)
	scroll_v.add_child(rtl_intro)
	var steps_v := VBoxContainer.new()
	steps_v.name = "HelpSteps"
	steps_v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	steps_v.add_theme_constant_override("separation", 8)
	scroll_v.add_child(steps_v)
	var rtl_footer := RichTextLabel.new()
	rtl_footer.name = "HelpFooter"
	rtl_footer.bbcode_enabled = true
	rtl_footer.fit_content = true
	rtl_footer.scroll_active = false
	rtl_footer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rtl_footer.add_theme_color_override("default_color", Color(0.78, 0.82, 0.9, 0.98))
	rtl_footer.add_theme_font_size_override("normal_font_size", 16)
	_apply_dialogue_default_font_to_richtext(rtl_footer)
	scroll_v.add_child(rtl_footer)


func _rtl_theme_line(rtl: RichTextLabel) -> void:
	rtl.add_theme_color_override("default_color", Color(0.78, 0.82, 0.9, 0.98))
	rtl.add_theme_font_size_override("normal_font_size", 16)
	_apply_dialogue_default_font_to_richtext(rtl)


func _make_crown_help_title_chip(art_path: String) -> Control:
	var wrap := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.1, 0.11, 0.16, 1)
	sb.set_border_width_all(1)
	sb.border_color = Color(0.78, 0.65, 0.35, 0.4)
	sb.set_corner_radius_all(8)
	sb.content_margin_left = 4
	sb.content_margin_top = 4
	sb.content_margin_right = 4
	sb.content_margin_bottom = 4
	wrap.add_theme_stylebox_override("panel", sb)
	wrap.custom_minimum_size = Vector2(52, 52)
	wrap.mouse_filter = Control.MOUSE_FILTER_STOP
	var ar := AspectRatioContainer.new()
	ar.set_anchors_preset(Control.PRESET_FULL_RECT)
	wrap.add_child(ar)
	var tr := TextureRect.new()
	tr.set_anchors_preset(Control.PRESET_FULL_RECT)
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tex := load(art_path) as Texture2D
	tr.texture = tex
	if tex:
		var gs := tex.get_size()
		ar.ratio = float(gs.x) / float(maxi(1, int(gs.y)))
	else:
		ar.ratio = 1.0
	ar.add_child(tr)
	wrap.gui_input.connect(func(ev: InputEvent) -> void:
		if ev is InputEventMouseButton:
			var mb := ev as InputEventMouseButton
			if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
				CrownTitlePreview.show_texture_from_path(art_path)
	)
	return wrap


func _populate_crown_help_panel() -> void:
	var intro := _crown_help_layer.get_node_or_null("Root/Margin/Panel/MarginVBox/Scroll/HelpScrollVBox/HelpIntro") as RichTextLabel
	var steps := _crown_help_layer.get_node_or_null("Root/Margin/Panel/MarginVBox/Scroll/HelpScrollVBox/HelpSteps") as VBoxContainer
	var footer := _crown_help_layer.get_node_or_null("Root/Margin/Panel/MarginVBox/Scroll/HelpScrollVBox/HelpFooter") as RichTextLabel
	if intro == null or steps == null or footer == null:
		return
	var head: PackedStringArray = []
	head.append("[b]Как получить титул[/b]")
	head.append("Каждая отправка [color=#9fd4ff]руды[/color] караваном Короны увеличивает ваш [color=#e8c97a]суммарный счёт[/color]. Титул зависит только от этого счёта — не от одной партии.")
	head.append("")
	head.append("[b]Ступени[/b] (нажмите на герб, чтобы увеличить)")
	intro.text = "\n".join(head)
	for c in steps.get_children():
		c.queue_free()
	var step_i := 0
	for t in BalanceConfig.CROWN_TITLES:
		if t is Dictionary:
			var nm := str(t.get("name", ""))
			var th := int(t.get("ore_threshold", 0))
			var mb := int(t.get("mine_ore_bonus", 0))
			var bonus := "шахта +" + str(mb) if mb > 0 else "без бонуса шахты"
			var art_p := CrownSystem.get_crown_title_art_path_for_index(step_i)
			var row := HBoxContainer.new()
			row.add_theme_constant_override("separation", 12)
			row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			if ResourceLoader.exists(art_p):
				row.add_child(_make_crown_help_title_chip(art_p))
			var line := RichTextLabel.new()
			line.bbcode_enabled = true
			line.fit_content = true
			line.scroll_active = false
			line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			_rtl_theme_line(line)
			line.text = "· [color=#e8c97a]%s[/color] — с [color=#9fd4ff]%d[/color] руды всего; %s" % [nm, th, bonus]
			row.add_child(line)
			steps.add_child(row)
			step_i += 1
	var tail: PackedStringArray = []
	tail.append("")
	tail.append("[b]Эффекты в игре[/b]")
	tail.append("Сейчас титул влияет на добычу [color=#9fd4ff]шахты[/color] при возврате с острова (см. ступени выше).")
	tail.append("")
	tail.append("[b]Караван и приказы[/b]")
	tail.append("Подробности — в разделе «Караван Короны» в замке.")
	footer.text = "\n".join(tail)


func _bind_caravan_brief() -> void:
	_caravan_brief = get_node_or_null("%s/CaravanBriefScroll/CaravanBrief" % _PATH_CARAVAN_VBOX) as RichTextLabel
	if _caravan_brief:
		_apply_dialogue_default_font_to_richtext(_caravan_brief)


func _caravan_arrival_rewards_line() -> String:
	var g := BalanceConfig.get_caravan_supply_gold()
	var m := BalanceConfig.get_caravan_supply_meat()
	var dis := SaveManager.crown_displeasure
	var g_show := int(round(float(g) * BalanceConfig.get_displeasure_gold_mult(dis)))
	return "При [b]прибытии[/b] каравана на базу вы сразу получаете [color=#e8c97a]%d золота[/color] и [color=#c49a6c]%d мяса[/color] (золото при немилости снижено; сейчас уровень немилости: [color=#ff9a7a]%d[/color])." % [g_show, m, dis]


func _caravan_mechanics_bbcode() -> String:
	var lines: PackedStringArray = []
	var interval := BalanceConfig.CARAVAN_EXPEDITION_INTERVAL
	var pending := SaveManager.caravan_pending
	var exp_left := SaveManager.expeditions_until_caravan
	var order := CrownSystem.get_current_order_info()
	lines.append("[b][color=#e8c97a]Ваш титул[/color][/b]  —  %s" % CrownSystem.get_current_title_name())
	if SaveManager.crown_displeasure > 0:
		lines.append("[color=#ff9a7a]Немилость Короны %d[/color]: меньше золота в жалованье при прибытии каравана." % SaveManager.crown_displeasure)
	lines.append("")
	lines.append("[b]Что вы получаете при прибытии[/b]")
	lines.append(_caravan_arrival_rewards_line())
	lines.append("[b]Как часто приходит караван[/b]")
	lines.append("После того как караван [b]уехал[/b] с вашей отгрузкой, считаются возвращения с похода: через [color=#9fd4ff]%d[/color] возвращений прибудет следующий рейс." % interval)
	lines.append("[color=#b0b8c8]Пока у причала стоит караван и ждёт руду, походы [b]не[/b] уменьшают этот счётчик и [b]не[/b] отсчитывают срок приказа. Можно «Отпустить порожним», чтобы снова шло время.[/color]")
	lines.append("")
	if pending:
		lines.append("[b]Сейчас[/b]: караван у причала — отгрузите [color=#9fd4ff]сердцевину[/color] или отпустите пустым.")
	else:
		var left := maxi(0, exp_left)
		if left <= 0:
			lines.append("[b]Сейчас[/b]: следующее [b]возвращение[/b] с похода приведёт караван Короны.")
		else:
			lines.append("[b]Сейчас[/b]: до прибытия каравана осталось [color=#9fd4ff]%d[/color] возвращений с похода." % left)
	lines.append("")
	if order.is_empty():
		lines.append("[b]Приказ Короны[/b] появится с первым же прибытием каравана.")
	else:
		var req := int(order.get("ore_required", 0))
		var sent := int(order.get("ore_sent", 0))
		var dl := int(order.get("deadline_remaining", 0))
		lines.append("[b]Текущий приказ[/b]: сдать [color=#9fd4ff]%d[/color] руды (отгружено [color=#9fd4ff]%d[/color])." % [req, sent])
		lines.append("Срок отсчитывается в [b]походах[/b] после выдачи приказа: осталось [color=#ffb870]%d[/color]." % dl)
		lines.append("Если срок истечёт и будет отгружено [b]меньше половины[/b] нормы — растёт [color=#ff9a7a]немилость[/color] (до %d)." % BalanceConfig.DISPLEASURE_MAX_LEVEL)
		lines.append("Перевыполнение (~[b]120%%[/b] нормы за одну отгрузку после недобора) снижает немилость.")
	lines.append("")
	lines.append("[b]Титул[/b]: растёт от [b]всей[/b] отправленной Короне руды — см. плашку вверху замка или кнопку «Справка».")
	return "\n".join(lines)


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
	var quote_lbl := get_node_or_null("%s/SubtitleHire" % _PATH_HIRE_VBOX) as Label
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


## ═══════════════════════════════════════════════════════
##  КАРАВАН КОРОНЫ — подменю в замке
## ═══════════════════════════════════════════════════════

var _caravan_ore_to_send: int = 0


func _open_caravan_select() -> void:
	_close_crown_help()
	var hire := get_node_or_null("HireSelectPanel") as Control
	var upgrade := get_node_or_null("UpgradeSelectPanel") as Control
	var caravan := get_node_or_null("CaravanSelectPanel") as Control
	var main_panel := get_node_or_null("CastleMenuPanel") as CanvasItem
	if hire:
		hire.visible = false
	if upgrade:
		upgrade.visible = false
	if caravan:
		caravan.visible = true
	if main_panel:
		main_panel.visible = false
	_set_main_castle_chrome_visible(false)
	_refresh_caravan_ui()


func _close_caravan_select() -> void:
	var caravan := get_node_or_null("CaravanSelectPanel") as Control
	var main_panel := get_node_or_null("CastleMenuPanel") as CanvasItem
	if caravan:
		caravan.visible = false
	if main_panel:
		main_panel.visible = true
	_set_main_castle_chrome_visible(true)


func _refresh_caravan_ui() -> void:
	var pending := SaveManager.caravan_pending
	var ore_available := SaveManager.ore_count

	var ore_lbl := get_node_or_null("%s/OreAvailable" % _PATH_CARAVAN_VBOX) as Label
	var send_all_btn := get_node_or_null("%s/BtnRow/BtnSendAll" % _PATH_CARAVAN_VBOX) as Button
	var send_half_btn := get_node_or_null("%s/BtnRow/BtnSendHalf" % _PATH_CARAVAN_VBOX) as Button
	var dismiss_btn := get_node_or_null("%s/BtnDismiss" % _PATH_CARAVAN_VBOX) as Button

	if _caravan_brief:
		_caravan_brief.text = _caravan_mechanics_bbcode()

	if ore_lbl:
		ore_lbl.text = "Руда на складе: %d" % ore_available

	if send_all_btn:
		send_all_btn.disabled = not pending or ore_available <= 0
		send_all_btn.text = "Отправить всё (%d)" % ore_available

	if send_half_btn:
		var half := maxi(1, ore_available / 2)
		send_half_btn.disabled = not pending or ore_available <= 0
		send_half_btn.text = "Отправить половину (%d)" % half

	if dismiss_btn:
		dismiss_btn.disabled = not pending
		dismiss_btn.text = "Отпустить порожним (без отгрузки)"


func _on_caravan_pressed() -> void:
	SoundManager.play_ui_button()
	_open_caravan_select()


func _on_caravan_back_pressed() -> void:
	SoundManager.play_ui_button()
	_close_caravan_select()


func _on_send_all_pressed() -> void:
	SoundManager.play_ui_button()
	var amount := SaveManager.ore_count
	if amount <= 0:
		return
	CrownSystem.send_ore_with_caravan(amount)
	_refresh_caravan_ui()


func _on_send_half_pressed() -> void:
	SoundManager.play_ui_button()
	var amount := maxi(1, SaveManager.ore_count / 2)
	if amount <= 0:
		return
	CrownSystem.send_ore_with_caravan(amount)
	_refresh_caravan_ui()


func _on_dismiss_caravan_pressed() -> void:
	SoundManager.play_ui_button()
	CrownSystem.dismiss_caravan_empty()
	_refresh_caravan_ui()
