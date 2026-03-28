class_name SquadWorkerLikeSteering
extends RefCounted
## Локальный обход препятствий как у `pawn_base.gd` (лучи + скольжение у стены).

const STEER_LOOKAHEAD_MIN: float = 88.0
const STEER_LOOKAHEAD_SPEED_MUL: float = 0.22
const STEER_BODY_HALF_WIDTH: float = 10.0


static func _probe_origin(unit: CharacterBody2D) -> Vector2:
	var cs := unit.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if cs != null and is_instance_valid(cs):
		return cs.global_position
	return unit.global_position


static func _lookahead(move_speed: float) -> float:
	return maxf(STEER_LOOKAHEAD_MIN, move_speed * STEER_LOOKAHEAD_SPEED_MUL)


static func _ray_wall_blocked(unit: CharacterBody2D, dir: Vector2, distance: float) -> bool:
	if dir.length_squared() < 1e-8:
		return true
	if not unit.is_inside_tree():
		return false
	var d := dir.normalized()
	var space := unit.get_world_2d().direct_space_state
	if space == null:
		return false
	var perp := Vector2(-d.y, d.x)
	var origin_base := _probe_origin(unit)
	var dist := maxf(24.0, distance)
	var mask: int = unit.collision_mask
	for lateral: float in [-STEER_BODY_HALF_WIDTH, 0.0, STEER_BODY_HALF_WIDTH]:
		var start: Vector2 = origin_base + perp * lateral + d * 8.0
		var end: Vector2 = start + d * dist
		var params := PhysicsRayQueryParameters2D.create(start, end)
		params.collision_mask = mask
		params.hit_from_inside = true
		params.exclude = [unit.get_rid()]
		if space.intersect_ray(params) != null:
			return true
	return false


static func steer_direction(unit: CharacterBody2D, goal_global: Vector2, move_speed: float) -> Vector2:
	var to_goal := goal_global - unit.global_position
	var hint := to_goal.normalized() if to_goal.length_squared() > 4.0 else Vector2.RIGHT
	var look := _lookahead(move_speed)
	if not _ray_wall_blocked(unit, hint, look):
		return hint
	var best := hint
	var best_dot := -2.0
	for i in range(-18, 19):
		if i == 0:
			continue
		var ang := float(i) * (PI / 18.0)
		var dd := hint.rotated(ang)
		if not _ray_wall_blocked(unit, dd, look):
			var dot: float = dd.dot(hint)
			if dot > best_dot:
				best_dot = dot
				best = dd
	if best_dot > -1.55:
		return best
	for i in range(-36, 37):
		if i == 0:
			continue
		var ang2 := float(i) * (PI / 36.0)
		var dd2 := hint.rotated(ang2)
		if not _ray_wall_blocked(unit, dd2, look * 0.82):
			var dot2: float = dd2.dot(hint)
			if dot2 > best_dot:
				best_dot = dot2
				best = dd2
	if best_dot > -1.85:
		return best
	for sgn in [-1.0, 1.0]:
		var side: Vector2 = hint.rotated(sgn * PI * 0.5)
		if not _ray_wall_blocked(unit, side, look * 0.7):
			return side
	for j in range(0, 16):
		var ang3 := float(j) * (PI / 8.0)
		var dd3 := Vector2.RIGHT.rotated(ang3)
		if not _ray_wall_blocked(unit, dd3, look * 0.55):
			return dd3
	return hint.rotated(PI * 0.5)


static func apply_wall_slide_toward(unit: CharacterBody2D, goal_global: Vector2, move_speed: float) -> void:
	if not unit.is_on_wall():
		return
	var n := unit.get_wall_normal()
	if n.length_squared() < 0.01:
		return
	unit.velocity = unit.velocity.slide(n)
	if unit.velocity.length_squared() < 400.0:
		var to_g := goal_global - unit.global_position
		var tangent := Vector2(-n.y, n.x)
		if tangent.dot(to_g) < 0.0:
			tangent = -tangent
		unit.velocity = tangent * move_speed * 0.88
