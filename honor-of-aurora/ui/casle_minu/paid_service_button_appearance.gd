class_name PaidServiceButtonAppearance
extends RefCounted
## Единый вид «услуга за золото»: неактивная кнопка как в оружейной (приглушённый фон + modulate).

const MODULATE_ENABLED := Color.WHITE
const MODULATE_DISABLED := Color(0.62, 0.62, 0.64, 1)
const META_PATCHED := &"_paid_service_btn_disabled_style"


static func ensure_disabled_stylebox(btn: Button) -> void:
	if btn == null:
		return
	if btn.get_meta(META_PATCHED, false):
		return
	btn.set_meta(META_PATCHED, true)
	var n := btn.get_theme_stylebox("normal") as StyleBoxFlat
	if n == null:
		return
	var d := n.duplicate() as StyleBoxFlat
	d.bg_color = Color(
		lerpf(n.bg_color.r, 0.2, 0.52),
		lerpf(n.bg_color.g, 0.21, 0.52),
		lerpf(n.bg_color.b, 0.24, 0.52),
		n.bg_color.a * 0.9
	)
	d.border_color = n.border_color.darkened(0.42)
	d.shadow_size = 0
	d.shadow_offset = Vector2.ZERO
	btn.add_theme_stylebox_override("disabled", d)


static func set_interactive(btn: Button, can_use: bool) -> void:
	if btn == null:
		return
	ensure_disabled_stylebox(btn)
	btn.disabled = not can_use
	btn.modulate = MODULATE_ENABLED if can_use else MODULATE_DISABLED
