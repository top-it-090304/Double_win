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


func apply_paralysis(target: Node, duration_sec: float) -> void:
	if target == null or not is_instance_valid(target) or duration_sec <= 0.0:
		return
	if target.has_method("apply_paralysis"):
		target.call("apply_paralysis", duration_sec)


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


func try_spend_wood(amount: int) -> bool:
	if amount <= 0:
		return true
	if SaveManager.wood_count < amount:
		return false
	GameManager.add_wood(-amount)
	return true


func try_spend_ore(amount: int) -> bool:
	if amount <= 0:
		return true
	if SaveManager.ore_count < amount:
		return false
	GameManager.add_ore(-amount)
	return true


func try_spend_gold_or_ore(gold_amount: int) -> bool:
	if gold_amount <= 0:
		return true
	if SaveManager.gold >= gold_amount:
		return try_spend_gold(gold_amount)
	var shortage := gold_amount - SaveManager.gold
	var ore_needed := BalanceConfig.get_ore_needed_for_gold(shortage)
	if SaveManager.ore_count < ore_needed:
		return false
	var spend_gold := SaveManager.gold
	if spend_gold > 0:
		GameManager.add_gold(-spend_gold)
	return try_spend_ore(ore_needed)


func try_spend_wood_or_ore(wood_amount: int) -> bool:
	if wood_amount <= 0:
		return true
	if SaveManager.wood_count >= wood_amount:
		return try_spend_wood(wood_amount)
	var shortage := wood_amount - SaveManager.wood_count
	var ore_needed := BalanceConfig.get_ore_needed_for_wood(shortage)
	if SaveManager.ore_count < ore_needed:
		return false
	var spend_wood := SaveManager.wood_count
	if spend_wood > 0:
		GameManager.add_wood(-spend_wood)
	return try_spend_ore(ore_needed)


func can_afford_gold_plus_ore(gold_amount: int, ore_amount: int) -> bool:
	var gold_shortage := maxi(0, gold_amount - SaveManager.gold)
	var ore_for_gold := BalanceConfig.get_ore_needed_for_gold(gold_shortage)
	return SaveManager.ore_count >= ore_amount + ore_for_gold


func try_spend_gold_plus_ore(gold_amount: int, ore_amount: int) -> bool:
	gold_amount = maxi(0, gold_amount)
	ore_amount = maxi(0, ore_amount)
	var gold_shortage := maxi(0, gold_amount - SaveManager.gold)
	var ore_for_gold := BalanceConfig.get_ore_needed_for_gold(gold_shortage)
	var total_ore := ore_amount + ore_for_gold
	if SaveManager.ore_count < total_ore:
		return false
	var spend_gold := mini(SaveManager.gold, gold_amount)
	if spend_gold > 0:
		GameManager.add_gold(-spend_gold)
	if total_ore > 0:
		GameManager.add_ore(-total_ore)
	return true


func purchase_premium_ore_pack(pack_id: String) -> bool:
	return GameManager.purchase_premium_ore_pack(pack_id)


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
