extends Control

@onready var _backdrop: ColorRect = $Backdrop
@onready var _safe_margin: MarginContainer = $SafeMargin
@onready var _main_tabs: TabContainer = $SafeMargin/PanelRoot/InnerMargin/VBox/MainTabs
@onready var _close_btn: Button = $SafeMargin/PanelRoot/InnerMargin/VBox/HeaderRow/CloseButton
@onready var _dossier_scroll: ScrollContainer = $SafeMargin/PanelRoot/InnerMargin/VBox/MainTabs/DossierTab/DossierScroll
@onready var _dossier_lead: Label = $SafeMargin/PanelRoot/InnerMargin/VBox/MainTabs/DossierTab/DossierScroll/DossierPad/DossierVBox/IntroCard/IntroMargin/DossierLead
@onready var _body_progress: RichTextLabel = $SafeMargin/PanelRoot/InnerMargin/VBox/MainTabs/DossierTab/DossierScroll/DossierPad/DossierVBox/CardProgress/CardProgInner/BodyProgress
@onready var _body_story: RichTextLabel = $SafeMargin/PanelRoot/InnerMargin/VBox/MainTabs/DossierTab/DossierScroll/DossierPad/DossierVBox/CardStory/CardStoryInner/BodyStory
@onready var _body_personal: RichTextLabel = $SafeMargin/PanelRoot/InnerMargin/VBox/MainTabs/DossierTab/DossierScroll/DossierPad/DossierVBox/CardPersonal/CardPersInner/BodyPersonal
@onready var _char_list: ItemList = $SafeMargin/PanelRoot/InnerMargin/VBox/MainTabs/CharactersTab/DossierSplit/LeftPanel/LeftMargin/LeftVBox/CharList
@onready var _char_portrait: TextureRect = $SafeMargin/PanelRoot/InnerMargin/VBox/MainTabs/CharactersTab/DossierSplit/LeftPanel/LeftMargin/LeftVBox/PortraitPanel/CharPortrait
@onready var _role_line_label: Label = $SafeMargin/PanelRoot/InnerMargin/VBox/MainTabs/CharactersTab/DossierSplit/LeftPanel/LeftMargin/LeftVBox/RoleLineLabel
@onready var _char_brief: Label = $SafeMargin/PanelRoot/InnerMargin/VBox/MainTabs/CharactersTab/DossierSplit/LeftPanel/LeftMargin/LeftVBox/CharBrief
@onready var _char_story_scroll: ScrollContainer = $SafeMargin/PanelRoot/InnerMargin/VBox/MainTabs/CharactersTab/DossierSplit/RightPanel/RightMargin/CharStoryScroll
@onready var _char_story: RichTextLabel = $SafeMargin/PanelRoot/InnerMargin/VBox/MainTabs/CharactersTab/DossierSplit/RightPanel/RightMargin/CharStoryScroll/CharStoryBody
@onready var _archive_list: ItemList = $SafeMargin/PanelRoot/InnerMargin/VBox/MainTabs/ArchiveTab/ArchiveSplit/ListPanel/ListMargin/NoteList
@onready var _archive_body: RichTextLabel = $SafeMargin/PanelRoot/InnerMargin/VBox/MainTabs/ArchiveTab/ArchiveSplit/DetailPanel/DetailMargin/NoteDetailScroll/NoteDetailBody
@onready var _empty_archive: Label = $SafeMargin/PanelRoot/InnerMargin/VBox/MainTabs/ArchiveTab/EmptyArchiveLabel
@onready var _archive_split: HBoxContainer = $SafeMargin/PanelRoot/InnerMargin/VBox/MainTabs/ArchiveTab/ArchiveSplit
@onready var _inv_slot_row: HBoxContainer = $SafeMargin/PanelRoot/InnerMargin/VBox/MainTabs/InventoryTab/InventoryScroll/InventoryPad/InvVBox/SlotRow
@onready var _inv_hint_card: PanelContainer = $SafeMargin/PanelRoot/InnerMargin/VBox/MainTabs/InventoryTab/InventoryScroll/InventoryPad/InvVBox/InvHintCard
@onready var _inv_vbox: VBoxContainer = $SafeMargin/PanelRoot/InnerMargin/VBox/MainTabs/InventoryTab/InventoryScroll/InventoryPad/InvVBox

var _timeline_body: RichTextLabel
var _archive_entries: Array[Dictionary] = []
var _items_tab: Control
var _items_scroll: ScrollContainer
var _items_grid: HFlowContainer
var _items_empty: Label
var _item_entries: Array[Dictionary] = []
var _item_detail_overlay: Control
var _item_detail_icon_panel: PanelContainer
var _item_detail_icon_label: Label
var _item_detail_icon_tex: TextureRect
var _item_detail_title: Label
var _item_detail_brief: Label
var _item_detail_desc: RichTextLabel
var _item_detail_showing := false
var _codex_marker_info: Dictionary = {}
## Пока true — не пишем «просмотрено» от программного выбора в списках.
var _codex_block_click_marks: bool = false
var _codex_prev_tab: int = 0
var _crown_dossier_block: PanelContainer
var _crown_dossier_hbox: HBoxContainer
var _help_tab: Control


func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	if _close_btn:
		_close_btn.pressed.connect(_on_close_pressed)
	if _main_tabs:
		_main_tabs.tab_changed.connect(_on_main_tab_changed)
	if not Events.crown_title_changed.is_connected(_on_crown_title_changed_refresh_dossier):
		Events.crown_title_changed.connect(_on_crown_title_changed_refresh_dossier)
	if _archive_list:
		_archive_list.item_selected.connect(_on_archive_item_selected)
	if _char_list:
		_char_list.item_selected.connect(_on_character_list_selected)
	_setup_timeline_tab()
	_setup_items_tab()
	_setup_help_tab()
	_set_tab_titles()


func _set_tab_titles() -> void:
	if _main_tabs == null:
		return
	_main_tabs.set_tab_title(0, "Сводка")
	_main_tabs.set_tab_title(1, "Досье")
	_main_tabs.set_tab_title(2, "Архив")
	_main_tabs.set_tab_title(3, "Хронология")
	if _main_tabs.get_tab_count() > 4:
		_main_tabs.set_tab_title(4, "Предметы")
	if _main_tabs.get_tab_count() > 5:
		_main_tabs.set_tab_title(5, "Справка")


func _setup_timeline_tab() -> void:
	if _inv_slot_row:
		_inv_slot_row.queue_free()
	if _inv_hint_card:
		_inv_hint_card.queue_free()
	if _inv_vbox == null:
		return
	_timeline_body = RichTextLabel.new()
	_timeline_body.bbcode_enabled = true
	_timeline_body.fit_content = true
	_timeline_body.scroll_active = false
	_timeline_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_timeline_body.add_theme_color_override("default_color", Color(0.78, 0.82, 0.9, 0.98))
	_timeline_body.add_theme_font_size_override("normal_font_size", 15)
	_inv_vbox.add_child(_timeline_body)


func _setup_items_tab() -> void:
	if _main_tabs == null:
		return
	_items_tab = Control.new()
	_items_tab.name = "ItemsTab"
	_main_tabs.add_child(_items_tab)

	_items_scroll = ScrollContainer.new()
	_items_scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_items_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_items_tab.add_child(_items_scroll)

	var pad := MarginContainer.new()
	pad.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pad.add_theme_constant_override("margin_left", 18)
	pad.add_theme_constant_override("margin_top", 14)
	pad.add_theme_constant_override("margin_right", 18)
	pad.add_theme_constant_override("margin_bottom", 14)
	_items_scroll.add_child(pad)

	_items_grid = HFlowContainer.new()
	_items_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_items_grid.add_theme_constant_override("h_separation", 12)
	_items_grid.add_theme_constant_override("v_separation", 12)
	pad.add_child(_items_grid)

	_items_empty = Label.new()
	_items_empty.visible = false
	_items_empty.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_items_empty.add_theme_color_override("font_color", Color(0.55, 0.6, 0.68, 0.92))
	_items_empty.add_theme_font_size_override("font_size", 16)
	_items_empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_items_empty.text = "Предметов пока нет. Исследуйте острова."
	_items_tab.add_child(_items_empty)

	_setup_item_detail_popup()


func _setup_help_tab() -> void:
	if _main_tabs == null:
		return
	_help_tab = Control.new()
	_help_tab.name = "HelpTab"
	_main_tabs.add_child(_help_tab)
	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_help_tab.add_child(scroll)
	var pad := MarginContainer.new()
	pad.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pad.add_theme_constant_override("margin_left", 2)
	pad.add_theme_constant_override("margin_top", 4)
	pad.add_theme_constant_override("margin_right", 6)
	pad.add_theme_constant_override("margin_bottom", 12)
	scroll.add_child(pad)
	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 12)
	pad.add_child(vbox)
	var lead := Label.new()
	lead.text = "Краткие пояснения по ресурсам и терминам мира. Подробности сюжета — в сводке, досье и архиве."
	lead.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lead.add_theme_color_override("font_color", Color(0.62, 0.66, 0.74, 0.95))
	lead.add_theme_font_size_override("font_size", 14)
	vbox.add_child(lead)
	for sec in CampCodexGlossary.get_sections():
		if not (sec is Dictionary):
			continue
		var sd: Dictionary = sec
		vbox.add_child(_make_help_heading(str(sd.get("heading", ""))))
		for e in sd.get("entries", []) as Array:
			if e is Dictionary:
				vbox.add_child(_make_help_entry_card(e))


func _make_help_heading(title: String) -> Label:
	var l := Label.new()
	l.text = title
	l.add_theme_color_override("font_color", Color(0.82, 0.72, 0.45, 1))
	l.add_theme_font_size_override("font_size", 16)
	return l


func _make_help_entry_card(entry: Dictionary) -> PanelContainer:
	var card := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.06, 0.07, 0.1, 0.92)
	sb.set_border_width_all(1)
	sb.border_color = Color(0.35, 0.38, 0.48, 0.45)
	sb.set_corner_radius_all(8)
	sb.content_margin_left = 14
	sb.content_margin_top = 12
	sb.content_margin_right = 14
	sb.content_margin_bottom = 12
	card.add_theme_stylebox_override("panel", sb)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var icon_wrap := PanelContainer.new()
	var isb := StyleBoxFlat.new()
	isb.bg_color = Color(0.1, 0.11, 0.16, 1)
	isb.set_border_width_all(1)
	isb.border_color = Color(0.78, 0.65, 0.35, 0.35)
	isb.set_corner_radius_all(8)
	isb.content_margin_left = 6
	isb.content_margin_top = 6
	isb.content_margin_right = 6
	isb.content_margin_bottom = 6
	icon_wrap.add_theme_stylebox_override("panel", isb)
	icon_wrap.custom_minimum_size = Vector2(76, 76)
	var ctr := CenterContainer.new()
	ctr.set_anchors_preset(Control.PRESET_FULL_RECT)
	icon_wrap.add_child(ctr)
	var tr := TextureRect.new()
	tr.custom_minimum_size = Vector2(64, 64)
	tr.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var ipath := str(entry.get("icon", ""))
	if ResourceLoader.exists(ipath):
		tr.texture = load(ipath) as Texture2D
	ctr.add_child(tr)
	row.add_child(icon_wrap)
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 6)
	var ttl := Label.new()
	ttl.text = str(entry.get("title", ""))
	ttl.add_theme_color_override("font_color", Color(0.82, 0.72, 0.45, 1))
	ttl.add_theme_font_size_override("font_size", 15)
	col.add_child(ttl)
	var body := Label.new()
	body.text = str(entry.get("body", ""))
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_color_override("font_color", Color(0.78, 0.82, 0.9, 0.98))
	body.add_theme_font_size_override("font_size", 14)
	col.add_child(body)
	row.add_child(col)
	card.add_child(row)
	return card


func reset_camp_codex_state() -> void:
	if _main_tabs:
		_main_tabs.current_tab = 0
	_scroll_dossier_top()


func prepare_on_open() -> void:
	_codex_block_click_marks = true
	_codex_marker_info = SaveManager.compute_codex_new_marker_info(get_tree())
	_refresh_archive_list()
	_refresh_dossier()
	_refresh_characters()
	_refresh_timeline()
	_refresh_items()
	_apply_codex_tab_markers()
	if _main_tabs:
		_main_tabs.current_tab = 0
		_codex_prev_tab = 0
	_scroll_dossier_top()
	_scroll_character_story_top()
	SaveManager.mark_codex_opened(get_tree())
	call_deferred("_codex_finish_open_setup")


func _codex_finish_open_setup() -> void:
	_codex_block_click_marks = false
	_focus_close_button()


func _on_crown_title_changed_refresh_dossier(_idx: int, _name: String) -> void:
	if not visible or _main_tabs == null:
		return
	if _main_tabs.current_tab == 0:
		_refresh_dossier()
	elif _main_tabs.current_tab == 1 and _char_list:
		var sel: PackedInt32Array = _char_list.get_selected_items()
		if sel.size() > 0:
			_apply_character_selection(int(sel[0]))


func _dossier_root_vbox() -> VBoxContainer:
	return _body_progress.get_node("../../..") as VBoxContainer


func _ensure_crown_dossier_panel() -> void:
	if _crown_dossier_block != null and is_instance_valid(_crown_dossier_block):
		return
	var v := _dossier_root_vbox()
	if v == null:
		return
	_crown_dossier_block = PanelContainer.new()
	_crown_dossier_block.name = "CrownDossierBlock"
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.06, 0.07, 0.1, 0.92)
	sb.set_border_width_all(1)
	sb.border_color = Color(0.35, 0.38, 0.48, 0.45)
	sb.set_corner_radius_all(8)
	sb.content_margin_left = 14
	sb.content_margin_top = 12
	sb.content_margin_right = 14
	sb.content_margin_bottom = 12
	_crown_dossier_block.add_theme_stylebox_override("panel", sb)
	_crown_dossier_hbox = HBoxContainer.new()
	_crown_dossier_hbox.add_theme_constant_override("separation", 14)
	_crown_dossier_block.add_child(_crown_dossier_hbox)
	v.add_child(_crown_dossier_block)
	v.move_child(_crown_dossier_block, 1)


func _make_dossier_crown_chip(art_path: String) -> Control:
	var wrap := PanelContainer.new()
	var chip_sb := StyleBoxFlat.new()
	chip_sb.bg_color = Color(0.1, 0.11, 0.16, 1)
	chip_sb.set_border_width_all(1)
	chip_sb.border_color = Color(0.78, 0.65, 0.35, 0.4)
	chip_sb.set_corner_radius_all(8)
	chip_sb.content_margin_left = 6
	chip_sb.content_margin_top = 6
	chip_sb.content_margin_right = 6
	chip_sb.content_margin_bottom = 6
	wrap.add_theme_stylebox_override("panel", chip_sb)
	wrap.custom_minimum_size = Vector2(88, 88)
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


func _refresh_crown_dossier_panel() -> void:
	_ensure_crown_dossier_panel()
	if _crown_dossier_hbox == null:
		return
	for c in _crown_dossier_hbox.get_children():
		c.queue_free()
	var data := CampCodexDossier.crown_dossier_panel_data()
	var art_path := String(data.get("art_path", ""))
	if not art_path.is_empty():
		_crown_dossier_hbox.add_child(_make_dossier_crown_chip(art_path))
	var text_col := VBoxContainer.new()
	text_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_col.add_theme_constant_override("separation", 6)
	var hdr := Label.new()
	hdr.text = "Титул Короны"
	hdr.add_theme_color_override("font_color", Color(0.82, 0.72, 0.45, 1))
	hdr.add_theme_font_size_override("font_size", 13)
	text_col.add_child(hdr)
	var nm_lbl := Label.new()
	nm_lbl.text = String(data.get("title_name", ""))
	nm_lbl.add_theme_color_override("font_color", Color(0.94, 0.9, 0.78, 1))
	nm_lbl.add_theme_font_size_override("font_size", 20)
	nm_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_col.add_child(nm_lbl)
	var sent_lbl := Label.new()
	sent_lbl.text = String(data.get("sent_line", ""))
	sent_lbl.add_theme_color_override("font_color", Color(0.62, 0.72, 0.82, 0.95))
	sent_lbl.add_theme_font_size_override("font_size", 15)
	sent_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_col.add_child(sent_lbl)
	var fx_lbl := Label.new()
	fx_lbl.text = String(data.get("fx_line", ""))
	fx_lbl.add_theme_color_override("font_color", Color(0.7, 0.74, 0.82, 0.92))
	fx_lbl.add_theme_font_size_override("font_size", 14)
	fx_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_col.add_child(fx_lbl)
	_crown_dossier_hbox.add_child(text_col)


func _scroll_dossier_top() -> void:
	if _dossier_scroll:
		_dossier_scroll.scroll_vertical = 0


func _scroll_character_story_top() -> void:
	if _char_story_scroll:
		_char_story_scroll.scroll_vertical = 0


func _refresh_dossier() -> void:
	if _dossier_lead:
		_dossier_lead.text = CampCodexDossier.intro_plain_text()
	_refresh_crown_dossier_panel()
	if _body_progress:
		_body_progress.bbcode_text = CampCodexDossier.build_stats_bbcode(get_tree())
	if _body_story:
		_body_story.bbcode_text = CampCodexDossier.story_bbcode()
	if _body_personal:
		_body_personal.bbcode_text = CampCodexDossier.personal_bbcode()


func _refresh_characters() -> void:
	var entries := CampCodexDossier.get_character_entries()
	if _char_list == null:
		return
	var prev_block := _codex_block_click_marks
	_codex_block_click_marks = true
	_char_list.clear()
	for d in entries:
		var dict: Dictionary = d
		_char_list.add_item(String(dict.get("display_name", "")))
		var idx := _char_list.item_count - 1
		_char_list.set_item_metadata(idx, String(dict.get("key", "")))
	if _char_list.item_count > 0:
		_char_list.select(0)
		_apply_character_selection(0)
	_codex_block_click_marks = prev_block
	_stamp_character_new_icons()


func _on_character_list_selected(index: int) -> void:
	SoundManager.play_ui_button()
	if not _codex_block_click_marks:
		var entries := CampCodexDossier.get_character_entries()
		if index >= 0 and index < entries.size():
			var key := String(entries[index].get("key", ""))
			if not key.is_empty():
				SaveManager.codex_mark_character_clicked(get_tree(), key)
				_refresh_codex_marker_ui()
	_apply_character_selection(index)


func _apply_character_selection(index: int) -> void:
	var entries := CampCodexDossier.get_character_entries()
	if index < 0 or index >= entries.size():
		return
	var d: Dictionary = entries[index]
	var key := String(d.get("key", ""))
	if _char_portrait:
		var path := String(d.get("portrait", ""))
		var t2: Texture2D = null
		if ResourceLoader.exists(path):
			t2 = load(path) as Texture2D
		_char_portrait.texture = t2
		_update_hero_crown_badge_on_portrait(key == "hero")
	if _role_line_label:
		var role_txt := String(d.get("role_line", ""))
		if key == "hero":
			role_txt += "\nТитул Короны: %s" % CrownSystem.get_current_title_name()
		_role_line_label.text = role_txt
	if _char_brief:
		_char_brief.text = String(d.get("brief_plain", ""))
	if _char_story:
		_char_story.bbcode_text = CampCodexDossierStories.get_story_bbcode(key)
	_scroll_character_story_top()


func _update_hero_crown_badge_on_portrait(hero_selected: bool) -> void:
	if _char_portrait == null:
		return
	var legacy := _char_portrait.get_node_or_null("CrownTitleBadge")
	if legacy:
		legacy.queue_free()
	var wrap := _char_portrait.get_node_or_null("CrownTitleBadgeWrap") as Control
	if not hero_selected:
		if wrap:
			wrap.visible = false
		return
	if wrap == null:
		wrap = Control.new()
		wrap.name = "CrownTitleBadgeWrap"
		wrap.mouse_filter = Control.MOUSE_FILTER_STOP
		wrap.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
		wrap.anchor_left = 1.0
		wrap.anchor_top = 1.0
		wrap.anchor_right = 1.0
		wrap.anchor_bottom = 1.0
		wrap.offset_left = -72.0
		wrap.offset_top = -72.0
		wrap.offset_right = -4.0
		wrap.offset_bottom = -4.0
		var ar := AspectRatioContainer.new()
		ar.set_anchors_preset(Control.PRESET_FULL_RECT)
		wrap.add_child(ar)
		var tr := TextureRect.new()
		tr.set_anchors_preset(Control.PRESET_FULL_RECT)
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ar.add_child(tr)
		_char_portrait.add_child(wrap)
		wrap.gui_input.connect(_on_hero_crown_badge_gui_input)
	var ar2 := wrap.get_child(0) as AspectRatioContainer
	var tr2 := ar2.get_child(0) as TextureRect
	var tex := CrownSystem.load_current_crown_title_texture()
	tr2.texture = tex
	if tex:
		var gs := tex.get_size()
		ar2.ratio = float(gs.x) / float(maxi(1, int(gs.y)))
	else:
		ar2.ratio = 1.0
	wrap.visible = tex != null


func _on_hero_crown_badge_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			CrownTitlePreview.show_texture(CrownSystem.load_current_crown_title_texture())


func _focus_close_button() -> void:
	if _close_btn and visible:
		_close_btn.grab_focus()


func _on_close_pressed() -> void:
	SoundManager.play_ui_button()
	if _main_tabs:
		var ct := _main_tabs.current_tab
		if ct == 0:
			SaveManager.codex_mark_summary_seen(get_tree())
		elif ct == 3:
			SaveManager.codex_mark_timeline_seen(get_tree())
	var hud := GameplayFacade.get_hud(get_tree())
	if hud and hud.has_method("hide_camp_codex_menu"):
		hud.hide_camp_codex_menu()


func _on_main_tab_changed(tab: int) -> void:
	if not _codex_block_click_marks and _main_tabs:
		if _codex_prev_tab == 0 and tab != 0:
			SaveManager.codex_mark_summary_seen(get_tree())
			_refresh_codex_marker_ui()
		if _codex_prev_tab == 3 and tab != 3:
			SaveManager.codex_mark_timeline_seen(get_tree())
			_refresh_codex_marker_ui()
	_codex_prev_tab = tab
	SoundManager.play_ui_button()
	if tab == 0:
		_refresh_dossier()
	if tab == 1:
		_refresh_characters()
	if tab == 2:
		_refresh_archive_list()
	if tab == 3:
		_refresh_timeline()
	if tab == 4:
		_refresh_items()
	match tab:
		1:
			_stamp_character_new_icons()
		2:
			_stamp_archive_new_icons()
		_:
			pass


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if CrownTitlePreview.visible and event.is_action_pressed("ui_cancel"):
		CrownTitlePreview.hide_preview()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("ui_cancel"):
		if _item_detail_showing:
			_hide_item_detail()
		else:
			_on_close_pressed()
		get_viewport().set_input_as_handled()


func _refresh_archive_list() -> void:
	if _archive_list == null:
		return
	_archive_list.clear()
	_archive_entries.clear()
	var grouped := CampCodexLoreArchive.get_entries_grouped()
	var found_any := false
	for group in grouped:
		var gd: Dictionary = group
		var cat: String = String(gd.get("category", ""))
		var hint: String = String(gd.get("hint", ""))
		var entries: Array = gd.get("entries", []) as Array
		if entries.is_empty():
			continue
		found_any = true
		var cat_count := entries.size()
		var cat_total := CampCodexLoreArchive.get_total_for_category(cat)
		var count_str := ""
		if cat_total > 0:
			count_str = "  (%d/%d)" % [cat_count, cat_total]
		elif cat_count > 0:
			count_str = "  (%d)" % cat_count
		var sep_text := "── %s%s ──" % [cat, count_str]
		if not hint.is_empty():
			sep_text += "\n     %s" % hint
		_archive_list.add_item(sep_text)
		var sep_idx := _archive_list.item_count - 1
		_archive_list.set_item_disabled(sep_idx, true)
		_archive_list.set_item_selectable(sep_idx, false)
		_archive_list.set_item_metadata(sep_idx, "")
		for e in entries:
			var ed: Dictionary = e
			_archive_entries.append(ed)
			var entry_idx := _archive_entries.size() - 1
			_archive_list.add_item("  %s" % String(ed.get("title", "")))
			var list_idx := _archive_list.item_count - 1
			_archive_list.set_item_metadata(list_idx, entry_idx)
		var missing := cat_total - cat_count
		for i in range(missing):
			_archive_list.add_item("  [???]")
			var m_idx := _archive_list.item_count - 1
			_archive_list.set_item_selectable(m_idx, false)
			_archive_list.set_item_custom_fg_color(m_idx, Color(0.35, 0.38, 0.45, 0.7))
	if _empty_archive:
		_empty_archive.visible = not found_any
	if _archive_split:
		_archive_split.visible = found_any
	if _archive_body:
		if found_any:
			_archive_body.bbcode_text = "[color=#aab8cc]Выберите запись в списке слева.[/color]"
		else:
			_archive_body.bbcode_text = "[center][color=#aab8cc]Записей пока нет. Ищите сундуки на островах и слушайте целителя у церкви.[/color][/center]"
	_stamp_archive_new_icons()


func _on_archive_item_selected(index: int) -> void:
	SoundManager.play_ui_button()
	if _archive_list == null or _archive_body == null:
		return
	var meta: Variant = _archive_list.get_item_metadata(index)
	if meta == null or str(meta) == "":
		return
	var entry_idx: int = int(meta)
	if entry_idx < 0 or entry_idx >= _archive_entries.size():
		return
	var ed: Dictionary = _archive_entries[entry_idx]
	if not _codex_block_click_marks:
		var eid := str(ed.get("id", ""))
		if not eid.is_empty():
			SaveManager.codex_mark_archive_clicked(eid)
			_refresh_codex_marker_ui()
	var title := String(ed.get("title", ""))
	var txt := String(ed.get("text_bbcode", ""))
	var is_letter: bool = ed.get("is_letter", false)
	if is_letter:
		_archive_body.bbcode_text = (
			"[font_size=%d][b][color=#d4c9a0]%s[/color][/b][/font_size]\n"
			% [DialogueUiConstants.TEXT_FONT_SIZE, title]
			+ "[color=#8a8070]─────────────────────[/color]\n\n%s\n\n"
			% txt
			+ "[color=#8a8070]─────────────────────[/color]"
		)
	else:
		_archive_body.bbcode_text = (
			"[font_size=%d][b]%s[/b][/font_size]\n\n%s"
			% [DialogueUiConstants.TEXT_FONT_SIZE, title, txt]
		)


func _refresh_items() -> void:
	if _items_grid == null:
		return
	for c: Node in _items_grid.get_children():
		c.queue_free()
	_item_entries.clear()
	var items := StoryItemLibrary.get_unlocked_items()
	for item in items:
		_item_entries.append(item)
		var is_new := _is_codex_item_marked_new(str(item.get("id", "")))
		var cell := _build_item_cell(item, _item_entries.size() - 1, is_new)
		_items_grid.add_child(cell)
	var found_any := not _item_entries.is_empty()
	if _items_empty:
		_items_empty.visible = not found_any
	if _items_scroll:
		_items_scroll.visible = found_any
	_hide_item_detail()


func _new_codex_id_set(marker_key: String) -> Dictionary:
	var d := {}
	var v: Variant = _codex_marker_info.get(marker_key, null)
	if v is PackedStringArray:
		for x in v as PackedStringArray:
			d[str(x)] = true
	elif v is Array:
		for x in v as Array:
			d[str(x)] = true
	return d


func _is_codex_item_marked_new(item_id: String) -> bool:
	if item_id.is_empty():
		return false
	return _new_codex_id_set("new_item_ids").has(item_id)


func _refresh_codex_marker_ui() -> void:
	_codex_marker_info = SaveManager.compute_codex_new_marker_info(get_tree())
	_apply_codex_tab_markers()
	if _main_tabs == null:
		return
	match _main_tabs.current_tab:
		1:
			_stamp_character_new_icons()
		2:
			_stamp_archive_new_icons()
		4:
			_refresh_items()


func _refresh_codex_marker_ui_preserve_items() -> void:
	_codex_marker_info = SaveManager.compute_codex_new_marker_info(get_tree())
	_apply_codex_tab_markers()
	_sync_item_grid_codex_badges()


func _apply_codex_tab_markers() -> void:
	if _main_tabs == null:
		return
	var tex: Texture2D = CodexNewMarker.get_badge_texture()
	var n := _main_tabs.get_tab_count()
	for i in n:
		_main_tabs.set_tab_icon(i, null)
	var tabs_v: Variant = _codex_marker_info.get("tabs", [])
	if tabs_v is Array:
		var tabs_a: Array = tabs_v
		for i in mini(tabs_a.size(), n):
			if tabs_a[i]:
				_main_tabs.set_tab_icon(i, tex)


func _stamp_archive_new_icons() -> void:
	if _archive_list == null:
		return
	var new_set := _new_codex_id_set("new_archive_ids")
	if new_set.is_empty():
		return
	var tex: Texture2D = CodexNewMarker.get_badge_texture()
	for row in range(_archive_list.item_count):
		var meta: Variant = _archive_list.get_item_metadata(row)
		if meta == null or str(meta) == "":
			continue
		var entry_idx: int = int(meta)
		if entry_idx < 0 or entry_idx >= _archive_entries.size():
			continue
		var eid := str(_archive_entries[entry_idx].get("id", ""))
		if new_set.has(eid):
			_archive_list.set_item_icon(row, tex)


func _stamp_character_new_icons() -> void:
	if _char_list == null:
		return
	var new_set := _new_codex_id_set("new_char_keys")
	if new_set.is_empty():
		return
	var tex: Texture2D = CodexNewMarker.get_badge_texture()
	var entries := CampCodexDossier.get_character_entries()
	for i in mini(_char_list.item_count, entries.size()):
		var k := str(entries[i].get("key", ""))
		if new_set.has(k):
			_char_list.set_item_icon(i, tex)


func _create_codex_item_badge() -> TextureRect:
	var nb := TextureRect.new()
	nb.name = "CodexNewBadge"
	nb.texture = CodexNewMarker.get_badge_texture()
	nb.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	nb.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	nb.custom_minimum_size = Vector2(18, 22)
	nb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return nb


func _place_codex_badge_on_cell(pc: PanelContainer, nb: TextureRect) -> void:
	pc.add_child(nb)
	nb.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	nb.offset_left = -22.0
	nb.offset_top = 4.0
	nb.offset_right = -2.0
	nb.offset_bottom = 26.0


func _sync_item_grid_codex_badges() -> void:
	if _items_grid == null:
		return
	var new_set := _new_codex_id_set("new_item_ids")
	for c in _items_grid.get_children():
		if not (c is PanelContainer):
			continue
		var pc := c as PanelContainer
		var iid := ""
		if pc.has_meta("codex_item_id"):
			iid = str(pc.get_meta("codex_item_id"))
		var want := new_set.has(iid)
		var existing := pc.get_node_or_null("CodexNewBadge") as TextureRect
		if want and existing == null:
			_place_codex_badge_on_cell(pc, _create_codex_item_badge())
		elif not want and existing != null:
			existing.queue_free()


func _build_item_cell(item: Dictionary, idx: int, is_new: bool = false) -> PanelContainer:
	var col: Color = item.get("icon_color", Color(0.4, 0.4, 0.4)) as Color
	var cell := PanelContainer.new()
	cell.set_meta("codex_item_id", str(item.get("id", "")))
	cell.custom_minimum_size = Vector2(100, 118)
	var style_n := StyleBoxFlat.new()
	style_n.bg_color = Color(0.07, 0.08, 0.12, 0.92)
	style_n.set_border_width_all(1)
	style_n.border_color = Color(col.r, col.g, col.b, 0.35)
	style_n.set_corner_radius_all(8)
	style_n.set_content_margin_all(8)
	cell.add_theme_stylebox_override("panel", style_n)
	cell.mouse_filter = Control.MOUSE_FILTER_STOP
	cell.tooltip_text = str(item.get("brief", ""))
	cell.gui_input.connect(_on_item_cell_input.bind(idx))
	cell.mouse_entered.connect(_on_cell_hover.bind(cell, col, true))
	cell.mouse_exited.connect(_on_cell_hover.bind(cell, col, false))

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 6)
	vbox.mouse_filter = Control.MOUSE_FILTER_PASS
	cell.add_child(vbox)

	var icon_panel := PanelContainer.new()
	icon_panel.custom_minimum_size = Vector2(64, 64)
	icon_panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	icon_panel.mouse_filter = Control.MOUSE_FILTER_PASS
	var icon_style := StyleBoxFlat.new()
	icon_style.bg_color = Color(col.r, col.g, col.b, 0.2)
	icon_style.set_border_width_all(1)
	icon_style.border_color = Color(col.r, col.g, col.b, 0.45)
	icon_style.set_corner_radius_all(6)
	icon_panel.add_theme_stylebox_override("panel", icon_style)
	vbox.add_child(icon_panel)

	var icon_path: String = str(item.get("icon", ""))
	if not icon_path.is_empty() and ResourceLoader.exists(icon_path):
		var tex_rect := TextureRect.new()
		tex_rect.texture = load(icon_path) as Texture2D
		tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tex_rect.custom_minimum_size = Vector2(48, 48)
		tex_rect.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		tex_rect.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		tex_rect.mouse_filter = Control.MOUSE_FILTER_PASS
		tex_rect.modulate = Color(col.r, col.g, col.b, 0.95)
		icon_panel.add_child(tex_rect)
	else:
		var char_lbl := Label.new()
		char_lbl.text = str(item.get("icon_char", "?"))
		char_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		char_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		char_lbl.add_theme_font_size_override("font_size", 28)
		char_lbl.add_theme_color_override("font_color", Color(col.r, col.g, col.b, 0.85))
		char_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		char_lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
		char_lbl.mouse_filter = Control.MOUSE_FILTER_PASS
		icon_panel.add_child(char_lbl)

	var name_lbl := Label.new()
	name_lbl.text = str(item.get("name", ""))
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 11)
	name_lbl.add_theme_color_override("font_color", Color(0.82, 0.84, 0.9, 0.95))
	name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_lbl.custom_minimum_size.x = 84
	name_lbl.mouse_filter = Control.MOUSE_FILTER_PASS
	vbox.add_child(name_lbl)
	if is_new:
		_place_codex_badge_on_cell(cell, _create_codex_item_badge())
	return cell


func _on_item_cell_input(event: InputEvent, idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if idx >= 0 and idx < _item_entries.size():
			SoundManager.play_dialogue_page_turn()
			_show_item_detail(_item_entries[idx])


func _on_cell_hover(cell: PanelContainer, col: Color, entered: bool) -> void:
	var style := StyleBoxFlat.new()
	if entered:
		style.bg_color = Color(col.r, col.g, col.b, 0.18)
		style.border_color = Color(col.r, col.g, col.b, 0.6)
	else:
		style.bg_color = Color(0.07, 0.08, 0.12, 0.92)
		style.border_color = Color(col.r, col.g, col.b, 0.35)
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(8)
	cell.add_theme_stylebox_override("panel", style)


func _setup_item_detail_popup() -> void:
	_item_detail_overlay = Control.new()
	_item_detail_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_item_detail_overlay.visible = false
	_item_detail_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_items_tab.add_child(_item_detail_overlay)

	var backdrop := ColorRect.new()
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color(0.02, 0.03, 0.06, 0.75)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	backdrop.gui_input.connect(_on_detail_backdrop_input)
	_item_detail_overlay.add_child(backdrop)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_PASS
	_item_detail_overlay.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(480, 0)
	panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var pstyle := StyleBoxFlat.new()
	pstyle.bg_color = Color(0.06, 0.07, 0.1, 0.97)
	pstyle.set_border_width_all(2)
	pstyle.border_color = Color(0.55, 0.48, 0.32, 0.7)
	pstyle.set_corner_radius_all(12)
	pstyle.content_margin_left = 22
	pstyle.content_margin_top = 18
	pstyle.content_margin_right = 22
	pstyle.content_margin_bottom = 18
	panel.add_theme_stylebox_override("panel", pstyle)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	center.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	panel.add_child(vbox)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 16)
	vbox.add_child(header)

	_item_detail_icon_panel = PanelContainer.new()
	_item_detail_icon_panel.custom_minimum_size = Vector2(72, 72)
	var icon_s := StyleBoxFlat.new()
	icon_s.bg_color = Color(0.15, 0.15, 0.2, 0.6)
	icon_s.set_border_width_all(1)
	icon_s.border_color = Color(0.5, 0.5, 0.5, 0.4)
	icon_s.set_corner_radius_all(8)
	_item_detail_icon_panel.add_theme_stylebox_override("panel", icon_s)
	header.add_child(_item_detail_icon_panel)

	_item_detail_icon_label = Label.new()
	_item_detail_icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_item_detail_icon_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_item_detail_icon_label.add_theme_font_size_override("font_size", 32)
	_item_detail_icon_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_item_detail_icon_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_item_detail_icon_panel.add_child(_item_detail_icon_label)

	_item_detail_icon_tex = TextureRect.new()
	_item_detail_icon_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_item_detail_icon_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_item_detail_icon_tex.custom_minimum_size = Vector2(56, 56)
	_item_detail_icon_tex.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_item_detail_icon_tex.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_item_detail_icon_tex.visible = false
	_item_detail_icon_panel.add_child(_item_detail_icon_tex)

	var title_col := VBoxContainer.new()
	title_col.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	title_col.add_theme_constant_override("separation", 4)
	header.add_child(title_col)

	_item_detail_title = Label.new()
	_item_detail_title.add_theme_font_size_override("font_size", 22)
	_item_detail_title.add_theme_color_override("font_color", Color(0.96, 0.93, 0.86, 1))
	title_col.add_child(_item_detail_title)

	_item_detail_brief = Label.new()
	_item_detail_brief.add_theme_font_size_override("font_size", 14)
	_item_detail_brief.add_theme_color_override("font_color", Color(0.62, 0.69, 0.78, 0.9))
	title_col.add_child(_item_detail_brief)

	var sep := HSeparator.new()
	sep.add_theme_color_override("separator", Color(0.4, 0.38, 0.3, 0.35))
	vbox.add_child(sep)

	var desc_scroll := ScrollContainer.new()
	desc_scroll.custom_minimum_size = Vector2(0, 180)
	desc_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	desc_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(desc_scroll)

	_item_detail_desc = RichTextLabel.new()
	_item_detail_desc.bbcode_enabled = true
	_item_detail_desc.fit_content = true
	_item_detail_desc.scroll_active = false
	_item_detail_desc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_item_detail_desc.add_theme_color_override("default_color", Color(0.85, 0.87, 0.92, 1))
	_item_detail_desc.add_theme_font_size_override("normal_font_size", 16)
	desc_scroll.add_child(_item_detail_desc)

	var footer := HBoxContainer.new()
	footer.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(footer)

	var close_btn := Button.new()
	close_btn.text = "Закрыть"
	close_btn.custom_minimum_size = Vector2(120, 36)
	var btn_n := StyleBoxFlat.new()
	btn_n.bg_color = Color(0.12, 0.13, 0.18, 0.95)
	btn_n.set_border_width_all(1)
	btn_n.border_color = Color(0.55, 0.48, 0.32, 0.55)
	btn_n.set_corner_radius_all(6)
	btn_n.set_content_margin_all(6)
	var btn_h := btn_n.duplicate() as StyleBoxFlat
	btn_h.bg_color = Color(0.18, 0.17, 0.14, 0.95)
	btn_h.border_color = Color(0.72, 0.62, 0.38, 0.7)
	var btn_p := btn_n.duplicate() as StyleBoxFlat
	btn_p.bg_color = Color(0.1, 0.1, 0.12, 0.95)
	close_btn.add_theme_stylebox_override("normal", btn_n)
	close_btn.add_theme_stylebox_override("hover", btn_h)
	close_btn.add_theme_stylebox_override("pressed", btn_p)
	close_btn.add_theme_color_override("font_color", Color(0.88, 0.85, 0.76, 1))
	close_btn.add_theme_color_override("font_hover_color", Color(0.96, 0.93, 0.82, 1))
	close_btn.add_theme_font_size_override("font_size", 14)
	close_btn.pressed.connect(_hide_item_detail)
	footer.add_child(close_btn)


func _show_item_detail(item: Dictionary) -> void:
	if _item_detail_overlay == null:
		return
	var iid := str(item.get("id", ""))
	if not iid.is_empty():
		SaveManager.codex_mark_item_clicked(iid)
		_refresh_codex_marker_ui_preserve_items()
	var col: Color = item.get("icon_color", Color(0.5, 0.5, 0.5)) as Color
	var is_letter: bool = item.get("is_letter", false)
	_item_detail_title.text = str(item.get("name", ""))
	_item_detail_brief.text = str(item.get("brief", ""))

	var desc_text := str(item.get("description", ""))
	if is_letter:
		_item_detail_desc.bbcode_enabled = true
		_item_detail_desc.text = ""
		_item_detail_desc.bbcode_text = "[color=#d4c9a0][i]%s[/i][/color]" % desc_text
		_item_detail_title.add_theme_color_override("font_color", Color(0.83, 0.79, 0.67, 1))
	else:
		_item_detail_desc.bbcode_enabled = true
		_item_detail_desc.text = ""
		_item_detail_desc.bbcode_text = desc_text
		_item_detail_title.add_theme_color_override("font_color", Color(0.96, 0.93, 0.86, 1))

	var icon_path: String = str(item.get("icon", ""))
	var has_texture := not icon_path.is_empty() and ResourceLoader.exists(icon_path)
	if has_texture:
		_item_detail_icon_tex.texture = load(icon_path) as Texture2D
		_item_detail_icon_tex.modulate = Color(col.r, col.g, col.b, 0.95)
		_item_detail_icon_tex.visible = true
		_item_detail_icon_label.visible = false
	else:
		_item_detail_icon_tex.visible = false
		_item_detail_icon_label.visible = true
		_item_detail_icon_label.text = str(item.get("icon_char", "?"))
		_item_detail_icon_label.add_theme_color_override("font_color", Color(col.r, col.g, col.b, 0.9))

	var icon_s := StyleBoxFlat.new()
	icon_s.bg_color = Color(col.r, col.g, col.b, 0.2)
	icon_s.set_border_width_all(1)
	icon_s.border_color = Color(col.r, col.g, col.b, 0.5)
	icon_s.set_corner_radius_all(8)
	_item_detail_icon_panel.add_theme_stylebox_override("panel", icon_s)
	_item_detail_overlay.visible = true
	_item_detail_showing = true


func _hide_item_detail() -> void:
	if _item_detail_overlay:
		_item_detail_overlay.visible = false
	if _item_detail_showing:
		SoundManager.play_ui_button()
	_item_detail_showing = false


func _on_detail_backdrop_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_hide_item_detail()


func _refresh_timeline() -> void:
	if _timeline_body == null:
		return
	_timeline_body.bbcode_text = CampCodexDossier.build_timeline_bbcode()


func try_handle_back() -> bool:
	if _item_detail_showing:
		_hide_item_detail()
		return true
	return false
