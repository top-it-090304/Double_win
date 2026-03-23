extends Node
## Фасад боя, HUD и золота (autoload).

const DAMAGE_NUMBER_SCENE := preload("res://ui/DamageNumber/damage_number.tscn")


func try_apply_damage(target: Node, amount: int) -> bool:
	if target == null or not is_instance_valid(target):
		return false
	if not target.has_method("take_damage"):
		return false
	target.take_damage(amount)
	return true


func try_apply_heal(target: Node, amount: int) -> bool:
	if target == null or not is_instance_valid(target) or amount <= 0:
		return false
	if target.has_method("heal"):
		target.heal(amount)
		return true
	return try_apply_damage(target, -amount)


func spawn_damage_number(parent: Node2D, amount: int, offset: Vector2 = Vector2(-26, -80)) -> void:
	if parent == null or not is_instance_valid(parent):
		return
	var dn: Control = DAMAGE_NUMBER_SCENE.instantiate() as Control
	if dn == null:
		return
	var label := dn.get_node_or_null("Label") as Label
	if label:
		label.text = str(amount)
	parent.add_child(dn)
	dn.position = offset


func try_spend_gold(amount: int) -> bool:
	if amount <= 0:
		return true
	if SaveManager.gold < amount:
		return false
	GameManager.add_gold(-amount)
	return true


func get_hud(tree: SceneTree) -> Node:
	if tree == null:
		return null
	return tree.get_first_node_in_group("hud")


func is_player_body(body: Node) -> bool:
	return body != null and is_instance_valid(body) and body.is_in_group("player")


func can_receive_monk_heal(body: Node) -> bool:
	if body == null or not is_instance_valid(body):
		return false
	if is_player_body(body):
		return true
	if body.is_in_group("healer"):
		return true
	## Отряд: лучники, копейщики, пешки — те же боевые юниты, что и герой (character_unit).
	if body.is_in_group("ally") and body.is_in_group("character_unit"):
		return true
	return false
