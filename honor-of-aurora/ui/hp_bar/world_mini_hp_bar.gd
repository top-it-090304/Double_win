extends Control
## Компактный HP-бар над головой: тёмная рамка, красная полоса, лёгкая анимация при смене HP.

const BAR_W := 44.0
const BAR_H := 6.0

var _progress: ProgressBar
var _value_tween: Tween


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 50
	z_as_relative = false
	custom_minimum_size = Vector2(BAR_W, BAR_H)
	size = custom_minimum_size

	_progress = ProgressBar.new()
	_progress.name = "FillBar"
	_progress.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_progress.show_percentage = false
	_progress.set_anchors_preset(Control.PRESET_FULL_RECT)
	_progress.offset_left = 1.0
	_progress.offset_top = 1.0
	_progress.offset_right = -1.0
	_progress.offset_bottom = -1.0
	add_child(_progress)

	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.06, 0.05, 0.07, 0.92)
	bg.set_corner_radius_all(3)
	bg.set_border_width_all(1)
	bg.border_color = Color(0.35, 0.18, 0.18, 0.95)
	bg.shadow_color = Color(0, 0, 0, 0.45)
	bg.shadow_size = 2
	bg.shadow_offset = Vector2(0, 1)

	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(0.96, 0.32, 0.28, 1.0)
	fill.set_corner_radius_all(2)
	fill.border_width_left = 0
	fill.border_width_top = 1
	fill.border_width_right = 0
	fill.border_width_bottom = 0
	fill.border_color = Color(1.0, 0.55, 0.5, 0.35)

	_progress.add_theme_stylebox_override(&"background", bg)
	_progress.add_theme_stylebox_override(&"fill", fill)


func setup(unit: Node) -> void:
	var hc: Node = unit.get_node_or_null("HealthComponent") if unit else null
	if hc == null:
		visible = false
		return
	if hc.has_signal("health_changed") and not hc.health_changed.is_connected(_on_health_changed):
		hc.health_changed.connect(_on_health_changed)
	_on_health_changed(hc.current_health, hc.max_health)


func _on_health_changed(current: int, maximum: int) -> void:
	if _progress == null:
		return
	var mx: int = maxi(maximum, 1)
	_progress.max_value = float(mx)
	visible = current > 0
	if not visible:
		return
	var target: float = clampf(float(current), 0.0, float(mx))
	if _value_tween:
		_value_tween.kill()
	_value_tween = create_tween()
	_value_tween.set_ease(Tween.EASE_OUT)
	_value_tween.set_trans(Tween.TRANS_CUBIC)
	_value_tween.tween_property(_progress, "value", target, 0.14)
	var ratio: float = float(current) / float(mx)
	modulate = Color(1, 1, 1, lerpf(0.42, 1.0, ratio))
