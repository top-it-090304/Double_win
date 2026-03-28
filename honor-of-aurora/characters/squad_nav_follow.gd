class_name SquadNavFollow
extends RefCounted
## Следование по нав-сетке сцены (как у pawn_base: map_get_path + слои региона острова/базы).

const WP_ADVANCE_DIST: float = 14.0
const REPATH_INTERVAL: float = 0.32
const GOAL_REPATH_DIST: float = 72.0

var _path: PackedVector2Array = PackedVector2Array()
var _idx: int = 0
var _repath_cd: float = 0.0
var nav_layers: int = 1
var _last_goal: Vector2 = Vector2.ZERO


func clear() -> void:
	_path.clear()
	_idx = 0
	_repath_cd = 0.0
	_last_goal = Vector2.ZERO


func sync_nav_layers_from_scene(unit: Node2D) -> void:
	if unit == null or not is_instance_valid(unit) or not unit.is_inside_tree():
		nav_layers = 1
		return
	var tree: SceneTree = unit.get_tree()
	if tree == null:
		nav_layers = 1
		return
	var scene: Node = tree.current_scene
	if scene == null:
		nav_layers = 1
		return
	var nr := scene.find_child("IslandNavigationRegion", true, false)
	if nr is NavigationRegion2D:
		nav_layers = (nr as NavigationRegion2D).navigation_layers
	else:
		nav_layers = 1


func get_velocity_or_null(
	unit: CharacterBody2D,
	goal_global: Vector2,
	speed: float,
	delta: float
) -> Variant:
	_repath_cd = maxf(0.0, _repath_cd - delta)
	var goal_moved: bool = _last_goal.distance_squared_to(goal_global) > GOAL_REPATH_DIST * GOAL_REPATH_DIST
	if _path.is_empty() or _repath_cd <= 0.0 or goal_moved:
		_path = _compute_path(unit, goal_global)
		_idx = 0
		_repath_cd = REPATH_INTERVAL
		_last_goal = goal_global
	if _path.is_empty():
		return null
	if _path.size() == 1:
		var to_p: Vector2 = _path[0] - unit.global_position
		if to_p.length_squared() < 6.25:
			return Vector2.ZERO
		return to_p.normalized() * speed
	while _idx < _path.size() - 1 and unit.global_position.distance_to(_path[_idx]) < WP_ADVANCE_DIST:
		_idx += 1
	var wp: Vector2 = _path[_idx]
	var to_wp: Vector2 = wp - unit.global_position
	if to_wp.length_squared() < 4.0 and _idx < _path.size() - 1:
		_idx += 1
		wp = _path[_idx]
		to_wp = wp - unit.global_position
	if to_wp.length_squared() < 1e-6:
		return Vector2.ZERO
	return to_wp.normalized() * speed


func _compute_path(unit: CharacterBody2D, goal: Vector2) -> PackedVector2Array:
	if unit == null or not is_instance_valid(unit) or not unit.is_inside_tree():
		return PackedVector2Array()
	var world: World2D = unit.get_world_2d()
	if world == null:
		return PackedVector2Array()
	var map_rid: RID = world.get_navigation_map()
	if map_rid == RID():
		return PackedVector2Array()
	var start_pt: Vector2 = NavigationServer2D.map_get_closest_point(map_rid, unit.global_position)
	var goal_pt: Vector2 = NavigationServer2D.map_get_closest_point(map_rid, goal)
	var path: PackedVector2Array = NavigationServer2D.map_get_path(
		map_rid, start_pt, goal_pt, false, nav_layers
	)
	if path.is_empty() and start_pt.distance_squared_to(goal_pt) > 4.0:
		path = NavigationServer2D.map_get_path(map_rid, start_pt, goal_pt, true, nav_layers)
	return path
