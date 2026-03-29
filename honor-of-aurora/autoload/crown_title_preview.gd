extends CanvasLayer
## Полноэкранный просмотр герба титула: пропорции сохраняются, закрытие — фон, Esc или «Закрыть».

const _VIEW_FRAC := 0.88

var _root: Control
var _dim: ColorRect
var _tex_rect: TextureRect
var _close_btn: Button


func _ready() -> void:
	layer = 90
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_build_ui()


func _build_ui() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_root)
	_dim = ColorRect.new()
	_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_dim.color = Color(0.02, 0.03, 0.06, 0.84)
	_dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_dim.gui_input.connect(_on_dim_gui_input)
	_root.add_child(_dim)
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	_root.add_child(margin)
	var outer_v := VBoxContainer.new()
	outer_v.set_anchors_preset(Control.PRESET_FULL_RECT)
	outer_v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	outer_v.add_theme_constant_override("separation", 12)
	margin.add_child(outer_v)
	var top_bar := HBoxContainer.new()
	top_bar.alignment = BoxContainer.ALIGNMENT_END
	_close_btn = Button.new()
	_close_btn.text = "Закрыть"
	_close_btn.focus_mode = Control.FOCUS_NONE
	_close_btn.add_theme_font_size_override("font_size", 18)
	_close_btn.pressed.connect(hide_preview)
	top_bar.add_child(_close_btn)
	outer_v.add_child(top_bar)
	var center := CenterContainer.new()
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	outer_v.add_child(center)
	var frame := PanelContainer.new()
	var psb := StyleBoxFlat.new()
	psb.bg_color = Color(0.06, 0.07, 0.1, 0.96)
	psb.set_border_width_all(1)
	psb.border_color = Color(0.55, 0.48, 0.32, 0.55)
	psb.set_corner_radius_all(12)
	psb.content_margin_left = 10
	psb.content_margin_top = 10
	psb.content_margin_right = 10
	psb.content_margin_bottom = 10
	frame.add_theme_stylebox_override("panel", psb)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(frame)
	_tex_rect = TextureRect.new()
	_tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_tex_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(_tex_rect)


func show_texture(tex: Texture2D) -> void:
	if tex == null:
		return
	var sz := tex.get_size()
	if sz.x <= 0 or sz.y <= 0:
		return
	_tex_rect.texture = tex
	var r := float(sz.x) / float(sz.y)
	var vp := get_viewport().get_visible_rect().size
	var max_w := vp.x * _VIEW_FRAC
	var max_h := vp.y * _VIEW_FRAC - 120.0
	max_h = maxf(120.0, max_h)
	var tw := max_w
	var th := tw / r
	if th > max_h:
		th = max_h
		tw = th * r
	_tex_rect.custom_minimum_size = Vector2(tw, th)
	visible = true
	SoundManager.play_ui_button()


func show_texture_from_path(path: String) -> void:
	if path.is_empty() or not ResourceLoader.exists(path):
		return
	var t := load(path) as Texture2D
	show_texture(t)


func hide_preview() -> void:
	if not visible:
		return
	visible = false
	SoundManager.play_ui_button()


func _on_dim_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			hide_preview()

