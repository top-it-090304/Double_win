extends Node
## Режим «На тапке»: дальний декор (слои после tile_layer_trees_y_sort_migrate) скрывается и
## выводится из группы `y_sortable`, чтобы YSortManager не обходил сотни спрайтов за кадр.
## Узлы регистрируются в группе `slipper_cull_decor_layer` после миграции (см. tile_layer_trees_y_sort_migrate).
## Волна 2 TASK-013: в SLIPPER радиус и частота обновления ужесточены относительно экспорта (меньше активного мира).

const GROUP_SLIPPER_CULL_DECOR := "slipper_cull_decor_layer"
const _YSORT_GROUP := "y_sortable"
const _WIND_GROUP := "wind_decor_sprite"

## Базовые значения сцены; в SLIPPER к ним применяются множители TASK-013.
@export var cull_radius_pixels: float = 2400.0
@export_range(1, 16, 1) var update_every_frames: int = 4

## Только SLIPPER: меньше пикселей — дальше от якоря слои считаются «дальним» декором.
const _SLIPPER_CULL_RADIUS_MULT: float = 0.75
## Только SLIPPER: реже полный проход по слоям (меньше CPU на проверках).
const _SLIPPER_UPDATE_FRAMES_MULT: int = 2
const _SLIPPER_UPDATE_FRAMES_CAP: int = 16
## Гистерезис: скрытый слой показываем по внешнему радиусу, видимый прячем только если
## ни один спрайт не попадает во внутренний — иначе на границе круга декор «мигает».
const _HYST_OUTER_RADIUS_MULT: float = 1.12
const _HYST_INNER_RADIUS_MULT: float = 0.88

var _was_slipper: bool = false


func _process(_delta: float) -> void:
	if not is_inside_tree():
		return
	var tree := get_tree()
	if tree == null:
		return
	var slipper := PerformancePreset.is_slipper_mode(SaveManager)
	if not slipper:
		if _was_slipper:
			_restore_all_under_island()
		_was_slipper = false
		return
	_was_slipper = true
	var eff_every := update_every_frames
	eff_every = clampi(eff_every * _SLIPPER_UPDATE_FRAMES_MULT, 1, _SLIPPER_UPDATE_FRAMES_CAP)
	if eff_every > 1 and (Engine.get_process_frames() % eff_every) != 0:
		return
	var eff_radius := cull_radius_pixels * _SLIPPER_CULL_RADIUS_MULT
	var eff_rsq: float = eff_radius * eff_radius
	var outer_rsq: float = eff_rsq * _HYST_OUTER_RADIUS_MULT * _HYST_OUTER_RADIUS_MULT
	var inner_rsq: float = eff_rsq * _HYST_INNER_RADIUS_MULT * _HYST_INNER_RADIUS_MULT
	var anchor: Variant = _get_anchor_global()
	if anchor == null:
		return
	var island_root: Node = get_parent()
	if island_root == null:
		return
	var apos: Vector2 = anchor as Vector2
	for layer in tree.get_nodes_in_group(GROUP_SLIPPER_CULL_DECOR):
		if layer == null or not is_instance_valid(layer):
			continue
		if not (layer is Node2D):
			continue
		if not layer.is_inside_tree():
			continue
		if not island_root.is_ancestor_of(layer):
			continue
		var n2: Node2D = layer as Node2D
		## По среднему центру слоя нельзя: на одном TileMapLayer тайлы по всему острову —
		## среднее уезжает в «середину карты», и тыквы/грибы у камеры пропадают целыми слоями.
		var should_show: bool
		if n2.visible:
			should_show = _layer_any_sprite_within_radius_sq(n2, apos, inner_rsq)
		else:
			should_show = _layer_any_sprite_within_radius_sq(n2, apos, outer_rsq)
		if should_show:
			if not n2.visible or n2.process_mode == Node.PROCESS_MODE_DISABLED:
				_restore_layer(n2)
		else:
			if n2.visible:
				_cull_layer(n2)


func _get_anchor_global() -> Variant:
	var p: Node = GameManager.current_scene_player
	if p and is_instance_valid(p) and p is Node2D:
		return (p as Node2D).global_position
	var vp := get_viewport()
	if vp == null:
		return null
	var cam := vp.get_camera_2d()
	if cam:
		return cam.global_position
	return null


func _layer_any_sprite_within_radius_sq(layer: Node2D, anchor: Vector2, radius_sq: float) -> bool:
	for c in layer.get_children():
		if c is Sprite2D or c is AnimatedSprite2D:
			var p: Vector2 = (c as Node2D).global_position
			if anchor.distance_squared_to(p) <= radius_sq:
				return true
	## Пустой слой или ещё не мигрировал — ориентир на узел слоя.
	return anchor.distance_squared_to(layer.global_position) <= radius_sq


func _restore_all_under_island() -> void:
	var island_root: Node = get_parent()
	if island_root == null:
		return
	var tree := get_tree()
	if tree == null:
		return
	for layer in tree.get_nodes_in_group(GROUP_SLIPPER_CULL_DECOR):
		if layer == null or not is_instance_valid(layer) or not (layer is Node2D):
			continue
		if not island_root.is_ancestor_of(layer):
			continue
		_restore_layer(layer as Node2D)


func _cull_layer(layer: Node2D) -> void:
	layer.visible = false
	layer.process_mode = Node.PROCESS_MODE_DISABLED
	for c in layer.get_children():
		if c is Sprite2D or c is AnimatedSprite2D:
			if c.is_in_group(_YSORT_GROUP):
				c.remove_from_group(_YSORT_GROUP)
			if c is AnimatedSprite2D and c.is_in_group(_WIND_GROUP):
				c.remove_from_group(_WIND_GROUP)


func _restore_layer(layer: Node2D) -> void:
	layer.visible = true
	layer.process_mode = Node.PROCESS_MODE_INHERIT
	for c in layer.get_children():
		if c is Sprite2D:
			c.add_to_group(_YSORT_GROUP)
		elif c is AnimatedSprite2D:
			c.add_to_group(_YSORT_GROUP)
			c.add_to_group(_WIND_GROUP)
