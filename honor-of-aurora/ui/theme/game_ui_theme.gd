extends RefCounted
class_name GameUITheme
## Единая визуальная система главного меню и настроек: контраст, иерархия, касания ≥44px, стили по канонам game UI.

## Тёмный фон панели + «пергаментное» золото (читаемость на шумном фоне).
const _PANEL_BG := Color(0.07, 0.08, 0.11, 0.94)
const _PANEL_BORDER := Color(0.52, 0.42, 0.28, 0.85)
const _BTN_BG := Color(0.12, 0.14, 0.18, 0.98)
const _BTN_HOVER := Color(0.18, 0.2, 0.26, 1.0)
const _BTN_PRESSED := Color(0.08, 0.09, 0.12, 1.0)
const _TEXT := Color(0.93, 0.94, 0.96, 1.0)
const _TEXT_MUTED := Color(0.62, 0.66, 0.74, 1.0)
const _ACCENT := Color(0.88, 0.72, 0.42, 1.0)


static func _sb_panel() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = _PANEL_BG
	s.set_corner_radius_all(12)
	s.border_width_left = 2
	s.border_width_top = 2
	s.border_width_right = 2
	s.border_width_bottom = 2
	s.border_color = _PANEL_BORDER
	s.shadow_color = Color(0, 0, 0, 0.55)
	s.shadow_size = 10
	s.shadow_offset = Vector2(0, 4)
	s.content_margin_left = 20
	s.content_margin_top = 20
	s.content_margin_right = 20
	s.content_margin_bottom = 20
	return s


static func _sb_btn(bg: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.set_corner_radius_all(8)
	s.border_width_left = 1
	s.border_width_top = 1
	s.border_width_right = 1
	s.border_width_bottom = 1
	s.border_color = Color(_PANEL_BORDER.r, _PANEL_BORDER.g, _PANEL_BORDER.b, 0.45)
	s.content_margin_left = 20
	s.content_margin_top = 14
	s.content_margin_right = 20
	s.content_margin_bottom = 14
	return s


static func _sb_sep() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.35, 0.38, 0.45, 0.35)
	s.set_content_margin_all(1)
	return s


## Системный UI-шрифт (Segoe UI / Arial / sans-serif) — читаемость в настройках.
static func _font_ui() -> Font:
	var sf := SystemFont.new()
	sf.font_names = PackedStringArray(["Segoe UI", "Arial", "Helvetica", "Noto Sans", "sans-serif"])
	sf.font_weight = 400
	sf.font_italic = false
	return sf


static func create_theme() -> Theme:
	var t := Theme.new()
	var f := _font_ui()

	t.set_default_font(f)
	t.set_default_font_size(18)

	# —— Panel / PanelContainer ——
	t.set_stylebox("panel", "PanelContainer", _sb_panel())
	t.set_stylebox("panel", "Panel", _sb_panel())

	# —— Button ——
	t.set_stylebox("normal", "Button", _sb_btn(_BTN_BG))
	t.set_stylebox("hover", "Button", _sb_btn(_BTN_HOVER))
	t.set_stylebox("pressed", "Button", _sb_btn(_BTN_PRESSED))
	var sb_focus := _sb_btn(_BTN_HOVER)
	sb_focus.border_color = Color(_ACCENT.r, _ACCENT.g, _ACCENT.b, 0.75)
	sb_focus.border_width_left = 2
	sb_focus.border_width_top = 2
	sb_focus.border_width_right = 2
	sb_focus.border_width_bottom = 2
	t.set_stylebox("focus", "Button", sb_focus)
	t.set_color("font_color", "Button", _TEXT)
	t.set_color("font_hover_color", "Button", Color(1, 1, 1, 1))
	t.set_color("font_pressed_color", "Button", Color(0.85, 0.86, 0.9, 1))
	t.set_font("font", "Button", f)
	t.set_font_size("font_size", "Button", 26)

	# —— OptionButton ——
	t.set_stylebox("normal", "OptionButton", _sb_btn(_BTN_BG))
	t.set_stylebox("hover", "OptionButton", _sb_btn(_BTN_HOVER))
	t.set_stylebox("pressed", "OptionButton", _sb_btn(_BTN_PRESSED))
	t.set_color("font_color", "OptionButton", _TEXT)
	t.set_font("font", "OptionButton", f)
	t.set_font_size("font_size", "OptionButton", 20)

	# —— CheckBox ——
	t.set_color("font_color", "CheckBox", _TEXT)
	t.set_font("font", "CheckBox", f)
	t.set_font_size("font_size", "CheckBox", 18)

	# —— Label (база) ——
	t.set_color("font_color", "Label", _TEXT)
	t.set_font("font", "Label", f)
	t.set_font_size("font_size", "Label", 18)

	# —— HSlider ——
	var track := StyleBoxFlat.new()
	track.bg_color = Color(0.15, 0.16, 0.2, 1)
	track.set_corner_radius_all(4)
	track.set_content_margin_all(6)
	track.content_margin_left = 12
	track.content_margin_right = 12
	t.set_stylebox("slider", "HSlider", track)
	var grabber := StyleBoxFlat.new()
	grabber.bg_color = _ACCENT
	grabber.set_corner_radius_all(8)
	grabber.set_content_margin_all(8)
	var area_clear := StyleBoxFlat.new()
	area_clear.bg_color = Color(0, 0, 0, 0)
	t.set_stylebox("grabber_area", "HSlider", area_clear)
	t.set_stylebox("grabber_area_highlight", "HSlider", area_clear)
	t.set_stylebox("grabber", "HSlider", grabber)
	t.set_stylebox("grabber_highlight", "HSlider", grabber)
	t.set_stylebox("grabber_disabled", "HSlider", grabber)

	# —— HSeparator ——
	t.set_stylebox("separator", "HSeparator", _sb_sep())
	t.set_constant("separation", "HSeparator", 8)

	return t
