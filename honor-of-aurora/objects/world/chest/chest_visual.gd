extends Node2D
class_name ChestVisual
## Сундук из набора Foozle: только спрайты NO_BACKLIGHT (без подсветки/«фона» за объектом).
## Без @tool — меньше нагрузка при загрузке сцен в редакторе; в игре превью в инспекторе может отставать от tier/state.
## Состояние картинки задаётся через visual_state; «тип» сундука — chest_tier (01…06 в именах файлов).

signal chest_updated()

## Соответствует файлам chests-01 … chests-06 (от простого к более богатому виду).
enum ChestTier {
	TIER_1,
	TIER_2,
	TIER_3,
	TIER_4,
	TIER_5,
	TIER_6,
}

## Вариант отображения (закрыт / пустой / золото / камни / переполнение).
enum ChestVisualState {
	CLOSED,
	OPEN_EMPTY,
	OPEN_GOLD,
	OPEN_GEMS,
	OPEN_GOLD_OVERFLOW,
	OPEN_GEMS_OVERFLOW,
}

const CHEST_PNG_BASE := "res://Asets/chest/Foozle_2DS0003_Elegant_Set_of_Chests_Vector/CHESTS/png"
## Кадр спрайта героя (Warrior atlas 192×192) — ориентир для размера сундука.
const _REF_PLAYER_FRAME_HEIGHT_PX := 192.0
## Высота сундука на экране = эта доля от высоты кадра игрока (0.5 = половина).
const _CHEST_HEIGHT_VS_PLAYER := 0.5

const _STATE_SUBDIR := {
	ChestVisualState.CLOSED: "CLOSED",
	ChestVisualState.OPEN_EMPTY: "OPEN_EMPTY",
	ChestVisualState.OPEN_GOLD: "OPEN_GOLD",
	ChestVisualState.OPEN_GEMS: "OPEN_GEMS",
	ChestVisualState.OPEN_GOLD_OVERFLOW: "OPEN_GOLD_OVERFLOW",
	ChestVisualState.OPEN_GEMS_OVERFLOW: "OPEN_GEMS_OVERFLOW",
}

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


func get_texture_path_for(tier: ChestTier, state: ChestVisualState) -> String:
	var sub: String = _STATE_SUBDIR[state]
	var num := int(tier) + 1
	return "%s/%s/NO_BACKLIGHT/chests-%02d.png" % [CHEST_PNG_BASE, sub, num]


func _refresh_texture() -> void:
	var spr: Sprite2D = _sprite if _sprite != null else get_node_or_null("Sprite2D") as Sprite2D
	if spr == null:
		return
	var path := get_texture_path_for(chest_tier, visual_state)
	var tex: Texture2D = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_REUSE) as Texture2D
	if tex == null:
		push_warning("ChestVisual: нет текстуры %s" % path)
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
	var spr: Sprite2D = _sprite if _sprite != null else get_node_or_null("Sprite2D") as Sprite2D
	if spr == null or spr.texture == null:
		return global_position.y + y_sort_bottom_pixel_offset
	var tex_h := float(spr.texture.get_height())
	var sy := absf(spr.global_scale.y)
	var h := tex_h * sy
	var cy := spr.global_position.y
	var ratio := clampf(y_sort_ground_ratio, 0.0, 1.0)
	return cy + h * (ratio - 0.5) + y_sort_bottom_pixel_offset
