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


## Сначала `bake_from_source_geometry_data` с пустым source (как в доке Godot 4).
## Если полигонов 0 — копия контуров на **новый** ресурс + `make_polygons_from_outlines`
## (не вызывать make_polygons на том же `NavigationPolygon`, где bake уже трогал данные — merge edge).
func _bake_navigation_polygon_from_outlines(np: NavigationPolygon) -> NavigationPolygon:
	var sg := NavigationMeshSourceGeometryData2D.new()
	NavigationServer2D.bake_from_source_geometry_data(np, sg)
	if np.get_polygon_count() > 0:
		return np
	if np.get_outline_count() == 0:
		return np
	var fb := NavigationPolygon.new()
	_configure_new_navigation_polygon(fb)
	for i in range(np.get_outline_count()):
		fb.add_outline(np.get_outline(i))
	fb.make_polygons_from_outlines()
	if fb.get_polygon_count() > 0:
		return fb
	return np


func _is_game_base_island_scene() -> bool:
	var scene := get_tree().current_scene
	if scene == null:
		return false
	return String(scene.scene_file_path).get_file() == "Game_base_islad.tscn"


func _ready() -> void:
	## Не трогаем navigation_layers — иначе затираются слои, выставленные в редакторе на сцене базы.
	## `Game_base_islad`: навигация сразу пересобирается из коллизий тайлмапа (`game_base_islad.gd`) — не выпекаем пресет (меньше логов и лишней работы).
	if _is_game_base_island_scene():
		_apply_outline(_default_outline)
		return
	if use_base_island_preset:
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
		navigation_polygon = _bake_navigation_polygon_from_outlines(navigation_polygon)
	if navigation_polygon.get_polygon_count() == 0:
		if navigation_polygon.get_outline_count() == 0:
			_apply_outline(_default_outline)
		else:
			push_warning(
				"IslandNavigationRegion: контуры из сцены не дали сетку — запасной прямоугольник. "
				+ "Проверь порядок точек (внешний контур и дырки — противоположное направление обхода)."
			)
			_apply_outline(_default_outline)


func _sync_navigation_map_cell_size() -> void:
	if navigation_polygon == null or not is_inside_tree():
		return
	var cs: float = navigation_polygon.cell_size
	if cs <= 0.0:
		cs = 1.0
	var map_rid: RID = get_world_2d().get_navigation_map()
	NavigationServer2D.map_set_cell_size(map_rid, cs)
	NavigationServer2D.map_set_use_edge_connections(map_rid, false)


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
	np = _bake_navigation_polygon_from_outlines(np)
	if np.get_polygon_count() > 0:
		navigation_polygon = np
		call_deferred("_sync_navigation_map_cell_size")
		return
	if outlines.size() > 0 and outlines[0] is PackedVector2Array:
		var np2 := NavigationPolygon.new()
		_configure_new_navigation_polygon(np2)
		np2.add_outline(outlines[0])
		np2 = _bake_navigation_polygon_from_outlines(np2)
		if np2.get_polygon_count() > 0:
			navigation_polygon = np2
			call_deferred("_sync_navigation_map_cell_size")
			push_warning(
				"IslandNavigationRegion: дыры не собрались, используется только внешний контур пресета."
			)
			return
	_apply_outline(_default_outline)
	if navigation_polygon == null or navigation_polygon.get_polygon_count() < 1:
		push_warning("IslandNavigationRegion: пресет и запасной прямоугольник не дали полигонов навигации.")


func _apply_outline(outline: PackedVector2Array) -> void:
	var np := NavigationPolygon.new()
	_configure_new_navigation_polygon(np)
	np.add_outline(outline)
	np = _bake_navigation_polygon_from_outlines(np)
	navigation_polygon = np
	call_deferred("_sync_navigation_map_cell_size")
