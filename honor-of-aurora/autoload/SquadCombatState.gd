extends Node
## Состояние боя: герой или купленный юнит в зоне врага (обнаружение / атака / преследование).
## Пока true — меню приказов отряду открыть нельзя.

## Враги дальше этого радиуса от героя не блокируют открытие сундука (см. `is_engaged_near_player`).
const CHEST_BLOCK_ENEMY_RADIUS_PX: float = 280.0

func is_engaged() -> bool:
	var tree := get_tree()
	if tree == null:
		return false
	if tree.get_node_count_in_group(&"enemy") < 1:
		return false
	var scene := tree.current_scene
	if scene == null:
		return false
	for enemy in tree.get_nodes_in_group("enemy"):
		if not is_instance_valid(enemy):
			continue
		if not scene.is_ancestor_of(enemy as Node):
			continue
		if _enemy_threatens_hero_or_squad(enemy):
			return true
	return false


## Как `is_engaged()`, но только для врагов в радиусе `radius_px` от героя — для сундуков и UX «нет врагов рядом».
func is_engaged_near_player(radius_px: float = CHEST_BLOCK_ENEMY_RADIUS_PX) -> bool:
	var tree := get_tree()
	if tree == null:
		return false
	if tree.get_node_count_in_group(&"enemy") < 1:
		return false
	var player := tree.get_first_node_in_group(&"player") as Node2D
	if player == null or not is_instance_valid(player):
		return false
	var scene := tree.current_scene
	if scene == null:
		return false
	var rsq: float = radius_px * radius_px
	for enemy in tree.get_nodes_in_group("enemy"):
		if not is_instance_valid(enemy):
			continue
		if not scene.is_ancestor_of(enemy as Node):
			continue
		if enemy is Node2D:
			if (enemy as Node2D).global_position.distance_squared_to(player.global_position) > rsq:
				continue
		else:
			continue
		if _enemy_threatens_hero_or_squad(enemy):
			return true
	return false


func _enemy_threatens_hero_or_squad(enemy: Node) -> bool:
	var da := enemy.get_node_or_null("DetectionArea") as Area2D
	if da and da.monitoring:
		for body in da.get_overlapping_bodies():
			if body == null or not is_instance_valid(body):
				continue
			if _is_hero_or_squad(body):
				return true
	var aa := enemy.get_node_or_null("AttackArea") as Area2D
	if aa and aa.monitoring:
		for body in aa.get_overlapping_bodies():
			if body == null or not is_instance_valid(body):
				continue
			if _is_hero_or_squad(body):
				return true
	if _enemy_chasing_or_attacking_hero_or_squad(enemy):
		return true
	return false


func _is_hero_or_squad(body: Node) -> bool:
	return body != null and is_instance_valid(body) and (body.is_in_group("player") or body.is_in_group("squad_member"))


## enemy_base.State: CHASE=1, ATTACK=2 — цель герой или отряд.
func _enemy_chasing_or_attacking_hero_or_squad(enemy: Node) -> bool:
	if not ("state" in enemy) or not ("target" in enemy):
		return false
	var st: Variant = enemy.get("state")
	var st_int := int(st)
	if st_int != 1 and st_int != 2:
		return false
	var tgt: Variant = enemy.get("target")
	if tgt == null or not is_instance_valid(tgt):
		return false
	return _is_hero_or_squad(tgt as Node)
