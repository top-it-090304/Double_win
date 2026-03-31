class_name SquadBaseBuildingPatrol
extends RefCounted
## Патруль на базе: зоны группы `base_patrol_zone` (телепорт, меню зданий, спавн и т.д.). Цель — центр зоны; «дошёл» = попал в радиус коллизии зоны. Движение как у рабочего (nav + steer).

const GROUP_PATROL_ZONE := &"base_patrol_zone"

static func collect_shuffled_zone_nodes(tree: SceneTree) -> Array[Node2D]:
	var nodes: Array[Node2D] = []
	if tree == null:
		return nodes
	for n in tree.get_nodes_in_group(GROUP_PATROL_ZONE):
		if not is_instance_valid(n) or not (n is Node2D):
			continue
		nodes.append(n as Node2D)
	if nodes.size() < 2:
		return nodes
	for i in range(nodes.size() - 1, 0, -1):
		var j: int = randi() % (i + 1)
		var t: Node2D = nodes[i]
		nodes[i] = nodes[j]
		nodes[j] = t
	return nodes


static func _find_first_collision_shape(node: Node) -> CollisionShape2D:
	if node is CollisionShape2D:
		return node as CollisionShape2D
	for c in node.get_children():
		var r: CollisionShape2D = _find_first_collision_shape(c)
		if r != null:
			return r
	return null


## Радиус «дошёл до зоны»: по форме коллизии + небольшой запас (не зависит от масок Area ↔ ally).
static func zone_reach_radius(zone: Node) -> float:
	if zone == null or not is_instance_valid(zone):
		return 96.0
	var cs: CollisionShape2D = _find_first_collision_shape(zone)
	if cs == null:
		return 96.0
	var sh: Shape2D = cs.shape
	if sh == null:
		return 96.0
	var pad: float = 18.0
	if sh is CircleShape2D:
		return (sh as CircleShape2D).radius * maxf(absf(cs.global_scale.x), absf(cs.global_scale.y)) + pad
	if sh is RectangleShape2D:
		var s: Vector2 = (sh as RectangleShape2D).size
		var gs: Vector2 = cs.global_scale.abs()
		return maxf(s.x * gs.x, s.y * gs.y) * 0.5 + pad
	if sh is CapsuleShape2D:
		var cap: CapsuleShape2D = sh as CapsuleShape2D
		var gs: Vector2 = cs.global_scale.abs()
		return maxf(cap.radius * maxf(gs.x, gs.y), cap.height * 0.5 * maxf(gs.x, gs.y)) + pad
	return 96.0


static func zone_goal_reached(unit: CharacterBody2D, zone: Node2D) -> bool:
	if zone == null or not is_instance_valid(zone):
		return false
	if zone is Area2D:
		var a: Area2D = zone as Area2D
		if a.monitoring and a.collision_mask != 0 and a.overlaps_body(unit):
			return true
	var r: float = zone_reach_radius(zone)
	return unit.global_position.distance_to(zone.global_position) <= r


## Как следование за героем: путь по нав-сетке + запасной steer (см. `SquadNavFollow` + pawn).
static func velocity_toward_goal_worker_like(
	unit: CharacterBody2D,
	follow_nav: SquadNavFollow,
	goal_global: Vector2,
	speed: float,
	patrol_speed_scale: float,
	follow_use_navigation: bool,
	delta: float
) -> Vector2:
	var spd: float = speed * patrol_speed_scale
	if follow_use_navigation and follow_nav != null:
		var vn: Variant = follow_nav.get_velocity_or_null(unit, goal_global, spd, delta)
		if vn != null and vn is Vector2:
			var fv: Vector2 = vn as Vector2
			if fv.length_squared() > 1.0:
				return fv
			return SquadWorkerLikeSteering.steer_direction(unit, goal_global, spd) * spd
	return SquadWorkerLikeSteering.steer_direction(unit, goal_global, spd) * spd
