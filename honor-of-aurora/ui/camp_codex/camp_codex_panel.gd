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


func _set_tab_titles() -> void:
	if _main_tabs == null:
		return
	_main_tabs.set_tab_title(0, "Сводка")
	_main_tabs.set_tab_title(1, "Досье")
	_main_tabs.set_tab_title(2, "Архив записок")
	_main_tabs.set_tab_title(3, "Инвентарь")


func reset_camp_codex_state() -> void:
	if _main_tabs:
		_main_tabs.current_tab = 0
	_scroll_dossier_top()


func prepare_on_open() -> void:
	_refresh_archive_list()
	_refresh_dossier()
	_refresh_characters()
	if _main_tabs:
		_main_tabs.current_tab = 0
	_scroll_dossier_top()
	_scroll_character_story_top()
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
	if tab == 0:
		_refresh_dossier()
	if tab == 1:
		_refresh_characters()
	if tab == 2:
		_refresh_archive_list()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		_on_close_pressed()
		get_viewport().set_input_as_handled()


func _refresh_archive_list() -> void:
	if _archive_list == null:
		return
	_archive_list.clear()
	var ids: PackedStringArray = ChestLoreLibrary.get_all_note_ids()
	var found_any := false
	for i in ids.size():
		var nid: String = String(ids[i])
		if not SaveManager.has_lore_note(nid):
			continue
		found_any = true
		var title := ChestLoreLibrary.get_note_display_title(nid)
		_archive_list.add_item(title)
		var idx := _archive_list.item_count - 1
		_archive_list.set_item_metadata(idx, nid)
	if _empty_archive:
		_empty_archive.visible = not found_any
	if _archive_split:
		_archive_split.visible = found_any
	if _archive_body:
		if found_any:
			_archive_body.bbcode_text = "[color=#aab8cc]Выберите записку в списке слева.[/color]"
		else:
			_archive_body.bbcode_text = "[center][color=#aab8cc]Записок пока нет. Ищите сундуки на островах.[/color][/center]"


func _on_archive_item_selected(index: int) -> void:
	if _archive_list == null or _archive_body == null:
		return
	var meta: Variant = _archive_list.get_item_metadata(index)
	if meta == null:
		return
	var nid := str(meta)
	var txt := ChestLoreLibrary.get_note_text(nid)
	var title := ChestLoreLibrary.get_note_display_title(nid)
	_archive_body.bbcode_text = (
		"[font_size=%d][b]%s[/b][/font_size]\n\n%s"
		% [DialogueUiConstants.TEXT_FONT_SIZE, title, txt]
	)


func try_handle_back() -> bool:
	return false
