extends Control

enum HireKind { ARCHER, LANCER, PAWN }


func get_hud() -> Node:
	return GameplayFacade.get_hud(get_tree())


func _ru_day_word_counted(n: int) -> String:
	var a := absi(n)
	var n10 := a % 10
	var n100 := a % 100
	if n100 >= 11 and n100 <= 14:
		return "дней"
	if n10 == 1:
		return "день"
	if n10 >= 2 and n10 <= 4:
		return "дня"
	return "дней"


func _ru_day_word_genitive_after_iz(n: int) -> String:
	var a := absi(n)
	var n10 := a % 10
	var n100 := a % 100
	if n100 >= 11 and n100 <= 14:
		return "дней"
	if n10 == 1:
		return "дня"
	return "дней"


func _ru_day_word_dative_after_kraten(n: int) -> String:
	var a := absi(n)
	var n10 := a % 10
	var n100 := a % 100
	if n100 >= 11 and n100 <= 14:
		return "дням"
	if n10 == 1:
		return "дню"
	return "дням"


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
const _PATH_CARAVAN_VBOX := "CaravanSelectPanel/CCenter/CaravanPanel/CaravanInner/CaravanBodyScroll/CaravanVBox"
const _PATH_CARAVAN_SUMMARY := "%s/CaravanSummaryVBox" % _PATH_CARAVAN_VBOX
const _PATH_CARAVAN_ORDER_DEADLINE_VBOX := "%s/CaravanOrderPanel/OrderMargin/OrderVBox/CaravanDeadlineStrip/DeadlineMargin/DeadlineVBox" % _PATH_CARAVAN_SUMMARY
const _CARAVAN_DOT_SLOTS_MAX := 12

var _crown_help_layer: CanvasLayer
var _crown_help_tab_index: int = 0
var _crown_help_tab_buttons: Array[Button] = []
var _crown_help_tab_scrolls: Array[ScrollContainer] = []
var _crown_icon_aspect: AspectRatioContainer
var _crown_title_icon: TextureRect
var _crown_title_name_lbl: Label
var _crown_title_sub_lbl: Label
var _crown_mood_accent: ColorRect
var _crown_mood_headline: Label
var _crown_mood_detail: Label
var _crown_mood_strip_panel: PanelContainer
var _crown_mood_panel_style_normal: StyleBoxFlat
var _crown_mood_panel_style_hover: StyleBoxFlat
var _crown_mood_effects_layer: CanvasLayer
var _crown_mood_effects_rtl: RichTextLabel
var _caravan_brief: RichTextLabel
var _caravan_details_scroll: ScrollContainer
var _caravan_details_btn: Button
var _caravan_details_expanded: bool = false
var _caravan_dot_row: HBoxContainer
var _caravan_reward_gold: Label
var _caravan_reward_meat: Label
var _caravan_reward_extra: Label
var _caravan_totals_line: Label
var _caravan_flavor_line: Label
var _caravan_pending_hint: Label
var _caravan_warning_line: Label
var _caravan_order_title: Label
var _caravan_order_ore_lbl: Label
var _caravan_order_ore_bar: ProgressBar
var _caravan_order_dl_lbl: Label
var _caravan_order_dl_bar: ProgressBar
var _caravan_deadline_strip: PanelContainer
var _caravan_deadline_head: Label
var _caravan_dot_panels: Array[Panel] = []
var _caravan_dl_bar_style_bg: StyleBoxFlat
var _caravan_dl_bar_style_fill: StyleBoxFlat
var _caravan_dot_style_fill: StyleBoxFlat
var _caravan_dot_style_dim: StyleBoxFlat
var _caravan_dot_style_hold: StyleBoxFlat

var _touch_scroll_helper := TouchScrollHelper.new()


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
	_ensure_crown_mood_strip()
	_build_crown_mood_effects_modal_if_needed()
	_build_crown_help_modal()
	_setup_caravan_panel_nodes()
	_refresh_crown_title_strip()
	_touch_scroll_helper.add_root(self)
	set_process_input(true)
	if not Events.crown_title_changed.is_connected(_on_crown_title_changed_ui):
		Events.crown_title_changed.connect(_on_crown_title_changed_ui)
	if not Events.crown_displeasure_changed.is_connected(_on_crown_displeasure_changed_ui):
		Events.crown_displeasure_changed.connect(_on_crown_displeasure_changed_ui)
	if not Events.crown_favor_changed.is_connected(_on_crown_favor_changed_ui):
		Events.crown_favor_changed.connect(_on_crown_favor_changed_ui)
	if not Events.caravan_arrived.is_connected(_on_caravan_event_refresh_ui):
		Events.caravan_arrived.connect(_on_caravan_event_refresh_ui)
	if not Events.caravan_dispatched.is_connected(_on_caravan_event_refresh_ui):
		Events.caravan_dispatched.connect(_on_caravan_event_refresh_ui)
	if not Events.caravan_pending_changed.is_connected(_on_caravan_pending_changed_ui):
		Events.caravan_pending_changed.connect(_on_caravan_pending_changed_ui)
	if not visibility_changed.is_connected(_on_castle_root_visibility_changed):
		visibility_changed.connect(_on_castle_root_visibility_changed)
	if not Events.gold_changed.is_connected(_on_castle_shop_resources_changed):
		Events.gold_changed.connect(_on_castle_shop_resources_changed)
	if not Events.wood_changed.is_connected(_on_castle_shop_resources_changed):
		Events.wood_changed.connect(_on_castle_shop_resources_changed)
	if not Events.ore_changed.is_connected(_on_castle_shop_resources_changed):
		Events.ore_changed.connect(_on_castle_shop_resources_changed)
	if not Events.meat_changed.is_connected(_on_castle_shop_resources_changed):
		Events.meat_changed.connect(_on_castle_shop_resources_changed)


func _exit_tree() -> void:
	if Events.gold_changed.is_connected(_on_castle_shop_resources_changed):
		Events.gold_changed.disconnect(_on_castle_shop_resources_changed)
	if Events.wood_changed.is_connected(_on_castle_shop_resources_changed):
		Events.wood_changed.disconnect(_on_castle_shop_resources_changed)
	if Events.ore_changed.is_connected(_on_castle_shop_resources_changed):
		Events.ore_changed.disconnect(_on_castle_shop_resources_changed)
	if Events.meat_changed.is_connected(_on_castle_shop_resources_changed):
		Events.meat_changed.disconnect(_on_castle_shop_resources_changed)


func _on_castle_shop_resources_changed(_value: int) -> void:
	if not visible:
		return
	_refresh_hire_buy_ui()
	var upgrade := get_node_or_null("UpgradeSelectPanel") as Control
	if upgrade != null and upgrade.visible:
		_refresh_upgrade_building_buttons()


func _on_castle_root_visibility_changed() -> void:
	if not visible:
		_touch_scroll_helper.reset()
		_hide_crown_mood_effects_modal()
		_close_crown_help()
		return
	_refresh_crown_title_strip()
	_refresh_caravan_slot_badge()
	_refresh_hire_buy_ui()
	var upgrade := get_node_or_null("UpgradeSelectPanel") as Control
	if upgrade != null and upgrade.visible:
		_refresh_upgrade_building_buttons()


func _on_caravan_pending_changed_ui(_pending: bool) -> void:
	_refresh_caravan_slot_badge()
	_refresh_caravan_ui_if_open()


func _on_crown_title_changed_ui(_idx: int, _name: String) -> void:
	_refresh_crown_title_strip()
	_refresh_caravan_ui_if_open()


func _on_crown_displeasure_changed_ui(_lvl: int) -> void:
	_refresh_crown_title_strip()
	_refresh_caravan_ui_if_open()


func _on_crown_favor_changed_ui(_lvl: int) -> void:
	_refresh_crown_title_strip()
	_refresh_caravan_ui_if_open()


func _on_caravan_event_refresh_ui(_a = null, _b = null) -> void:
	_refresh_caravan_ui_if_open()


func _refresh_caravan_ui_if_open() -> void:
	var csp := get_node_or_null("CaravanSelectPanel") as Control
	if csp and csp.visible:
		_refresh_caravan_ui()


func reset_castle_menu_state() -> void:
	if CrownTitlePreview.visible:
		CrownTitlePreview.hide_preview()
	_hide_crown_mood_effects_modal()
	_close_crown_help()
	_close_upgrade_select()
	_close_hire_select()
	_close_caravan_select()
	var main_panel := get_node_or_null("CastleMenuPanel") as CanvasItem
	if main_panel:
		main_panel.visible = true
	_refresh_crown_title_strip()
	_refresh_caravan_slot_badge()


func _refresh_hire_buy_ui() -> void:
	var ore_cost := BalanceConfig.get_unit_hire_ore_cost()
	var price_lbl := get_node_or_null("%s/HirePriceLabel" % _PATH_HIRE_VBOX) as Label
	if price_lbl:
		price_lbl.text = "Все типы: %d зол. и %d Сердцевины" % [unit_hire_cost, ore_cost]
	for path_kind in [
		["%s/HireSlotsRow/slot_archer/ColumnArcher/BuyArcher" % _PATH_HIRE_VBOX, HireKind.ARCHER],
		["%s/HireSlotsRow/slot_lancer/ColumnLancer/BuyLancer" % _PATH_HIRE_VBOX, HireKind.LANCER],
		["%s/HireSlotsRow/slot_pawn/ColumnPawn/BuyPawn" % _PATH_HIRE_VBOX, HireKind.PAWN],
	]:
		var path: String = path_kind[0]
		var kind: HireKind = path_kind[1]
		var b := get_node_or_null(path) as Button
		if b:
			b.text = ""
		var gl := get_node_or_null("%s/CostRow/GoldCostRow/GoldCostLabel" % path) as Label
		var ol := get_node_or_null("%s/CostRow/OreCostRow/OreCostLabel" % path) as Label
		if gl:
			gl.text = str(unit_hire_cost)
		if ol:
			ol.text = str(ore_cost)
		if b:
			PaidServiceButtonAppearance.set_interactive(b, _can_hire_kind(kind))


func try_close_crown_mood_effects_modal() -> bool:
	if _crown_mood_effects_layer == null or not _crown_mood_effects_layer.visible:
		return false
	_hide_crown_mood_effects_modal()
	return true


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
			btn.icon = null
			btn.text = "Максимум"
			if cost_row:
				cost_row.visible = false
			PaidServiceButtonAppearance.set_interactive(btn, false)
			continue
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
		var can_upgrade := GameplayFacade.can_afford_building_upgrade(gold_cost, wood_cost, ore_cost)
		PaidServiceButtonAppearance.set_interactive(btn, can_upgrade)


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
	_set_crown_help_tab(0)
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


func _ensure_crown_mood_strip() -> void:
	## Немилость / одобрение Короны — только в замке (не в HUD).
	var main_actions := get_node_or_null(_PATH_MAIN_ACTIONS) as VBoxContainer
	if main_actions == null or main_actions.get_node_or_null("CrownMoodStrip"):
		return
	var wrap := MarginContainer.new()
	wrap.name = "CrownMoodStrip"
	wrap.add_theme_constant_override("margin_bottom", 6)
	var panel := PanelContainer.new()
	var psb := StyleBoxFlat.new()
	psb.bg_color = Color(0.05, 0.06, 0.09, 0.96)
	psb.set_border_width_all(1)
	psb.border_color = Color(0.42, 0.38, 0.52, 0.45)
	psb.set_corner_radius_all(10)
	psb.content_margin_left = 12
	psb.content_margin_top = 8
	psb.content_margin_right = 14
	psb.content_margin_bottom = 8
	panel.add_theme_stylebox_override("panel", psb)
	_crown_mood_strip_panel = panel
	_crown_mood_panel_style_normal = psb
	_crown_mood_panel_style_hover = psb.duplicate() as StyleBoxFlat
	_crown_mood_panel_style_hover.border_color = Color(0.58, 0.52, 0.75, 0.88)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	panel.gui_input.connect(_on_crown_mood_strip_gui_input)
	if not panel.mouse_entered.is_connected(_on_crown_mood_strip_mouse_entered):
		panel.mouse_entered.connect(_on_crown_mood_strip_mouse_entered)
	if not panel.mouse_exited.is_connected(_on_crown_mood_strip_mouse_exited):
		panel.mouse_exited.connect(_on_crown_mood_strip_mouse_exited)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	_crown_mood_accent = ColorRect.new()
	_crown_mood_accent.custom_minimum_size = Vector2(5, 0)
	_crown_mood_accent.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_crown_mood_accent.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(_crown_mood_accent)
	var text_col := VBoxContainer.new()
	text_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_col.add_theme_constant_override("separation", 2)
	_crown_mood_headline = Label.new()
	_crown_mood_headline.add_theme_font_size_override("font_size", 21)
	_crown_mood_detail = Label.new()
	_crown_mood_detail.add_theme_font_size_override("font_size", 15)
	_crown_mood_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_col.add_child(_crown_mood_headline)
	text_col.add_child(_crown_mood_detail)
	row.add_child(text_col)
	panel.add_child(row)
	wrap.add_child(panel)
	main_actions.add_child(wrap)
	var strip := main_actions.get_node_or_null("CrownTitleStrip")
	if strip != null:
		main_actions.move_child(wrap, strip.get_index() + 1)
	_refresh_crown_mood_strip()


func _build_crown_mood_effects_modal_if_needed() -> void:
	if _crown_mood_effects_layer != null:
		return
	_crown_mood_effects_layer = CanvasLayer.new()
	_crown_mood_effects_layer.layer = 13
	_crown_mood_effects_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	_crown_mood_effects_layer.visible = false
	add_child(_crown_mood_effects_layer)
	var root := Control.new()
	root.name = "CrownMoodEffectsRoot"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_crown_mood_effects_layer.add_child(root)
	var dim := ColorRect.new()
	dim.name = "Dim"
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.02, 0.03, 0.06, 0.65)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.gui_input.connect(_on_crown_mood_effects_dim_gui_input)
	root.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(420, 200)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var psb := StyleBoxFlat.new()
	psb.bg_color = Color(0.07, 0.08, 0.11, 0.99)
	psb.set_border_width_all(1)
	psb.border_color = Color(0.5, 0.44, 0.62, 0.65)
	psb.set_corner_radius_all(14)
	psb.content_margin_left = 18
	psb.content_margin_top = 14
	psb.content_margin_right = 18
	psb.content_margin_bottom = 16
	panel.add_theme_stylebox_override("panel", psb)
	center.add_child(panel)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	panel.add_child(vbox)
	var header := HBoxContainer.new()
	var ht := Label.new()
	ht.text = "Влияние на базу"
	ht.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ht.add_theme_color_override("font_color", Color(0.92, 0.88, 0.82, 1))
	ht.add_theme_font_size_override("font_size", 22)
	var close_b := Button.new()
	close_b.text = "Закрыть"
	close_b.focus_mode = Control.FOCUS_NONE
	close_b.add_theme_font_size_override("font_size", 18)
	close_b.pressed.connect(_on_crown_mood_effects_close_pressed)
	header.add_child(ht)
	header.add_child(close_b)
	vbox.add_child(header)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size = Vector2(0, 220)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(scroll)
	_crown_mood_effects_rtl = RichTextLabel.new()
	_crown_mood_effects_rtl.bbcode_enabled = true
	_crown_mood_effects_rtl.fit_content = true
	_crown_mood_effects_rtl.scroll_active = false
	_crown_mood_effects_rtl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_crown_mood_effects_rtl.add_theme_color_override("default_color", Color(0.82, 0.86, 0.92, 0.95))
	_crown_mood_effects_rtl.add_theme_font_size_override("normal_font_size", 16)
	_crown_mood_effects_rtl.custom_minimum_size = Vector2(380, 0)
	_apply_dialogue_default_font_to_richtext(_crown_mood_effects_rtl)
	scroll.add_child(_crown_mood_effects_rtl)


func _on_crown_mood_effects_dim_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			_hide_crown_mood_effects_modal()


func _on_crown_mood_effects_close_pressed() -> void:
	SoundManager.play_ui_button()
	_hide_crown_mood_effects_modal()


func _hide_crown_mood_effects_modal() -> void:
	if _crown_mood_effects_layer:
		_crown_mood_effects_layer.hide()


func _on_crown_mood_strip_mouse_entered() -> void:
	if _crown_mood_strip_panel and _crown_mood_panel_style_hover:
		_crown_mood_strip_panel.add_theme_stylebox_override("panel", _crown_mood_panel_style_hover)


func _on_crown_mood_strip_mouse_exited() -> void:
	if _crown_mood_strip_panel and _crown_mood_panel_style_normal:
		_crown_mood_strip_panel.add_theme_stylebox_override("panel", _crown_mood_panel_style_normal)


func _on_crown_mood_strip_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			SoundManager.play_ui_button()
			_show_crown_mood_effects_modal()
			get_viewport().set_input_as_handled()


func _show_crown_mood_effects_modal() -> void:
	if _crown_mood_effects_layer == null or _crown_mood_effects_rtl == null:
		return
	_crown_mood_effects_rtl.text = _format_crown_mood_effects_bbcode()
	_crown_mood_effects_layer.show()


func _format_crown_mood_effects_bbcode() -> String:
	var d := SaveManager.crown_displeasure
	var f := SaveManager.crown_favor
	var out: PackedStringArray = []
	if d > 0:
		out.append("[b][color=#e8a090]Немилость · уровень %d[/color][/b]\n" % d)
		var g_m := BalanceConfig.get_crown_caravan_gold_mult(d, 0)
		out.append(
			"• Жалованье каравана (настроение): [color=#ffaaaa]%d%%[/color] к базовой сумме; бонус титула умножается сверху\n"
			% int(round(g_m * 100.0))
		)
		var b_m := BalanceConfig.get_crown_building_cost_mult(d, 0)
		out.append(
			"• Улучшения зданий (настроение): [color=#ffaaaa]+%d%%[/color] к золоту, дереву и руде; скидка титула — отдельно\n"
			% int(round((b_m - 1.0) * 100.0))
		)
		var hi_m := BalanceConfig.get_crown_hire_cost_mult(d, 0)
		out.append(
			"• Найм в казарме: [color=#ffaaaa]+%d%%[/color] к золоту и руде\n"
			% int(round((hi_m - 1.0) * 100.0))
		)
		var h_m := BalanceConfig.get_supply_heal_mult(d, 0)
		out.append(
			"• Исцеление у целителя: [color=#ffaaaa]%d%%[/color] эффективности\n" % int(round(h_m * 100.0))
		)
		var r_m := BalanceConfig.get_supply_rest_mult(d, 0)
		out.append(
			"• Привал на острове: [color=#ffaaaa]%d%%[/color] к объёму исцеления\n" % int(round(r_m * 100.0))
		)
		var s_m := BalanceConfig.get_supply_service_cost_mult(d, 0)
		out.append(
			"• Услуги на базе — оружейная, монастырь и др.: [color=#ffaaaa]×%.2f[/color] к цене\n" % s_m
		)
		var a_m := BalanceConfig.get_supply_archer_damage_mult(d, 0)
		out.append(
			"• Урон лучников: [color=#ffaaaa]%d%%[/color] от обычного\n" % int(round(a_m * 100.0))
		)
		var rg0 := BalanceConfig.get_armor_repair_gold_cost(0, 0)
		var rgd := BalanceConfig.get_armor_repair_gold_cost(d, 0)
		var ro0 := BalanceConfig.get_armor_repair_ore_cost(0, 0)
		var rod := BalanceConfig.get_armor_repair_ore_cost(d, 0)
		if rg0 > 0:
			var gold_x := int(round((float(rgd) / float(rg0) - 1.0) * 100.0))
			if ro0 > 0:
				var ore_x := int(round((float(rod) / float(ro0) - 1.0) * 100.0))
				out.append(
					"• Ремонт снаряжения: золото [color=#ffaaaa]+%d%%[/color], руда [color=#ffaaaa]+%d%%[/color] к цене без немилости\n"
					% [gold_x, ore_x]
				)
			else:
				out.append(
					"• Ремонт снаряжения: золото [color=#ffaaaa]+%d%%[/color] к цене без немилости\n" % gold_x
				)
		else:
			out.append("• Ремонт снаряжения: дороже при немилости\n")
	elif f > 0:
		out.append("[b][color=#7ed4a8]Одобрение · уровень %d[/color][/b]\n" % f)
		var g_f := BalanceConfig.get_crown_caravan_gold_mult(0, f)
		out.append(
			"• Жалованье каравана (настроение): [color=#a8e8c8]+%d%%[/color] к базовой сумме; бонус титула умножается сверху\n"
			% int(round((g_f - 1.0) * 100.0))
		)
		var b_f := BalanceConfig.get_crown_building_cost_mult(0, f)
		out.append(
			"• Улучшения зданий (настроение): [color=#a8e8c8]−%d%%[/color] к золоту, дереву и руде (с титулом — суммируется)\n"
			% int(round((1.0 - b_f) * 100.0))
		)
		var hi_f := BalanceConfig.get_crown_hire_cost_mult(0, f)
		out.append(
			"• Найм в казарме: [color=#a8e8c8]−%d%%[/color] к золоту и руде\n"
			% int(round((1.0 - hi_f) * 100.0))
		)
		var h_mf := BalanceConfig.get_supply_heal_mult(0, f)
		out.append(
			"• Исцеление у целителя: [color=#a8e8c8]%d%%[/color] эффективности\n" % int(round(h_mf * 100.0))
		)
		var r_mf := BalanceConfig.get_supply_rest_mult(0, f)
		out.append(
			"• Привал на острове: [color=#a8e8c8]%d%%[/color] к объёму исцеления\n" % int(round(r_mf * 100.0))
		)
		var s_mf := BalanceConfig.get_supply_service_cost_mult(0, f)
		out.append(
			"• Услуги на базе: [color=#a8e8c8]×%.2f[/color] к цене, скидка\n" % s_mf
		)
		var a_mf := BalanceConfig.get_supply_archer_damage_mult(0, f)
		out.append(
			"• Урон лучников: [color=#a8e8c8]%d%%[/color] от обычного\n" % int(round(a_mf * 100.0))
		)
		var rg0f := BalanceConfig.get_armor_repair_gold_cost(0, 0)
		var rgff := BalanceConfig.get_armor_repair_gold_cost(0, f)
		var ro0f := BalanceConfig.get_armor_repair_ore_cost(0, 0)
		var roff := BalanceConfig.get_armor_repair_ore_cost(0, f)
		if rg0f > 0:
			var gp := int(round((float(rgff) / float(rg0f)) * 100.0))
			if ro0f > 0:
				var op := int(round((float(roff) / float(ro0f)) * 100.0))
				out.append(
					"• Ремонт снаряжения: золото [color=#a8e8c8]%d%%[/color], руда [color=#a8e8c8]%d%%[/color] от цены без одобрения\n"
					% [gp, op]
				)
			else:
				out.append(
					"• Ремонт снаряжения: золото [color=#a8e8c8]%d%%[/color] от цены без одобрения\n" % gp
				)
	else:
		out.append("[b][color=#d4c49a]Стандартные отношения[/color][/b]\n")
		out.append(
			"• Без немилости и одобрения цены найма и улучшений зданий — базовые (× сложность); услуги и ремонт — без королевской надбавки.\n"
		)
		out.append(
			"• Жалованье каравана: [color=#b8c4d8]титул[/color] увеличивает золото; одобрение или немилость сдвигают базу ещё сильнее.\n"
		)
		out.append(
			"\n[i]Выполняйте приказы караваном — растёт одобрение (дешевле всё перечисленное и щедрее жалованье). Срыв сроков — немилость. Сила эффекта зависит от уровня сложности.[/i]"
		)
	return "".join(out)


func _refresh_crown_mood_strip() -> void:
	if _crown_mood_headline == null or _crown_mood_detail == null:
		return
	var d := SaveManager.crown_displeasure
	var f := SaveManager.crown_favor
	var accent: Color
	if d > 0:
		accent = Color(0.78, 0.32, 0.26, 1)
		var rn: Array[String] = ["I", "II", "III"]
		_crown_mood_headline.text = "Немилость · %s" % rn[clampi(d - 1, 0, 2)]
		_crown_mood_headline.add_theme_color_override("font_color", Color(0.96, 0.74, 0.68, 1))
		var dlines: Array[String] = [
			"Снабжение урезано",
			"Снабжение сильно урезано",
			"Критический дефицит снабжения",
		]
		_crown_mood_detail.text = dlines[clampi(d - 1, 0, 2)]
	elif f > 0:
		accent = Color(0.32, 0.72, 0.52, 1)
		var rn2: Array[String] = ["I", "II", "III"]
		_crown_mood_headline.text = "Одобрение · %s" % rn2[clampi(f - 1, 0, 2)]
		_crown_mood_headline.add_theme_color_override("font_color", Color(0.68, 0.94, 0.82, 1))
		var flines: Array[String] = [
			"Улучшенное снабжение",
			"Усиленное снабжение",
			"Элитное снабжение",
		]
		_crown_mood_detail.text = flines[clampi(f - 1, 0, 2)]
	else:
		accent = Color(0.62, 0.52, 0.34, 1)
		_crown_mood_headline.text = "Отношения с Короной"
		_crown_mood_headline.add_theme_color_override("font_color", Color(0.9, 0.86, 0.78, 1))
		_crown_mood_detail.text = "Стандартное снабжение и услуги на базе"
	if _crown_mood_accent:
		_crown_mood_accent.color = accent
	_crown_mood_detail.add_theme_color_override("font_color", Color(0.72, 0.76, 0.84, 0.88))


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
		return "Отправлено Короне Сердцевины: %d — высшая ступень титула." % sent
	var need := next_th - sent
	return "Отправлено Короне Сердцевины: %d  ·  до следующего титула: %d" % [sent, need]


func _on_crown_title_strip_icon_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			CrownTitlePreview.show_texture(_crown_title_texture())


func _refresh_crown_title_strip() -> void:
	if _crown_title_icon == null or _crown_title_name_lbl == null:
		_refresh_crown_mood_strip()
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
	var sub := CrownSystem.get_current_title_flavor()
	var grat := BalanceConfig.get_patron_title_gratitude_epithet(SaveManager.premium_ore_purchased_total)
	if not grat.is_empty():
		sub = "%s\n\n%s" % [sub, grat]
	_crown_title_sub_lbl.text = sub
	_refresh_crown_mood_strip()


func _build_crown_help_modal() -> void:
	_crown_help_tab_buttons.clear()
	_crown_help_tab_scrolls.clear()
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
	var tab_row := HBoxContainer.new()
	tab_row.name = "TabBar"
	tab_row.add_theme_constant_override("separation", 8)
	tab_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var tab_labels := ["Обзор", "Ступени", "Караван"]
	for i in range(tab_labels.size()):
		var tb := Button.new()
		tb.name = "TabBtn%d" % i
		tb.text = tab_labels[i]
		tb.focus_mode = Control.FOCUS_NONE
		tb.custom_minimum_size = Vector2(96, 42)
		tb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tb.add_theme_font_size_override("font_size", 17)
		tb.add_theme_color_override("font_color", Color(0.92, 0.9, 0.84, 1))
		tb.pressed.connect(_on_crown_help_tab_pressed.bind(i))
		tab_row.add_child(tb)
		_crown_help_tab_buttons.append(tb)
	vbox.add_child(tab_row)
	var host := Control.new()
	host.name = "TabContentHost"
	host.size_flags_vertical = Control.SIZE_EXPAND_FILL
	host.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	host.custom_minimum_size = Vector2(0, 260)
	vbox.add_child(host)
	var s0 := _crown_help_add_tab_scroll(host, "OverviewVBox")
	s0.name = "ScrollOverview"
	var s1 := _crown_help_add_tab_scroll(host, "TitlesVBox")
	s1.name = "ScrollTitles"
	s1.visible = false
	var s2 := _crown_help_add_tab_scroll(host, "CaravanVBox")
	s2.name = "ScrollCaravan"
	s2.visible = false
	_crown_help_tab_scrolls.append(s0)
	_crown_help_tab_scrolls.append(s1)
	_crown_help_tab_scrolls.append(s2)
	_set_crown_help_tab(0)


func _crown_help_add_tab_scroll(host: Control, inner_name: String) -> ScrollContainer:
	var sc := ScrollContainer.new()
	sc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	sc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	host.add_child(sc)
	var inner := VBoxContainer.new()
	inner.name = inner_name
	inner.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inner.add_theme_constant_override("separation", 14)
	sc.add_child(inner)
	return sc


func _crown_help_tab_stylebox(selected: bool) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.set_corner_radius_all(8)
	sb.content_margin_left = 12
	sb.content_margin_top = 8
	sb.content_margin_right = 12
	sb.content_margin_bottom = 8
	if selected:
		sb.bg_color = Color(0.16, 0.18, 0.26, 1)
		sb.set_border_width_all(2)
		sb.border_color = Color(0.82, 0.68, 0.36, 0.95)
	else:
		sb.bg_color = Color(0.1, 0.11, 0.15, 0.96)
		sb.set_border_width_all(1)
		sb.border_color = Color(0.38, 0.42, 0.52, 0.55)
	return sb


func _style_crown_help_tab_button(btn: Button, selected: bool) -> void:
	var n := _crown_help_tab_stylebox(selected)
	var h := n.duplicate() as StyleBoxFlat
	h.bg_color = Color(0.22, 0.24, 0.32, 1)
	var p := n.duplicate() as StyleBoxFlat
	p.bg_color = Color(0.08, 0.09, 0.12, 1)
	btn.add_theme_stylebox_override("normal", n)
	btn.add_theme_stylebox_override("hover", h)
	btn.add_theme_stylebox_override("pressed", p)


func _set_crown_help_tab(idx: int) -> void:
	if _crown_help_tab_scrolls.is_empty():
		return
	idx = clampi(idx, 0, _crown_help_tab_scrolls.size() - 1)
	_crown_help_tab_index = idx
	for i in range(_crown_help_tab_scrolls.size()):
		_crown_help_tab_scrolls[i].visible = (i == idx)
	for i in range(_crown_help_tab_buttons.size()):
		_style_crown_help_tab_button(_crown_help_tab_buttons[i], i == idx)


func _on_crown_help_tab_pressed(tab_idx: int) -> void:
	SoundManager.play_ui_button()
	_set_crown_help_tab(tab_idx)


func _on_crown_help_go_caravan_pressed() -> void:
	SoundManager.play_ui_button()
	_open_caravan_select()


func _crown_help_short_serdtsevina_bbcode() -> String:
	return (
		"[b]Сердцевина[/b] — ресурс островов и шахты; на базе тратится на услуги и найм. "
		+ "Всё, что вы [color=#9fd4ff]отправите Короне караваном[/color], остаётся в зачёте навсегда: "
		+ "от этого растёт [color=#e8c97a]титул[/color] — жалованье, лимит вывоза Сердцевины с острова и скидки в замке."
	)


func _crown_title_bonus_lines(t: Dictionary) -> PackedStringArray:
	return BalanceConfig.crown_title_bonus_summary_lines(t)


func _crown_help_title_card_style(current: bool) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.set_corner_radius_all(10)
	sb.content_margin_left = 14
	sb.content_margin_top = 12
	sb.content_margin_right = 14
	sb.content_margin_bottom = 12
	if current:
		sb.bg_color = Color(0.13, 0.15, 0.22, 1)
		sb.set_border_width_all(2)
		sb.border_color = Color(0.88, 0.72, 0.38, 0.98)
	else:
		sb.bg_color = Color(0.09, 0.1, 0.14, 1)
		sb.set_border_width_all(1)
		sb.border_color = Color(0.55, 0.48, 0.32, 0.45)
	return sb


func _make_crown_help_section_title(text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 20)
	l.add_theme_color_override("font_color", Color(0.94, 0.9, 0.78, 1))
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return l


func _make_crown_help_body_label(text: String, font_size: int = 15) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", Color(0.76, 0.8, 0.9, 0.96))
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return l


func _make_crown_help_bullet_label(text: String) -> Label:
	var l := Label.new()
	l.text = "•  %s" % text
	l.add_theme_font_size_override("font_size", 14)
	l.add_theme_color_override("font_color", Color(0.72, 0.78, 0.88, 0.95))
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return l


func _add_crown_help_progress_block(parent: VBoxContainer) -> void:
	var sent := SaveManager.ore_sent_to_crown_total
	var next_th := _next_title_threshold_after(sent)
	var idx := BalanceConfig.get_crown_title_index_for_ore_sent(sent)
	var cur_th := 0
	if idx >= 0 and idx < BalanceConfig.CROWN_TITLES.size():
		var td: Variant = BalanceConfig.CROWN_TITLES[idx]
		if td is Dictionary:
			cur_th = int((td as Dictionary).get("ore_threshold", 0))
	var wrap := PanelContainer.new()
	wrap.add_theme_stylebox_override("panel", _crown_help_title_card_style(false))
	var inner := VBoxContainer.new()
	inner.add_theme_constant_override("separation", 8)
	var cap := Label.new()
	cap.add_theme_font_size_override("font_size", 17)
	cap.add_theme_color_override("font_color", Color(0.88, 0.82, 0.7, 1))
	cap.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	cap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var bar := ProgressBar.new()
	bar.custom_minimum_size = Vector2(0, 22)
	bar.show_percentage = false
	var bar_fill := StyleBoxFlat.new()
	bar_fill.bg_color = Color(0.4, 0.62, 0.88, 1)
	bar_fill.set_corner_radius_all(5)
	bar.add_theme_stylebox_override("fill", bar_fill)
	var bar_bg := StyleBoxFlat.new()
	bar_bg.bg_color = Color(0.11, 0.12, 0.16, 1)
	bar_bg.set_corner_radius_all(5)
	bar.add_theme_stylebox_override("background", bar_bg)
	var sub := Label.new()
	sub.add_theme_font_size_override("font_size", 14)
	sub.add_theme_color_override("font_color", Color(0.7, 0.76, 0.86, 0.92))
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sub.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if next_th < 0:
		cap.text = "Ваш титул"
		bar.visible = false
		sub.text = "Вы на высшей ступени. Через караван Короне уже ушло %d ед. Сердцевины." % sent
	else:
		var span := maxi(1, next_th - cur_th)
		var done := clampi(sent - cur_th, 0, span)
		cap.text = "До следующего титула"
		bar.min_value = 0.0
		bar.max_value = float(span)
		bar.value = float(done)
		var need := maxi(0, next_th - sent)
		sub.text = "Короне отдано за всю игру: %d ед. До следующего звания не хватает ещё %d." % [sent, need]
	inner.add_child(cap)
	inner.add_child(bar)
	inner.add_child(sub)
	wrap.add_child(inner)
	parent.add_child(wrap)


func _build_crown_help_title_card(t: Dictionary, step_i: int, is_current: bool) -> Control:
	var nm := str(t.get("name", ""))
	var th := int(t.get("ore_threshold", 0))
	var art_p := CrownSystem.get_crown_title_art_path_for_index(step_i)
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", _crown_help_title_card_style(is_current))
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var outer := MarginContainer.new()
	outer.add_theme_constant_override("margin_left", 0)
	outer.add_theme_constant_override("margin_top", 0)
	outer.add_theme_constant_override("margin_right", 0)
	outer.add_theme_constant_override("margin_bottom", 0)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if ResourceLoader.exists(art_p):
		var chip := _make_crown_help_title_chip(art_p)
		chip.custom_minimum_size = Vector2(58, 58)
		row.add_child(chip)
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 6)
	var title_row := HBoxContainer.new()
	title_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var name_l := Label.new()
	name_l.text = nm
	name_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_l.add_theme_font_size_override("font_size", 18)
	name_l.add_theme_color_override("font_color", Color(0.92, 0.82, 0.55, 1))
	name_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title_row.add_child(name_l)
	if is_current:
		var bs := StyleBoxFlat.new()
		bs.bg_color = Color(0.78, 0.65, 0.35, 0.85)
		bs.set_corner_radius_all(6)
		bs.content_margin_left = 8
		bs.content_margin_top = 4
		bs.content_margin_right = 8
		bs.content_margin_bottom = 4
		var badge_wrap := PanelContainer.new()
		badge_wrap.add_theme_stylebox_override("panel", bs)
		var badge := Label.new()
		badge.text = "Ваш титул"
		badge.add_theme_font_size_override("font_size", 13)
		badge.add_theme_color_override("font_color", Color(0.15, 0.12, 0.08, 1))
		badge_wrap.add_child(badge)
		title_row.add_child(badge_wrap)
	col.add_child(title_row)
	var th_l := _make_crown_help_body_label(
		"Эта ступень — когда Короне за всю игру ушло не меньше %d ед. Сердцевины караваном." % th, 14
	)
	th_l.add_theme_color_override("font_color", Color(0.65, 0.78, 0.95, 0.95))
	col.add_child(th_l)
	var bonus_title := Label.new()
	bonus_title.text = "Бонусы ступени"
	bonus_title.add_theme_font_size_override("font_size", 13)
	bonus_title.add_theme_color_override("font_color", Color(0.55, 0.6, 0.7, 0.9))
	col.add_child(bonus_title)
	for line in _crown_title_bonus_lines(t):
		col.add_child(_make_crown_help_bullet_label(line))
	row.add_child(col)
	outer.add_child(row)
	card.add_child(outer)
	return card


func _clear_vbox_children(v: VBoxContainer) -> void:
	for c in v.get_children():
		v.remove_child(c)
		c.free()


func _populate_crown_help_overview(vbox: VBoxContainer) -> void:
	_clear_vbox_children(vbox)
	var rtl := RichTextLabel.new()
	rtl.bbcode_enabled = true
	rtl.fit_content = true
	rtl.scroll_active = false
	rtl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_rtl_theme_line(rtl)
	rtl.text = _crown_help_short_serdtsevina_bbcode()
	vbox.add_child(rtl)
	var hint := RichTextLabel.new()
	hint.bbcode_enabled = true
	hint.fit_content = true
	hint.scroll_active = false
	hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_rtl_theme_line(hint)
	hint.add_theme_font_size_override("normal_font_size", 14)
	hint.add_theme_color_override("default_color", Color(0.65, 0.72, 0.82, 0.9))
	hint.text = "Подробнее о ресурсе — «Справка» в кодексе лагеря. Про караван, приказы и походы — вкладка [color=#e8c97a]«Караван»[/color]."
	vbox.add_child(hint)
	vbox.add_child(HSeparator.new())
	_add_crown_help_progress_block(vbox)
	vbox.add_child(_make_crown_help_section_title("Сейчас"))
	var cur := CrownSystem.get_current_title()
	vbox.add_child(_make_crown_help_body_label("Титул: %s" % str(cur.get("name", "")), 16))
	vbox.add_child(_make_crown_help_body_label(_crown_progress_subline(), 14))
	var dis := SaveManager.crown_displeasure
	var fav_h := SaveManager.crown_favor
	if dis > 0:
		var dis_l := RichTextLabel.new()
		dis_l.bbcode_enabled = true
		dis_l.fit_content = true
		dis_l.scroll_active = false
		dis_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_rtl_theme_line(dis_l)
		dis_l.text = (
			"Немилость Короны: [color=#ff9a7a]%d[/color] — меньше золота в жалованье, дороже найм, здания и услуги. Плашка настроения вверху или вкладка «Караван»."
			% dis
		)
		vbox.add_child(dis_l)
	elif fav_h > 0:
		var fav_l := RichTextLabel.new()
		fav_l.bbcode_enabled = true
		fav_l.fit_content = true
		fav_l.scroll_active = false
		fav_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_rtl_theme_line(fav_l)
		fav_l.text = (
			"Одобрение Короны: [color=#7ed4a8]%d[/color] — больше золота в жалованье, дешевле найм, здания и услуги. Выполняйте приказы караваном."
			% fav_h
		)
		vbox.add_child(fav_l)
	vbox.add_child(_make_crown_help_section_title("Бонусы вашего титула"))
	for line in _crown_title_bonus_lines(cur):
		vbox.add_child(_make_crown_help_bullet_label(line))
	vbox.add_child(HSeparator.new())
	vbox.add_child(_make_crown_help_section_title("Как растёт титул"))
	vbox.add_child(
		_make_crown_help_body_label(
			"Каждая отгрузка караваном добавляет к тому, что вы уже отдали Короне за всю игру. Титул смотрит на это накопление, а не на размер одной партии.",
			15
		)
	)


func _populate_crown_help_titles(vbox: VBoxContainer) -> void:
	_clear_vbox_children(vbox)
	var intro := RichTextLabel.new()
	intro.bbcode_enabled = true
	intro.fit_content = true
	intro.scroll_active = false
	intro.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_rtl_theme_line(intro)
	intro.text = (
		"Ниже — ступени по тому, сколько [color=#9fd4ff]Сердцевины[/color] вы за всю игру отправили Короне караваном, и какие даются бонусы: жалованье, лимит вывоза руды с острова за поход, скидки на улучшения зданий. Герб можно нажать."
	)
	vbox.add_child(intro)
	var cur_idx := BalanceConfig.get_crown_title_index_for_ore_sent(SaveManager.ore_sent_to_crown_total)
	var step_i := 0
	for t in BalanceConfig.CROWN_TITLES:
		if t is Dictionary:
			vbox.add_child(_build_crown_help_title_card(t as Dictionary, step_i, step_i == cur_idx))
			step_i += 1


func _populate_crown_help_caravan_tab(vbox: VBoxContainer) -> void:
	_clear_vbox_children(vbox)
	vbox.add_child(_make_crown_help_section_title("Караван и походы"))
	var rtl0 := RichTextLabel.new()
	rtl0.bbcode_enabled = true
	rtl0.fit_content = true
	rtl0.scroll_active = false
	rtl0.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_rtl_theme_line(rtl0)
	rtl0.add_theme_font_size_override("normal_font_size", 15)
	rtl0.text = (
		"Пока обоз не ждёт у причала, [b]каждое ваше возвращение на базу с острова сменяет день и ночь в лагере[/b] и приближает момент, когда снова приедет [color=#e8c97a]караван Короны[/color]. "
		+ "Это не часы на столе — ритм задают ваши походы.\n\n"
		+ "Когда караван стоит в порту, следующий рейс не приближается, пока вы не отгрузите [color=#9fd4ff]Сердцевину[/color] или не [b]отпустите караван порожним[/b]. Срок текущего приказа Короны при этом убывает с каждым таким днём, как обычно.\n\n"
		+ "Сколько Корона ждёт от вас сейчас и успеваете ли — сказано прямо на экране [color=#e8c97a]«Караван Короны»[/color] в замке, отдельный слот в меню. "
		+ "Там же, под [b]«Подробнее о правилах ▼»[/b], — развёрнутый текст. Первое поручение появится после первого приезда каравана."
	)
	vbox.add_child(rtl0)
	vbox.add_child(HSeparator.new())
	vbox.add_child(_make_crown_help_section_title("Немилость Короны"))
	var rtl1 := RichTextLabel.new()
	rtl1.bbcode_enabled = true
	rtl1.fit_content = true
	rtl1.scroll_active = false
	rtl1.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_rtl_theme_line(rtl1)
	rtl1.text = (
		"Если к концу отведённого срока приказ по [color=#9fd4ff]Сердцевине[/color] выполнен слишком слабо, Корона остывает к вам: "
		+ "в жалованье каравана золота меньше, на базе услуги и улучшения дороже. "
		+ "Обида не бесконечна; щедрая отгрузка после провала может её смягчить."
	)
	vbox.add_child(rtl1)
	var go := Button.new()
	go.text = "Открыть «Караван Короны»"
	go.focus_mode = Control.FOCUS_NONE
	go.custom_minimum_size = Vector2(0, 48)
	go.add_theme_font_size_override("font_size", 18)
	go.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var gb := StyleBoxFlat.new()
	gb.bg_color = Color(0.16, 0.2, 0.28, 1)
	gb.set_border_width_all(1)
	gb.border_color = Color(0.55, 0.62, 0.78, 0.75)
	gb.set_corner_radius_all(10)
	gb.content_margin_left = 16
	gb.content_margin_top = 12
	gb.content_margin_right = 16
	gb.content_margin_bottom = 12
	go.add_theme_stylebox_override("normal", gb)
	var gb_h := gb.duplicate() as StyleBoxFlat
	gb_h.bg_color = Color(0.22, 0.26, 0.36, 1)
	go.add_theme_stylebox_override("hover", gb_h)
	var gb_p := gb.duplicate() as StyleBoxFlat
	gb_p.bg_color = Color(0.1, 0.12, 0.16, 1)
	go.add_theme_stylebox_override("pressed", gb_p)
	go.add_theme_color_override("font_color", Color(0.92, 0.9, 0.84, 1))
	go.pressed.connect(_on_crown_help_go_caravan_pressed)
	vbox.add_child(go)


func _populate_crown_help_panel() -> void:
	if _crown_help_layer == null:
		return
	for sc in _crown_help_tab_scrolls:
		sc.scroll_vertical = 0
	var o := _crown_help_layer.get_node_or_null("Root/Margin/Panel/MarginVBox/TabContentHost/ScrollOverview/OverviewVBox") as VBoxContainer
	var t := _crown_help_layer.get_node_or_null("Root/Margin/Panel/MarginVBox/TabContentHost/ScrollTitles/TitlesVBox") as VBoxContainer
	var c := _crown_help_layer.get_node_or_null("Root/Margin/Panel/MarginVBox/TabContentHost/ScrollCaravan/CaravanVBox") as VBoxContainer
	if o == null or t == null or c == null:
		return
	_populate_crown_help_overview(o)
	_populate_crown_help_titles(t)
	_populate_crown_help_caravan_tab(c)
	_set_crown_help_tab(_crown_help_tab_index)


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


func _setup_caravan_panel_nodes() -> void:
	_caravan_brief = get_node_or_null("%s/CaravanDetailsScroll/CaravanBrief" % _PATH_CARAVAN_VBOX) as RichTextLabel
	if _caravan_brief:
		_apply_dialogue_default_font_to_richtext(_caravan_brief)
	_caravan_details_scroll = get_node_or_null("%s/CaravanDetailsScroll" % _PATH_CARAVAN_VBOX) as ScrollContainer
	_caravan_details_btn = get_node_or_null("%s/BtnCaravanDetails" % _PATH_CARAVAN_VBOX) as Button
	_caravan_dot_row = get_node_or_null("%s/CaravanDotRow" % _PATH_CARAVAN_SUMMARY) as HBoxContainer
	_caravan_reward_gold = get_node_or_null("%s/CaravanRewardsHBox/CaravanRewardGold" % _PATH_CARAVAN_SUMMARY) as Label
	_caravan_reward_meat = get_node_or_null("%s/CaravanRewardsHBox/CaravanRewardMeat" % _PATH_CARAVAN_SUMMARY) as Label
	_caravan_reward_extra = get_node_or_null("%s/CaravanRewardsHBox/CaravanRewardExtra" % _PATH_CARAVAN_SUMMARY) as Label
	_caravan_totals_line = get_node_or_null("%s/CaravanTotalsLine" % _PATH_CARAVAN_SUMMARY) as Label
	_caravan_flavor_line = get_node_or_null("%s/CaravanIntendantRow/IntendantTexts/CaravanFlavorLine" % _PATH_CARAVAN_SUMMARY) as Label
	_caravan_pending_hint = get_node_or_null("%s/CaravanPendingHint" % _PATH_CARAVAN_SUMMARY) as Label
	_caravan_warning_line = get_node_or_null("%s/CaravanWarningLine" % _PATH_CARAVAN_SUMMARY) as Label
	_caravan_order_title = get_node_or_null("%s/CaravanOrderPanel/OrderMargin/OrderVBox/CaravanOrderTitle" % _PATH_CARAVAN_SUMMARY) as Label
	_caravan_order_ore_lbl = get_node_or_null("%s/CaravanOrderPanel/OrderMargin/OrderVBox/CaravanOrderOreLabel" % _PATH_CARAVAN_SUMMARY) as Label
	_caravan_order_ore_bar = get_node_or_null("%s/CaravanOrderPanel/OrderMargin/OrderVBox/CaravanOrderOreBar" % _PATH_CARAVAN_SUMMARY) as ProgressBar
	_caravan_deadline_strip = get_node_or_null("%s/CaravanOrderPanel/OrderMargin/OrderVBox/CaravanDeadlineStrip" % _PATH_CARAVAN_SUMMARY) as PanelContainer
	_caravan_deadline_head = get_node_or_null("%s/CaravanDeadlineHead" % _PATH_CARAVAN_ORDER_DEADLINE_VBOX) as Label
	_caravan_order_dl_lbl = get_node_or_null("%s/CaravanOrderDeadlineLabel" % _PATH_CARAVAN_ORDER_DEADLINE_VBOX) as Label
	_caravan_order_dl_bar = get_node_or_null("%s/CaravanOrderDeadlineBar" % _PATH_CARAVAN_ORDER_DEADLINE_VBOX) as ProgressBar
	_init_caravan_dot_styles()
	_build_caravan_dot_widgets()
	_init_caravan_deadline_bar_look()
	_apply_caravan_details_toggle(false)
	_refresh_caravan_slot_badge()
	if not resized.is_connected(_on_castle_caravan_panel_resized):
		resized.connect(_on_castle_caravan_panel_resized)
	if get_viewport() and not get_viewport().size_changed.is_connected(_on_castle_caravan_panel_resized):
		get_viewport().size_changed.connect(_on_castle_caravan_panel_resized)
	_fit_caravan_panel_to_viewport()


func _on_castle_caravan_panel_resized() -> void:
	_fit_caravan_panel_to_viewport()


func _fit_caravan_panel_to_viewport() -> void:
	var panel := get_node_or_null("CaravanSelectPanel/CCenter/CaravanPanel") as Control
	var scroll := get_node_or_null("CaravanSelectPanel/CCenter/CaravanPanel/CaravanInner/CaravanBodyScroll") as Control
	if panel == null or scroll == null:
		return
	var m := 20.0
	var vp := get_viewport().get_visible_rect().size
	var max_w := clampf(vp.x - m * 2.0, 280.0, 920.0)
	var max_h := clampf(vp.y - m * 2.0, 220.0, minf(680.0, vp.y - m * 2.0))
	panel.custom_minimum_size = Vector2(0, 0)
	scroll.custom_minimum_size = Vector2(max_w, max_h)


func _init_caravan_dot_styles() -> void:
	_caravan_dot_style_fill = StyleBoxFlat.new()
	_caravan_dot_style_fill.bg_color = Color(0.38, 0.72, 0.95, 1)
	_caravan_dot_style_fill.set_corner_radius_all(4)
	_caravan_dot_style_dim = StyleBoxFlat.new()
	_caravan_dot_style_dim.bg_color = Color(0.18, 0.2, 0.26, 1)
	_caravan_dot_style_dim.set_corner_radius_all(4)
	_caravan_dot_style_hold = StyleBoxFlat.new()
	_caravan_dot_style_hold.bg_color = Color(0.32, 0.36, 0.44, 1)
	_caravan_dot_style_hold.set_corner_radius_all(4)


func _init_caravan_deadline_bar_look() -> void:
	if _caravan_order_dl_bar == null:
		return
	_caravan_order_dl_bar.show_percentage = true
	_caravan_dl_bar_style_bg = StyleBoxFlat.new()
	_caravan_dl_bar_style_bg.bg_color = Color(0.08, 0.06, 0.07, 1)
	_caravan_dl_bar_style_bg.set_corner_radius_all(5)
	_caravan_dl_bar_style_bg.set_border_width_all(1)
	_caravan_dl_bar_style_bg.border_color = Color(0.45, 0.28, 0.18, 0.9)
	_caravan_order_dl_bar.add_theme_stylebox_override("background", _caravan_dl_bar_style_bg)
	_caravan_dl_bar_style_fill = StyleBoxFlat.new()
	_caravan_dl_bar_style_fill.set_corner_radius_all(4)
	_caravan_order_dl_bar.add_theme_stylebox_override("fill", _caravan_dl_bar_style_fill)
	_caravan_order_dl_bar.tooltip_text = "Полоса заполняется по мере истечения срока приказа (дни в лагере после возвращений с острова). 100%% — срок истёк; до этого успейте отгрузить норму."


func _set_caravan_deadline_bar_fill_by_ratio(elapsed_ratio: float) -> void:
	if _caravan_dl_bar_style_fill == null:
		return
	var r := clampf(elapsed_ratio, 0.0, 1.0)
	var calm := Color(0.28, 0.62, 0.48, 0.96)
	var urgent := Color(0.92, 0.32, 0.14, 0.98)
	_caravan_dl_bar_style_fill.bg_color = calm.lerp(urgent, r)


func _build_caravan_dot_widgets() -> void:
	if _caravan_dot_row == null:
		return
	for c in _caravan_dot_row.get_children():
		c.queue_free()
	_caravan_dot_panels.clear()
	for i in _CARAVAN_DOT_SLOTS_MAX:
		var p := Panel.new()
		p.custom_minimum_size = Vector2(32, 10)
		p.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_caravan_dot_row.add_child(p)
		_caravan_dot_panels.append(p)


func _apply_caravan_details_toggle(expanded: bool) -> void:
	_caravan_details_expanded = expanded
	if _caravan_details_btn:
		_caravan_details_btn.text = "Скрыть правила ▲" if expanded else "Подробнее о правилах ▼"
	if _caravan_details_scroll:
		_caravan_details_scroll.visible = expanded


func _on_caravan_details_pressed() -> void:
	SoundManager.play_ui_button()
	_apply_caravan_details_toggle(not _caravan_details_expanded)


func _caravan_rules_bbcode() -> String:
	var interval := BalanceConfig.CARAVAN_EXPEDITION_INTERVAL
	var lines: PackedStringArray = []
	lines.append(CampCodexDossier.serdtsevina_info_bbcode())
	lines.append("")
	lines.append("[b]Титул[/b]: зависит от суммарной Сердцевины, отправленной Короне; плашка вверху замка, кнопка «Справка».")
	lines.append("")
	lines.append(
		"[b]Рейсы[/b]: после отъезда каравана следующий прибудет через [color=#9fd4ff]%d[/color] %s — столько полных суток в лагере после возвращений с острова."
		% [interval, _ru_day_word_counted(interval)]
	)
	lines.append("")
	lines.append("[b]Пока караван у причала[/b]: следующий рейс встаёт в очередь; один счётчик дней на срок приказа и на график рейса. «Отпустить порожним» снимает ожидание.")
	lines.append("")
	lines.append(
		"[b]Приказ[/b]: норма Сердцевины к сроку в тех же днях, что считает и прибытие каравана (каждое возвращение на базу с похода — новый день); срок кратен [color=#9fd4ff]%d[/color] %s (ритм рейса). Если к концу срока отгружено меньше половины нормы — растёт [color=#ff9a7a]немилость[/color], макс. %d. Одна отгрузка примерно на [b]120%%[/b] нормы после недобора снижает немилость."
		% [BalanceConfig.CARAVAN_EXPEDITION_INTERVAL, _ru_day_word_dative_after_kraten(BalanceConfig.CARAVAN_EXPEDITION_INTERVAL), BalanceConfig.DISPLEASURE_MAX_LEVEL]
	)
	lines.append("")
	lines.append(
		"[b]Смена приказа[/b]: по окончании срока текущего поручения, если норма выполнена — поступает [color=#9fd4ff]следующий[/color] приказ в цепочке; если нет — повторяется [color=#9fd4ff]то же[/color] поручение с той же нормой и новым сроком (уже отгруженное в зачёт приказу сохраняется)."
	)
	lines.append("")
	lines.append(
		"[b]Немилость[/b]: меньше золота в жалованье, дороже найм, улучшения зданий и услуги на базе (сила зависит от сложности)."
	)
	lines.append(
		"[b]Одобрение[/b]: наоборот — щедрее жалованье и ниже цены; растёт за своевременные отгрузки по приказу (пока нет немилости)."
	)
	return "\n".join(lines)


func _caravan_arrival_details_bbcode() -> String:
	var interval_cfg := maxi(1, BalanceConfig.CARAVAN_EXPEDITION_INTERVAL)
	var pending := SaveManager.caravan_pending
	var exp_left := CrownSystem.get_returns_until_next_caravan()
	var lines: PackedStringArray = []
	lines.append("[b]Статус рейса[/b]")
	if pending:
		lines.append("Караван у причала. Загрузите Сердцевину или отпустите порожним.")
	else:
		if exp_left <= 0:
			lines.append("С вашим следующим приходом на базу с похода прибудет караван.")
		elif exp_left == 1:
			lines.append("До прибытия каравана остался 1 %s." % _ru_day_word_counted(1))
		else:
			lines.append(
				"До прибытия каравана осталось %d %s."
				% [exp_left, _ru_day_word_counted(exp_left)]
			)
	lines.append("")
	lines.append("[color=#8a93a8]Дни до следующего рейса (после возвращения на базу)[/color]")
	lines.append("")
	var completed_raw := 0
	if not pending:
		completed_raw = clampi(interval_cfg - exp_left, 0, interval_cfg)
	if pending:
		lines.append("Пока караван у причала, следующий рейс не прибывает — загрузите Сердцевину или отпустите обоз (очередь рейса сохраняется).")
	else:
		lines.append(
			"Отмечено дней в текущем цикле: %d из %d %s. Полный цикл — караван при следующем приходе на базу."
			% [completed_raw, interval_cfg, _ru_day_word_genitive_after_iz(interval_cfg)]
		)
	return "\n".join(lines)


func _refresh_caravan_status_and_order() -> void:
	var interval_cfg := maxi(1, BalanceConfig.CARAVAN_EXPEDITION_INTERVAL)
	var pending := SaveManager.caravan_pending
	var exp_left := CrownSystem.get_returns_until_next_caravan()
	var order := CrownSystem.get_current_order_info()

	if _caravan_pending_hint:
		_caravan_pending_hint.visible = pending

	if _caravan_dot_row:
		_caravan_dot_row.visible = not pending

	if _caravan_flavor_line:
		if pending:
			_caravan_flavor_line.text = "Борт ждёт распоряжения по отгрузке; следующий рейс встанет в очередь, пока обоз не уйдёт."
		else:
			_caravan_flavor_line.text = "Маяки на материке ждут Сердцевину; караван — единственный постоянный канал с базой."

	var g_base := BalanceConfig.get_caravan_supply_gold()
	var m := BalanceConfig.get_caravan_supply_meat()
	var dis := SaveManager.crown_displeasure
	var fav := SaveManager.crown_favor
	var g_show := int(round(float(g_base) * CrownSystem.get_gold_reward_crown_mult()))
	if _caravan_reward_gold:
		_caravan_reward_gold.text = "+%d зол." % g_show
	if _caravan_reward_meat:
		_caravan_reward_meat.text = "+%d мяса" % m
	if _caravan_reward_extra:
		if dis > 0:
			_caravan_reward_extra.text = "Немилость %d — меньше золота; титул и сложность тоже влияют на сумму." % dis
		elif fav > 0:
			_caravan_reward_extra.text = "Одобрение %d — бонус к золоту жалованья (и титул умножает)." % fav
		else:
			_caravan_reward_extra.text = "Титул Короны увеличивает жалованье; одобрение или немилость сдвигают выплату сильнее."

	if _caravan_totals_line:
		var sent_total := SaveManager.ore_sent_to_crown_total
		var trips := SaveManager.caravan_sent_count
		_caravan_totals_line.text = "Всего передано Короне: %d ед. Сердцевины, накопительно. Отправок каравана: %d." % [sent_total, trips]

	_refresh_caravan_expedition_dots(interval_cfg, pending, exp_left)
	_refresh_caravan_order_block(order, pending)
	_refresh_caravan_warning(order)


func _refresh_caravan_expedition_dots(interval_cfg: int, pending: bool, exp_left: int) -> void:
	if _caravan_dot_panels.is_empty():
		return
	var n := mini(interval_cfg, _CARAVAN_DOT_SLOTS_MAX)
	var completed_raw := 0
	if not pending:
		completed_raw = clampi(interval_cfg - exp_left, 0, interval_cfg)
	var filled := 0
	if not pending and interval_cfg > 0:
		filled = clampi(int(round(float(completed_raw) * float(n) / float(interval_cfg))), 0, n)
	var seg_tip := (
		"Каждый сегмент — один день: возвращение с острова на базу. Заполненный ряд — следующий рейс при следующем приходе на базу. Макс. %d сегм."
		% interval_cfg
	)
	for i in _caravan_dot_panels.size():
		var p := _caravan_dot_panels[i]
		if i >= n:
			p.visible = false
			p.tooltip_text = ""
			continue
		p.visible = true
		var st: StyleBoxFlat
		if pending:
			st = _caravan_dot_style_hold
			p.tooltip_text = "Караван у причала: следующий рейс ждёт отъезда борта (очередь сохраняется)."
		elif i < filled:
			st = _caravan_dot_style_fill
			p.tooltip_text = seg_tip
		else:
			st = _caravan_dot_style_dim
			p.tooltip_text = seg_tip
		p.add_theme_stylebox_override("panel", st)


func _refresh_caravan_order_block(order: Dictionary, caravan_pending: bool) -> void:
	if _caravan_order_title == null:
		return
	if order.is_empty():
		_caravan_order_title.text = "Приказ Короны"
		if _caravan_deadline_strip:
			_caravan_deadline_strip.visible = false
		if _caravan_order_ore_lbl:
			if SaveManager.crown_order_index <= 0:
				_caravan_order_ore_lbl.text = "Появится после первого прибытия каравана."
			else:
				_caravan_order_ore_lbl.text = "Нет активного приказа. Новое поручение может прийти с прибытием каравана."
		if _caravan_order_ore_bar:
			_caravan_order_ore_bar.visible = false
		if _caravan_order_dl_lbl:
			_caravan_order_dl_lbl.visible = false
		if _caravan_order_dl_bar:
			_caravan_order_dl_bar.visible = false
		return

	var req := maxi(1, int(order.get("ore_required", 1)))
	var sent := maxi(0, int(order.get("ore_sent", 0)))
	var dl_left := maxi(0, int(order.get("deadline_remaining", 0)))
	var dl_total := maxi(1, int(order.get("deadline_expeditions", BalanceConfig.DEFAULT_CROWN_ORDER_DEADLINE_EXPEDITIONS)))
	var awaiting := bool(order.get("deadline_expired_awaiting_dispatch", false))

	if _caravan_deadline_head:
		_caravan_deadline_head.text = "Срок окончен — 100%" if awaiting else "Срок приказа — важно"

	if _caravan_deadline_strip:
		_caravan_deadline_strip.visible = true

	if _caravan_order_ore_bar:
		_caravan_order_ore_bar.visible = true
		_caravan_order_ore_bar.max_value = float(req)
		_caravan_order_ore_bar.value = float(mini(sent, req))

	if _caravan_order_dl_bar:
		_caravan_order_dl_bar.visible = true
		## Доля прошедшего срока: 0% в начале периода, 100% когда не осталось дней в счётчике (окончание срока).
		## Диапазон 0..1 — совпадает с дефолтом сцены и гарантирует корректный % без рассинхрона max/value.
		_caravan_order_dl_bar.min_value = 0.0
		_caravan_order_dl_bar.max_value = 1.0
		var elapsed_ratio := 0.0 if dl_total <= 0 else float(dl_total - dl_left) / float(dl_total)
		elapsed_ratio = clampf(elapsed_ratio, 0.0, 1.0)
		_caravan_order_dl_bar.value = elapsed_ratio
		_set_caravan_deadline_bar_fill_by_ratio(elapsed_ratio)

	if sent >= req:
		_caravan_order_title.text = "Приказ Короны"
		if _caravan_order_ore_lbl:
			_caravan_order_ore_lbl.text = "Норма выполнена: %d / %d." % [sent, req]
		if _caravan_order_dl_lbl:
			_caravan_order_dl_lbl.visible = true
			if dl_left > 0:
				_caravan_order_dl_lbl.text = (
					"Следующий приказ поступит по окончании срока этого поручения: осталось %d из %d %s."
					% [dl_left, dl_total, _ru_day_word_genitive_after_iz(dl_total)]
				)
			else:
				if awaiting:
					_caravan_order_dl_lbl.text = (
						"Срок окончен — 100%%. Норма выполнена. Отправьте караван — после отъезда вступит следующий приказ."
					)
				else:
					_caravan_order_dl_lbl.text = "Срок поручения завершён — оформляется следующий приказ."
		return

	_caravan_order_title.text = "Приказ Короны"
	if _caravan_order_ore_lbl:
		_caravan_order_ore_lbl.text = "Сердцевина к приказу: %d / %d" % [sent, req]

	if _caravan_order_dl_lbl:
		_caravan_order_dl_lbl.visible = true
		if dl_left > 0:
			_caravan_order_dl_lbl.text = (
				"Осталось %d из %d %s до конца срока."
				% [dl_left, dl_total, _ru_day_word_genitive_after_iz(dl_total)]
			)
		else:
			if awaiting:
				if caravan_pending:
					_caravan_order_dl_lbl.text = (
						"Срок окончен — 100%%. Отгрузите Сердцевину караваном или отпустите порожним — от исхода зависит продление срока и немилость."
					)
				else:
					_caravan_order_dl_lbl.text = "Срок окончен — 100%%. Дождитесь каравана у причала, чтобы отгрузить норму или закрыть рейс."
			elif caravan_pending:
				_caravan_order_dl_lbl.text = "Срок вышел. Отгрузите Сердцевину караваном у причала — иначе последствия зафиксируют при следующей отметке."
			else:
				_caravan_order_dl_lbl.text = "Срок вышел. Дождитесь следующего прибытия каравана и отгрузите норму."


func _refresh_caravan_warning(order: Dictionary) -> void:
	if _caravan_warning_line == null:
		return
	_caravan_warning_line.visible = false
	if order.is_empty():
		return
	var req := int(order.get("ore_required", 0))
	var sent := int(order.get("ore_sent", 0))
	var dl_left := int(order.get("deadline_remaining", 0))
	if req <= 0:
		return
	if sent >= req:
		return
	if dl_left != 1:
		return
	var half_barrier := int(float(req) * 0.5)
	if sent >= half_barrier:
		return
	_caravan_warning_line.visible = true
	_caravan_warning_line.text = "Остался 1 день до конца срока приказа, норма ещё не выполнена."


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


func _can_hire_kind(kind: HireKind) -> bool:
	if GameManager.get_squad_member_count() >= BalanceConfig.MAX_SQUAD_MEMBERS:
		return false
	if kind == HireKind.ARCHER or kind == HireKind.LANCER:
		if SaveManager.archer_count + SaveManager.lancer_count >= GameManager.get_max_warriors_allowed():
			return false
	var hire_ore_cost := BalanceConfig.get_unit_hire_ore_cost()
	return GameplayFacade.can_afford_gold_plus_ore_strict(unit_hire_cost, hire_ore_cost)


func _show_hire_fail(msg: String) -> void:
	var quote_lbl := get_node_or_null("%s/SubtitleHire" % _PATH_HIRE_VBOX) as Label
	if quote_lbl:
		quote_lbl.text = msg


func _hire_unit(kind: HireKind) -> void:
	var scene := _resolve_scene_for_hire(kind)
	if not scene:
		return
	if GameManager.get_squad_member_count() >= BalanceConfig.MAX_SQUAD_MEMBERS:
		_show_hire_fail("Отряд переполнен. Максимум %d бойцов." % BalanceConfig.MAX_SQUAD_MEMBERS)
		return
	if kind == HireKind.ARCHER or kind == HireKind.LANCER:
		if SaveManager.archer_count + SaveManager.lancer_count >= GameManager.get_max_warriors_allowed():
			_show_hire_fail("Нужен запас мяса: добывайте на базе овец, чтобы увеличить лимит лучников и копейщиков.")
			return
	var hire_ore_cost := BalanceConfig.get_unit_hire_ore_cost()
	if not GameplayFacade.try_spend_gold_plus_ore_strict(unit_hire_cost, hire_ore_cost):
		var msg := "Недостаточно средств."
		if SaveManager.gold < unit_hire_cost and SaveManager.ore_count < hire_ore_cost:
			msg = "Недостаточно золота и Сердцевины."
		elif SaveManager.gold < unit_hire_cost:
			msg = "Недостаточно золота."
		elif SaveManager.ore_count < hire_ore_cost:
			msg = "Недостаточно Сердцевины."
		_show_hire_fail(msg)
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
	_refresh_hire_buy_ui()


## ═══════════════════════════════════════════════════════
##  КАРАВАН КОРОНЫ — подменю в замке
## ═══════════════════════════════════════════════════════

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
	_apply_caravan_details_toggle(false)
	_fit_caravan_panel_to_viewport()
	_refresh_caravan_ui()
	call_deferred("_refresh_caravan_ui")


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

	var ore_lbl := get_node_or_null("%s/OreRow/OreAvailable" % _PATH_CARAVAN_VBOX) as Label
	var send_all_btn := get_node_or_null("%s/BtnRow/BtnSendAll" % _PATH_CARAVAN_VBOX) as Button
	var send_half_btn := get_node_or_null("%s/BtnRow/BtnSendHalf" % _PATH_CARAVAN_VBOX) as Button
	var dismiss_btn := get_node_or_null("%s/BtnDismiss" % _PATH_CARAVAN_VBOX) as Button

	if _caravan_brief:
		_caravan_brief.text = _caravan_rules_bbcode() + "\n\n" + _caravan_arrival_details_bbcode()
	_refresh_caravan_status_and_order()

	if ore_lbl:
		ore_lbl.text = "Сердцевина на складе: %d" % ore_available

	var send_tip := ""
	if not pending:
		send_tip = "Станет доступно, когда караван прибудет к причалу."
	elif ore_available <= 0:
		send_tip = "Нет Сердцевины на складе."

	if send_all_btn:
		send_all_btn.disabled = not pending or ore_available <= 0
		send_all_btn.text = "Отправить всё — %d" % ore_available
		send_all_btn.tooltip_text = send_tip if send_all_btn.disabled else "Отправить всю Сердцевину с караваном."

	if send_half_btn:
		var half := maxi(1, ore_available / 2)
		send_half_btn.disabled = not pending or ore_available <= 0
		send_half_btn.text = "Отправить половину — %d" % half
		send_half_btn.tooltip_text = send_tip if send_half_btn.disabled else "Отправить половину склада."

	if dismiss_btn:
		dismiss_btn.disabled = not pending
		dismiss_btn.text = "Отпустить порожним, без отгрузки"
		dismiss_btn.tooltip_text = "Доступно, пока караван ждёт у причала." if pending else "Нечего отпускать — каравана у причала нет."


func _on_caravan_pressed() -> void:
	SoundManager.play_ui_button()
	_open_caravan_select()


func _on_caravan_back_pressed() -> void:
	SoundManager.play_ui_button()
	_close_caravan_select()


func _refresh_caravan_slot_badge() -> void:
	var badge := get_node_or_null(
		"CastleMenuPanel/Center/Frame/InnerMargin/InnerVBox/MainActions/SlotsRow/slot_caravan/ColumnCaravan/PortraitFrameCaravan/CaravanSlotBadge"
	) as CanvasItem
	if badge:
		badge.visible = SaveManager.caravan_pending


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


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if _touch_scroll_helper.consume_touch_scroll(event):
		get_viewport().set_input_as_handled()
