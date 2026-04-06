extends Node2D
class_name ChestVisual
## Два спрайта: закрытый и открытый (`res://Asets/chest/chests-01*.png`).
## Состояние картинки — `visual_state`; ярус лута (`chest_tier`) на вид не влияет.

signal chest_updated()

## Сохранён для лута и инспектора; на текстуру не влияет.
enum ChestTier {
	TIER_1,
	TIER_2,
	TIER_3,
	TIER_4,
	TIER_5,
	TIER_6,
}

## Все «открытые» варианты используют одну текстуру открытого сундука.
enum ChestVisualState {
	CLOSED,
	OPEN_EMPTY,
	OPEN_GOLD,
	OPEN_GEMS,
	OPEN_GOLD_OVERFLOW,
	OPEN_GEMS_OVERFLOW,
}

const TEXTURE_CLOSED := "res://Asets/chest/chests-01.png"
const TEXTURE_OPENED := "res://Asets/chest/chests-01_opened.png"

static var _chest_texture_cache: Dictionary = {}

## Кадр спрайта героя (Warrior atlas 192×192) — ориентир для размера сундука.
const _REF_PLAYER_FRAME_HEIGHT_PX := 192.0
## Высота сундука на экране = эта доля от высоты кадра игрока (0.5 = половина).
const _CHEST_HEIGHT_VS_PLAYER := 0.5

@export var chest_tier: ChestTier = ChestTier.TIER_1:
	set(v):
		chest_tier = v
		if is_node_ready():
			_refresh_texture()

@export var visual_state: ChestVisualState = ChestVisualState.CLOSED:
	set(v):
		visual_state = v
		if is_node_ready():
			_refresh_texture()

## Точка «ног» для Y-сортировки: 1.0 — низ спрайта.
@export_range(0.0, 1.0, 0.01) var y_sort_ground_ratio: float = 1.0
@export var y_sort_bottom_pixel_offset: float = 0.0

@onready var _sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	add_to_group("y_sortable")
	_refresh_texture()


func set_visual_state(next: ChestVisualState) -> void:
	visual_state = next


func set_tier(tier: ChestTier) -> void:
	chest_tier = tier


## Удобные обёртки для геймплея.
func show_closed() -> void:
	set_visual_state(ChestVisualState.CLOSED)


func show_open_empty() -> void:
	set_visual_state(ChestVisualState.OPEN_EMPTY)


func show_open_gold() -> void:
	set_visual_state(ChestVisualState.OPEN_GOLD)


func show_open_gems() -> void:
	set_visual_state(ChestVisualState.OPEN_GEMS)


func show_open_gold_overflow() -> void:
	set_visual_state(ChestVisualState.OPEN_GOLD_OVERFLOW)


func show_open_gems_overflow() -> void:
	set_visual_state(ChestVisualState.OPEN_GEMS_OVERFLOW)


func is_closed_visual() -> bool:
	return visual_state == ChestVisualState.CLOSED


func get_texture_path_for(_tier: ChestTier, state: ChestVisualState) -> String:
	return TEXTURE_CLOSED if state == ChestVisualState.CLOSED else TEXTURE_OPENED


func _is_open_state(state: ChestVisualState) -> bool:
	return state != ChestVisualState.CLOSED


func _texture_for_visual_state(state: ChestVisualState) -> Texture2D:
	var path: String = TEXTURE_OPENED if _is_open_state(state) else TEXTURE_CLOSED
	if _chest_texture_cache.has(path):
		return _chest_texture_cache[path] as Texture2D
	var tex: Texture2D = ResourceLoader.load(path, "Texture2D", ResourceLoader.CACHE_MODE_REUSE) as Texture2D
	if tex != null:
		_chest_texture_cache[path] = tex
	return tex


func _refresh_texture() -> void:
	var spr: Sprite2D = _sprite if _sprite != null else get_node_or_null("Sprite2D") as Sprite2D
	if spr == null:
		return
	var tex: Texture2D = _texture_for_visual_state(visual_state)
	if tex == null:
		push_warning("ChestVisual: нет текстуры для state=%s (пути: %s / %s)" % [visual_state, TEXTURE_CLOSED, TEXTURE_OPENED])
		return
	spr.texture = tex
	_apply_display_scale(spr)
	emit_signal("chest_updated")


func _apply_display_scale(spr: Sprite2D) -> void:
	if spr.texture == null:
		return
	var src_h: float = float(spr.texture.get_height())
	if src_h <= 0.0:
		return
	var target_h: float = _REF_PLAYER_FRAME_HEIGHT_PX * _CHEST_HEIGHT_VS_PLAYER
	var s: float = target_h / src_h
	spr.scale = Vector2(s, s)
	## Низ спрайта у локального y=0 (якорь на «земле»).
	spr.position = Vector2(0.0, -target_h * 0.5)


func get_y_sort_bottom_y() -> float:
	var from_sprites := YSortSpriteBounds.max_global_y_from_descendants(self)
	if not is_nan(from_sprites):
		return from_sprites + y_sort_bottom_pixel_offset
	var spr: Sprite2D = _sprite if _sprite != null else get_node_or_null("Sprite2D") as Sprite2D
	if spr == null or spr.texture == null:
		return global_position.y + y_sort_bottom_pixel_offset
	var tex_h := float(spr.texture.get_height())
	var sy := absf(spr.global_scale.y)
	var h := tex_h * sy
	var cy := spr.global_position.y
	var ratio := clampf(y_sort_ground_ratio, 0.0, 1.0)
	return cy + h * (ratio - 0.5) + y_sort_bottom_pixel_offset
