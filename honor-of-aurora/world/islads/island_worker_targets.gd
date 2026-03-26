class_name IslandWorkerTargets
extends RefCounted
## Поиск точек добычи на базовом острове (`Game_base_islad`): руда — тайлы камня, дерево — тайлы деревьев, мясо — узлы группы `sheep_resource` (в т.ч. `BaseSheep`) или маркеры `island_meat_marker`.


static func find_target_global(scene: Node, job_key: String, from_global: Vector2) -> Vector2:
	if scene == null:
		return Vector2.ZERO
	match job_key:
		"meat":
			return _find_meat_global(scene, from_global)
		"wood":
			return _find_random_tree_tile_global(scene)
		"ore", _:
			return _find_random_ore_tile_global(scene)


static func _tile_center_global(tm: TileMapLayer, cell: Vector2i) -> Vector2:
	var ts := Vector2(64, 64)
	if tm.tile_set:
		ts = Vector2(tm.tile_set.tile_size)
	var local := tm.map_to_local(cell) + ts * 0.5
	return tm.to_global(local)


static func _collect_tile_centers_from_root(root: Node, out: Array[Vector2]) -> void:
	if root is TileMapLayer:
		_append_layer_cells_world(root as TileMapLayer, out)
		return
	for c in root.get_children():
		_collect_tile_centers_from_root(c, out)


static func _append_layer_cells_world(tm: TileMapLayer, out: Array[Vector2]) -> void:
	var cells := tm.get_used_cells()
	if cells.is_empty():
		return
	for cell in cells:
		out.append(_tile_center_global(tm, cell))


static func _find_random_ore_tile_global(scene: Node) -> Vector2:
	var pts: Array[Vector2] = []
	for nm in [&"rocks", &"rock_island"]:
		var rocks := scene.find_child(String(nm), true, false)
		if rocks:
			_collect_tile_centers_from_root(rocks, pts)
	if pts.is_empty():
		return Vector2.ZERO
	return pts[randi() % pts.size()]


static func _find_random_tree_tile_global(scene: Node) -> Vector2:
	var trees := scene.find_child("trees", true, false)
	if trees == null:
		return Vector2.ZERO
	var pts: Array[Vector2] = []
	_collect_tile_centers_from_root(trees, pts)
	if pts.is_empty():
		return Vector2.ZERO
	return pts[randi() % pts.size()]


static func _find_meat_global(scene: Node, from_global: Vector2) -> Vector2:
	var best: Vector2 = Vector2.ZERO
	var bd := INF
	for n in scene.get_tree().get_nodes_in_group("sheep_resource"):
		if not n is Node2D:
			continue
		var n2: Node2D = n as Node2D
		var d := from_global.distance_squared_to(n2.global_position)
		if d < bd:
			bd = d
			best = n2.global_position
	if bd < INF:
		return best
	for n in scene.get_tree().get_nodes_in_group("island_meat_marker"):
		if not n is Node2D:
			continue
		var n2: Node2D = n as Node2D
		var d := from_global.distance_squared_to(n2.global_position)
		if d < bd:
			bd = d
			best = n2.global_position
	return best
