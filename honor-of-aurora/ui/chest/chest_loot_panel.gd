extends CanvasLayer
## Панель добычи сундука: стиль как у диалогов / меню замка, иконки ресурсов, компактный текст.

const _TEX_GOLD := preload("res://Asets/Unit_pack/UI Elements/UI Elements/Icons/Icon_03.png")
const _TEX_ORE := preload("res://Asets/Unit_pack/UI Elements/UI Elements/Icons/Icon_07.png")
const _TEX_MEAT := preload("res://Asets/Environment/Resources/Resources/M_Idle.png")
const _TEX_WOOD := preload("res://Asets/Environment/Resources/Resources/W_Idle.png")
const _ORE_SHADER := preload("res://ui/resources_hud/ore_icon_gold.gdshader")

@onready var _backdrop: ColorRect = $RootLayout/Backdrop
@onready var _title: Label = $RootLayout/Center/PanelRoot/Margin/VBox/TitleRow/TitleLabel
@onready var _resources_flow: HFlowContainer = $RootLayout/Center/PanelRoot/Margin/VBox/ResourcesFlow
@onready var _lore_block: VBoxContainer = $RootLayout/Center/PanelRoot/Margin/VBox/LoreBlock
@onready var _lore_text: Label = $RootLayout/Center/PanelRoot/Margin/VBox/LoreBlock/LoreScroll/LoreText
@onready var _empty_label: Label = $RootLayout/Center/PanelRoot/Margin/VBox/EmptyLabel
@onready var _confirm: Button = $RootLayout/Center/PanelRoot/Margin/VBox/Footer/ConfirmButton

var _ore_material: ShaderMaterial


func _exit_tree() -> void:
	ChestLootUi.set_chest_popup_open(false)


func _ready() -> void:
	layer = 95
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process_unhandled_input(true)
	visible = false
	_ore_material = ShaderMaterial.new()
	_ore_material.shader = _ORE_SHADER
	if _confirm:
		_confirm.pressed.connect(_close)
	if _backdrop:
		_backdrop.gui_input.connect(_on_backdrop_gui_input)


func setup_from_loot(loot: Dictionary) -> void:
	for c: Node in _resources_flow.get_children():
		c.queue_free()
	var g: int = maxi(0, int(loot.get("gold", 0)))
	var w: int = maxi(0, int(loot.get("wood", 0)))
	var m: int = maxi(0, int(loot.get("meat", 0)))
	var o: int = maxi(0, int(loot.get("ore", 0)))
	if g > 0:
		_add_chip(_TEX_GOLD, g, null)
	if w > 0:
		_add_chip(_TEX_WOOD, w, null)
	if m > 0:
		_add_chip(_TEX_MEAT, m, null)
	if o > 0:
		_add_chip(_TEX_ORE, o, _ore_material)
	var lore_id: String = str(loot.get("lore_note_id", ""))
	var lore_body := ""
	if not lore_id.is_empty():
		lore_body = ChestLoreLibrary.get_note_text(lore_id)
	var has_lore: bool = not lore_body.is_empty()
	var has_res: bool = g + w + m + o > 0
	_empty_label.visible = not has_res and not has_lore
	_resources_flow.visible = has_res
	_lore_block.visible = has_lore
	if has_lore:
		_lore_text.text = lore_body
	_title.text = "Находка" if has_res or has_lore else "Сундук"
	ChestLootUi.set_chest_popup_open(true)
	visible = true
	SoundManager.play_menu_open()
	call_deferred("_arm_focus")


func _add_chip(tex: Texture2D, amount: int, icon_material: Material) -> void:
	var wrap := PanelContainer.new()
	wrap.custom_minimum_size = Vector2(108, 52)
	var inner := StyleBoxFlat.new()
	inner.bg_color = Color(0.07, 0.08, 0.11, 0.92)
	inner.border_color = Color(0.28, 0.34, 0.44, 0.65)
	inner.set_border_width_all(1)
	inner.set_corner_radius_all(10)
	inner.content_margin_left = 8
	inner.content_margin_top = 6
	inner.content_margin_right = 10
	inner.content_margin_bottom = 6
	wrap.add_theme_stylebox_override("panel", inner)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(36, 36)
	icon.texture = tex
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if icon_material:
		icon.material = icon_material
	row.add_child(icon)
	var lab := Label.new()
	lab.text = "+%d" % amount
	lab.add_theme_font_size_override("font_size", 22)
	lab.add_theme_color_override("font_color", Color(0.96, 0.97, 1.0, 1.0))
	row.add_child(lab)
	wrap.add_child(row)
	_resources_flow.add_child(wrap)


func _arm_focus() -> void:
	if _confirm:
		_confirm.grab_focus()


func _close() -> void:
	ChestLootUi.set_chest_popup_open(false)
	SoundManager.play_menu_close()
	queue_free()


func _on_backdrop_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_close()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_close()
		return
	if event.is_action_pressed("attack"):
		get_viewport().set_input_as_handled()
		_close()
