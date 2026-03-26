extends NavigationRegion2D
## Один регион навигации на остров: по умолчанию — большой прямоугольник.
## `use_base_island_preset` — контур базы с дырами под стены (см. `base_island_nav_preset.gd`).

@export var use_base_island_preset: bool = false
## Включи, когда контуры дырок в пресете проверены в редакторе. Иначе движок может падать в merge edge (см. лог).
@export var use_preset_holes: bool = false

var _default_outline: PackedVector2Array = PackedVector2Array([
	Vector2(-3200, -1100),
	Vector2(1600, -1100),
	Vector2(1600, 1200),
	Vector2(-3200, 1200),
])


func _is_game_base_island_scene() -> bool:
	var scene := get_tree().current_scene
	if scene == null:
		return false
	return String(scene.scene_file_path).get_file() == "Game_base_islad.tscn"


func _ready() -> void:
	## Не трогаем navigation_layers — иначе затираются слои, выставленные в редакторе на сцене базы.
	## На базе — пресет острова. По умолчанию без дыр (`use_preset_holes`), иначе merge edge в NavigationServer.
	if use_base_island_preset or _is_game_base_island_scene():
		var outlines: Array = (
			BaseIslandNavigationPreset.get_outline_arrays()
			if use_preset_holes
			else BaseIslandNavigationPreset.get_outline_arrays_outer_only()
		)
		_apply_preset_from_arrays(outlines)
		return
	if navigation_polygon == null:
		_apply_outline(_default_outline)
		return
	if navigation_polygon.get_polygon_count() == 0 and navigation_polygon.get_outline_count() > 0:
		navigation_polygon.make_polygons_from_outlines()
	if navigation_polygon.get_polygon_count() == 0:
		if navigation_polygon.get_outline_count() == 0:
			_apply_outline(_default_outline)
		else:
			push_error(
				"IslandNavigationRegion: не удалось собрать полигоны из контуров (дырки/стены?). "
				+ "Проверь порядок точек: внешний остров — в одну сторону, дырки — в противоположную."
			)


func _sync_navigation_map_cell_size() -> void:
	if navigation_polygon == null or not is_inside_tree():
		return
	var cs: float = navigation_polygon.cell_size
	if cs <= 0.0:
		cs = 1.0
	NavigationServer2D.map_set_cell_size(get_world_2d().get_navigation_map(), cs)


func _configure_new_navigation_polygon(np: NavigationPolygon) -> void:
	np.cell_size = 1.0
	if np.agent_radius <= 0.0:
		np.agent_radius = 10.0


func _apply_preset_from_arrays(outlines: Array) -> void:
	if outlines.is_empty():
		_apply_outline(_default_outline)
		return
	var np := NavigationPolygon.new()
	_configure_new_navigation_polygon(np)
	for o in outlines:
		if o is PackedVector2Array and (o as PackedVector2Array).size() >= 3:
			np.add_outline(o)
	np.make_polygons_from_outlines()
	if np.get_polygon_count() > 0:
		navigation_polygon = np
		call_deferred("_sync_navigation_map_cell_size")
		return
	if outlines.size() > 0 and outlines[0] is PackedVector2Array:
		var np2 := NavigationPolygon.new()
		_configure_new_navigation_polygon(np2)
		np2.add_outline(outlines[0])
		np2.make_polygons_from_outlines()
		if np2.get_polygon_count() > 0:
			navigation_polygon = np2
			call_deferred("_sync_navigation_map_cell_size")
			push_warning(
				"IslandNavigationRegion: дыры не собрались, используется только внешний контур пресета."
			)
			return
	_apply_outline(_default_outline)
	push_warning("IslandNavigationRegion: пресет не применён, используется запасной прямоугольник.")


func _apply_outline(outline: PackedVector2Array) -> void:
	var np := NavigationPolygon.new()
	_configure_new_navigation_polygon(np)
	np.add_outline(outline)
	np.make_polygons_from_outlines()
	navigation_polygon = np
	call_deferred("_sync_navigation_map_cell_size")
