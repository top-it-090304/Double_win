extends Control
## Отдельное окно чтения грамоты Короны (прокрутка, не окно диалога).

const TEX_KNIGHT := preload("res://Asets/Unit_pack/UI Elements/UI Elements/Human Avatars/aa_player.png")

@onready var _face: TextureRect = %KnightFace
@onready var _title_label: Label = %TitleLabel
@onready var _scroll: ScrollContainer = %BodyScroll
@onready var _body: RichTextLabel = %BodyRichText
@onready var _close_btn: Button = %CloseButton

var _on_closed: Callable = Callable()
var _tier: int = -1


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_STOP
	if _close_btn:
		_close_btn.pressed.connect(_on_close_pressed)
	if _face:
		_face.texture = TEX_KNIGHT
		_face.flip_h = false


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_on_close_pressed()


## tier — индекс в BalanceConfig.CROWN_TITLES (1…); on_closed вызывается после закрытия.
func setup_patent(tier: int, on_closed: Callable) -> void:
	_on_closed = on_closed
	_tier = tier
	if tier < 1 or tier >= BalanceConfig.CROWN_TITLES.size():
		call_deferred("_on_close_pressed")
		return
	var t: Dictionary = BalanceConfig.CROWN_TITLES[tier]
	var title_name := str(t.get("name", ""))
	if _title_label:
		_title_label.text = title_name
	var raw: Variant = t.get("patent_lines", null)
	var parts: PackedStringArray = []
	if raw is Array:
		for p in raw as Array:
			var s := str(p).strip_edges()
			if not s.is_empty():
				parts.append(s)
	var hero := str(t.get("patent_hero_line", "")).strip_edges()

	var bb := ""
	bb += "[color=#c9b896]Милорд, вот что канцелярия заверила под печатью. Читайте без спешки — сургуч не любит суеты.[/color]\n\n"
	bb += "[color=#e8d4a8]───────────────[/color]\n\n"
	for i in range(parts.size()):
		if i > 0:
			bb += "\n\n"
		bb += parts[i]
	if not hero.is_empty():
		bb += "\n\n[color=#9ec8e8][i]— %s[/i][/color]" % hero
	var bonus_lines := BalanceConfig.crown_title_bonus_summary_lines(t)
	if not bonus_lines.is_empty():
		bb += "\n\n[color=#e8d4a8]───────────────[/color]\n\n"
		bb += "[color=#a8c4a8][b]Уставные льготы по титулу[/b][/color]\n"
		for bl in bonus_lines:
			bb += "\n[color=#b8c8d8]• %s[/color]" % bl

	if _body:
		_body.text = bb
		call_deferred("_scroll_to_top")


func _scroll_to_top() -> void:
	if _scroll:
		_scroll.scroll_vertical = 0


func _on_close_pressed() -> void:
	SoundManager.play_ui_button()
	if _tier >= 1 and BalanceConfig.crown_title_tier_has_patent(_tier):
		StoryState.set_flag("crown_patent_letter_%d" % _tier, true)
	var cb := _on_closed
	_on_closed = Callable()
	_tier = -1
	queue_free()
	if cb.is_valid():
		cb.call()
