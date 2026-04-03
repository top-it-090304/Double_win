extends CharacterBody2D

@export var speed: float = 100.0
## Общий масштаб облака (спрайт, коллайдер, нотификатор экрана).
@export var visual_scale: float = 1.1
## Доля разброса скорости (параллакс / глубина).
@export var speed_jitter_fraction: float = 0.14
@export var cloud_textures: Array[Texture2D] = []
## Доля полностью непрозрачных облаков (остальные — со случайной альфой между min и max).
@export_range(0.0, 1.0, 0.01) var opaque_cloud_fraction: float = 0.5
## Диапазон альфы для «полупрозрачной» половины (каждое облако — своё значение).
@export_range(0.0, 1.0, 0.01) var translucent_alpha_min: float = 0.18
@export_range(0.0, 1.0, 0.01) var translucent_alpha_max: float = 0.78
## Линейный масштаб аддитивного слоя за непрозрачным облаком (>1 — чуть больше ореола).
@export_range(1.0, 1.35, 0.01) var opaque_glow_scale: float = 1.1
## Сила свечения (альфа аддитивного слоя).
@export_range(0.0, 0.6, 0.01) var opaque_glow_strength: float = 0.2
## Оттенок свечения (аддитивное смешение).
@export var opaque_glow_tint: Color = Color(0.78, 0.9, 1.0, 1.0)


func _ready() -> void:
	## Не перехватывать клики/тапы (меню: облака поверх UI, события должны доходить до кнопок).
	input_pickable = false
	scale = Vector2.ONE * maxf(0.05, visual_scale)
	var random_index: int = randi() % cloud_textures.size()
	var selected_texture: Texture2D = cloud_textures[random_index]
	var spr: Sprite2D = $Sprite2D
	spr.texture = selected_texture
	if _apply_cloud_modulate(spr):
		_add_opaque_glow_sprite(spr, selected_texture)

	var j: float = clampf(speed_jitter_fraction, 0.0, 0.45)
	speed *= randf_range(1.0 - j, 1.0 + j)


func _apply_cloud_modulate(spr: Sprite2D) -> bool:
	var r: float = clampf(randf_range(0.94, 1.03), 0.0, 1.0)
	var g: float = clampf(randf_range(0.96, 1.04), 0.0, 1.0)
	var b: float = clampf(randf_range(0.97, 1.06), 0.0, 1.0)
	if randf() < clampf(opaque_cloud_fraction, 0.0, 1.0):
		spr.modulate = Color(r, g, b, 1.0)
		return true
	var lo: float = minf(translucent_alpha_min, translucent_alpha_max)
	var hi: float = maxf(translucent_alpha_min, translucent_alpha_max)
	var a: float = clampf(randf_range(lo, hi), 0.0, 1.0)
	spr.modulate = Color(r, g, b, a)
	return false


func _add_opaque_glow_sprite(main: Sprite2D, tex: Texture2D) -> void:
	var glow := Sprite2D.new()
	glow.name = &"OpaqueGlow"
	glow.texture = tex
	glow.centered = main.centered
	glow.offset = main.offset
	glow.flip_h = main.flip_h
	glow.flip_v = main.flip_v
	var gs: float = maxf(1.01, opaque_glow_scale)
	glow.scale = Vector2(gs, gs)
	glow.z_index = main.z_index - 1
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	glow.material = mat
	var t: Color = opaque_glow_tint
	var sa: float = clampf(opaque_glow_strength, 0.0, 1.0)
	glow.modulate = Color(t.r, t.g, t.b, sa)
	add_child(glow)
	move_child(glow, main.get_index())


func _physics_process(_delta: float) -> void:
	velocity.x = speed
	move_and_slide()
