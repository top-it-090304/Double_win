extends "res://Game/game_level_spawn_layer.gd"
## База: стражи-лучники стоят на месте; мини HP над юнитами скрыты (у героя отдельный HUD).
## Навигация рабочего: `NavigationServer2D.bake_from_source_geometry_data` из коллизий тайлмапа (без ручных дыр).

const _WorldMiniHpBarScript := preload("res://ui/hp_bar/world_mini_hp_bar.gd")
const _BASE_SHEEP_SCENE := preload("res://ally/sheep/base_sheep.tscn")

var _base_sheep_spawn_queued: bool = false


func _ready() -> void:
	add_to_group("base_sheep_spawner")
	# Стартовая позиция героя — центр тайла лодки (см. GameManager.get_boat_tile_center_global).
	super._ready()
	call_deferred("_setup_base_navigation_from_tile_collisions")
	var tree := get_tree()
	tree.node_added.connect(_on_tree_node_added_hide_unit_hp)
	# После кадров GameManager добавляет героя и отряд — убираем бары со всех юнитов, кроме игрока.
	await tree.process_frame
	await tree.process_frame
	await tree.process_frame
	_hide_mini_hp_bars_on_all_non_player_units()


func _exit_tree() -> void:
	var tree := get_tree()
	if tree and tree.node_added.is_connected(_on_tree_node_added_hide_unit_hp):
		tree.node_added.disconnect(_on_tree_node_added_hide_unit_hp)


func _on_tree_node_added_hide_unit_hp(node: Node) -> void:
	if not is_inside_tree() or not is_ancestor_of(node):
		return
	if not (node is CharacterBody2D):
		return
	call_deferred("_apply_hide_unit_hp_after_ready", node)


func _apply_hide_unit_hp_after_ready(node: Node) -> void:
	if not is_instance_valid(node) or not is_ancestor_of(node):
		return
	if node.is_in_group("player"):
		return
	await node.ready
	if not is_instance_valid(node) or not is_ancestor_of(node):
		return
	if node.is_in_group("player"):
		return
	if not node.is_in_group("character_unit"):
		return
	_remove_world_mini_hp_bar_children(node)


func _hide_mini_hp_bars_on_all_non_player_units() -> void:
	var root := get_tree().current_scene
	if root == null:
		return
	for node in get_tree().get_nodes_in_group("character_unit"):
		if not root.is_ancestor_of(node):
			continue
		if node.is_in_group("player"):
			continue
		_remove_world_mini_hp_bar_children(node)


func _remove_world_mini_hp_bar_children(unit: Node) -> void:
	for c in unit.get_children():
		if c is Control and c.get_script() == _WorldMiniHpBarScript:
			c.queue_free()


func _setup_base_navigation_from_tile_collisions() -> void:
	## Не дублировать регион с `IslandEncounterShared` / старой сценой.
	var old := find_child("IslandNavigationRegion", true, false)
	if old != null:
		old.free()
	var np := NavigationPolygon.new()
	## Чуть больше радиуса коллайдера пешки (~10) — иначе путь прижимается к углам и застревает.
	np.agent_radius = 26.0
	np.cell_size = 1.0
	np.parsed_geometry_type = NavigationPolygon.PARSED_GEOMETRY_STATIC_COLLIDERS
	np.parsed_collision_mask = 0xFFFFFFFF
	np.source_geometry_mode = NavigationPolygon.SOURCE_GEOMETRY_ROOT_NODE_CHILDREN
	var outline := PackedVector2Array([
		Vector2(-3200, -1100),
		Vector2(1600, -1100),
		Vector2(1600, 1200),
		Vector2(-3200, 1200),
	])
	np.add_outline(outline)
	var sg := NavigationMeshSourceGeometryData2D.new()
	var parse_root: Node = find_child("island", true, false)
	if parse_root == null:
		parse_root = self
	NavigationServer2D.parse_source_geometry_data(np, sg, parse_root)
	NavigationServer2D.bake_from_source_geometry_data(np, sg)
	if np.get_polygon_count() < 1:
		push_warning(
			"Game_base_islad: выпечка навигации не дала полигонов — проверь коллизии тайлсета и контур."
		)
		return
	var nav := NavigationRegion2D.new()
	nav.name = "IslandNavigationRegion"
	nav.navigation_layers = 1
	nav.navigation_polygon = np
	add_child(nav)
	call_deferred("_sync_nav_map_cell_size", np.cell_size)


func _sync_nav_map_cell_size(cell_size: float) -> void:
	var cs: float = cell_size
	if cs <= 0.0:
		cs = 1.0
	NavigationServer2D.map_set_cell_size(get_world_2d().get_navigation_map(), cs)


func spawn_base_sheep_random() -> void:
	## Нельзя вызывать add_child из колбэков физики (MeatPickupArea.body_entered) — «flushing queries».
	if _base_sheep_spawn_queued:
		return
	_base_sheep_spawn_queued = true
	call_deferred("_spawn_base_sheep_deferred")


func _spawn_base_sheep_deferred() -> void:
	_base_sheep_spawn_queued = false
	var ch := find_child("charecters", true, false)
	if ch == null:
		push_warning("Game_base_islad: нет узла charecters — овца не заспавнена.")
		return
	var inst := _BASE_SHEEP_SCENE.instantiate() as Node2D
	inst.global_position = _random_point_on_base_navigation()
	ch.add_child(inst)


func _random_point_on_base_navigation() -> Vector2:
	var map_rid: RID = get_world_2d().get_navigation_map()
	for _i in range(40):
		var r := Vector2(randf_range(-2800.0, 1400.0), randf_range(-1000.0, 1100.0))
		var c: Vector2 = NavigationServer2D.map_get_closest_point(map_rid, r)
		if c.distance_to(r) < 220.0:
			return c
	var sz := find_child("SquadSpawnZone", true, false) as Node2D
	var fb := Vector2(-400.0, 880.0)
	if sz != null and is_instance_valid(sz):
		fb = sz.global_position
	return NavigationServer2D.map_get_closest_point(map_rid, fb)
