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


func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	if _close_btn:
		_close_btn.pressed.connect(_on_close_pressed)
	if _main_tabs:
		_main_tabs.tab_changed.connect(_on_main_tab_changed)
	if _archive_list:
		_archive_list.item_selected.connect(_on_archive_item_selected)
	if _char_list:
		_char_list.item_selected.connect(_on_character_list_selected)
	_set_tab_titles()
	_setup_timeline_tab()
	_setup_items_tab()


func _set_tab_titles() -> void:
	if _main_tabs == null:
		return
	_main_tabs.set_tab_title(0, "Сводка")
	_main_tabs.set_tab_title(1, "Досье")
	_main_tabs.set_tab_title(2, "Архив")
	_main_tabs.set_tab_title(3, "Хронология")
	if _main_tabs.get_tab_count() > 4:
		_main_tabs.set_tab_title(4, "Предметы")


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
	_main_tabs.set_tab_title(_main_tabs.get_tab_count() - 1, "Предметы")

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


func reset_camp_codex_state() -> void:
	if _main_tabs:
		_main_tabs.current_tab = 0
	_scroll_dossier_top()


func prepare_on_open() -> void:
	_refresh_archive_list()
	_refresh_dossier()
	_refresh_characters()
	_refresh_timeline()
	_refresh_items()
	if _main_tabs:
		_main_tabs.current_tab = 0
	_scroll_dossier_top()
	_scroll_character_story_top()
	SaveManager.mark_codex_opened()
	call_deferred("_focus_close_button")


func _scroll_dossier_top() -> void:
	if _dossier_scroll:
		_dossier_scroll.scroll_vertical = 0


func _scroll_character_story_top() -> void:
	if _char_story_scroll:
		_char_story_scroll.scroll_vertical = 0


func _refresh_dossier() -> void:
	if _dossier_lead:
		_dossier_lead.text = CampCodexDossier.intro_plain_text()
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
	_char_list.clear()
	for d in entries:
		var dict: Dictionary = d
		_char_list.add_item(String(dict.get("display_name", "")))
		var idx := _char_list.item_count - 1
		_char_list.set_item_metadata(idx, String(dict.get("key", "")))
	if _char_list.item_count > 0:
		_char_list.select(0)
		_apply_character_selection(0)


func _on_character_list_selected(index: int) -> void:
	SoundManager.play_ui_button()
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
	if _role_line_label:
		_role_line_label.text = String(d.get("role_line", ""))
	if _char_brief:
		_char_brief.text = String(d.get("brief_plain", ""))
	if _char_story:
		_char_story.bbcode_text = CampCodexDossierStories.get_story_bbcode(key)
	_scroll_character_story_top()


func _focus_close_button() -> void:
	if _close_btn and visible:
		_close_btn.grab_focus()


func _on_close_pressed() -> void:
	SoundManager.play_ui_button()
	var hud := GameplayFacade.get_hud(get_tree())
	if hud and hud.has_method("hide_camp_codex_menu"):
		hud.hide_camp_codex_menu()


func _on_main_tab_changed(tab: int) -> void:
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


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
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
			_archive_body.bbcode_text = "[center][color=#aab8cc]Записей пока нет. Ищите сундуки на островах и слушайте разговоры у огня.[/color][/center]"


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
		var cell := _build_item_cell(item, _item_entries.size() - 1)
		_items_grid.add_child(cell)
	var found_any := not _item_entries.is_empty()
	if _items_empty:
		_items_empty.visible = not found_any
	if _items_scroll:
		_items_scroll.visible = found_any
	_hide_item_detail()


func _build_item_cell(item: Dictionary, idx: int) -> PanelContainer:
	var col: Color = item.get("icon_color", Color(0.4, 0.4, 0.4)) as Color
	var cell := PanelContainer.new()
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
