extends Node
## Режим «На тапке»: дальний декор (слои после tile_layer_trees_y_sort_migrate) скрывается и
## выводится из группы `y_sortable`, чтобы YSortManager не обходил сотни спрайтов за кадр.
## Узлы регистрируются в группе `slipper_cull_decor_layer` после миграции (см. tile_layer_trees_y_sort_migrate).

const GROUP_SLIPPER_CULL_DECOR := "slipper_cull_decor_layer"
const _YSORT_GROUP := "y_sortable"
const _WIND_GROUP := "wind_decor_sprite"

@export var cull_radius_pixels: float = 2400.0
@export_range(1, 8, 1) var update_every_frames: int = 4

var _rsq: float = 0.0
var _was_slipper: bool = false


func _ready() -> void:
	_rsq = cull_radius_pixels * cull_radius_pixels


func _process(_delta: float) -> void:
	if update_every_frames > 1 and (Engine.get_process_frames() % update_every_frames) != 0:
		return
	var slipper := PerformancePreset.is_slipper_mode(SaveManager)
	if not slipper:
		if _was_slipper:
			_restore_all_under_island()
		_was_slipper = false
		return
	_was_slipper = true
	var anchor: Variant = _get_anchor_global()
	if anchor == null:
		return
	var island_root: Node = get_parent()
	if island_root == null:
		return
	var apos: Vector2 = anchor as Vector2
	for layer in get_tree().get_nodes_in_group(GROUP_SLIPPER_CULL_DECOR):
		if layer == null or not is_instance_valid(layer):
			continue
		if not (layer is Node2D):
			continue
		if not layer.is_inside_tree():
			continue
		if not island_root.is_ancestor_of(layer):
			continue
		var n2: Node2D = layer as Node2D
		var center := _layer_content_center_global(n2)
		var should_show := apos.distance_squared_to(center) <= _rsq
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
	var cam := get_viewport().get_camera_2d()
	if cam:
		return cam.global_position
	return null


func _layer_content_center_global(layer: Node2D) -> Vector2:
	var sum := Vector2.ZERO
	var n := 0
	for c in layer.get_children():
		if c is Node2D:
			sum += (c as Node2D).global_position
			n += 1
	if n == 0:
		return layer.global_position
	return sum / float(n)


func _restore_all_under_island() -> void:
	var island_root: Node = get_parent()
	if island_root == null:
		return
	for layer in get_tree().get_nodes_in_group(GROUP_SLIPPER_CULL_DECOR):
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
