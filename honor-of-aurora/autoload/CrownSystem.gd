extends Node
## Система Короны: караваны, приказы, титулы, немилость, шахта, провизия, привал.
## Autoload — зависит от SaveManager, BalanceConfig, Events, StoryState, GameManager.


## Диалог прибытия запускает GameManager после смены сцены на базу (см. `_try_caravan_arrival_dialogue_on_base_ready`):
## иначе `call_deferred` с сигнала срабатывает до готовности HUD — `DialogueWindow` вне дерева и `get_tree()` падает.


## ═══════════════════════════════════════════════════════
##  ШАХТА — пассивная добыча руды при возврате с похода
## ═══════════════════════════════════════════════════════

func get_mine_tier() -> int:
	return SaveManager.get_building_tier("Mine")


func harvest_mine_on_expedition_return() -> int:
	var pawns_on_base := SaveManager.pawn_count
	var title_bonus := BalanceConfig.get_crown_mine_ore_bonus(SaveManager.ore_sent_to_crown_total)
	var ore := BalanceConfig.get_mine_ore_per_return(get_mine_tier(), pawns_on_base, title_bonus)
	if ore > 0:
		GameManager.add_ore(ore)
		Events.mine_harvested.emit(ore)
	return ore


## ═══════════════════════════════════════════════════════
##  ПРОВИЗИЯ — мясо как стоимость похода
## ═══════════════════════════════════════════════════════

func get_expedition_meat_cost() -> int:
	var warriors := SaveManager.archer_count + SaveManager.lancer_count
	return BalanceConfig.get_expedition_meat_cost(warriors)


func can_afford_expedition() -> bool:
	return SaveManager.meat_count >= get_expedition_meat_cost()


func spend_expedition_provisions() -> bool:
	var cost := get_expedition_meat_cost()
	if SaveManager.meat_count < cost:
		return false
	GameManager.add_meat(-cost)
	_reset_expedition_tracking()
	return true


func _reset_expedition_tracking() -> void:
	SaveManager.rest_used_this_expedition = 0
	SaveManager.expedition_ore_collected = 0
	SaveManager.expedition_wood_collected = 0
	SaveManager.expedition_meat_collected = 0
	degrade_armor()


## ═══════════════════════════════════════════════════════
##  ПРИВАЛ — хил героя за мясо на острове
## ═══════════════════════════════════════════════════════

func can_rest() -> bool:
	if SaveManager.rest_used_this_expedition >= BalanceConfig.REST_MAX_PER_EXPEDITION:
		return false
	if SaveManager.meat_count < BalanceConfig.REST_MEAT_COST:
		return false
	return true


func get_rests_remaining() -> int:
	return maxi(0, BalanceConfig.REST_MAX_PER_EXPEDITION - SaveManager.rest_used_this_expedition)


func try_rest(hero_node: Node) -> bool:
	if not can_rest():
		return false
	if hero_node == null or not is_instance_valid(hero_node):
		return false
	GameManager.add_meat(-BalanceConfig.REST_MEAT_COST)
	SaveManager.rest_used_this_expedition += 1
	var max_hp := 100
	if hero_node.has_method("get_max_health"):
		max_hp = int(hero_node.get_max_health())
	elif hero_node.get("max_health") != null:
		max_hp = int(hero_node.get("max_health"))
	var base_heal := BalanceConfig.get_rest_heal_amount(max_hp)
	var heal := maxi(1, int(round(float(base_heal) * get_rest_modifier())))
	if hero_node.has_method("heal"):
		hero_node.heal(heal)
	elif GameplayFacade.try_apply_heal(hero_node, heal):
		pass
	Events.rest_used.emit(heal, get_rests_remaining())
	return true


## ═══════════════════════════════════════════════════════
##  РЕСУРСНЫЕ CAP-Ы ЗА ПОХОД
## ═══════════════════════════════════════════════════════

func can_collect_expedition_ore() -> bool:
	return SaveManager.expedition_ore_collected < BalanceConfig.MAX_ORE_PER_EXPEDITION


func can_collect_expedition_wood() -> bool:
	return SaveManager.expedition_wood_collected < BalanceConfig.MAX_WOOD_PER_EXPEDITION


func can_collect_expedition_meat() -> bool:
	return SaveManager.expedition_meat_collected < BalanceConfig.MAX_MEAT_PER_EXPEDITION


func track_expedition_ore(amount: int) -> void:
	SaveManager.expedition_ore_collected += maxi(0, amount)


func track_expedition_wood(amount: int) -> void:
	SaveManager.expedition_wood_collected += maxi(0, amount)


func track_expedition_meat(amount: int) -> void:
	SaveManager.expedition_meat_collected += maxi(0, amount)


## ═══════════════════════════════════════════════════════
##  КАРАВАН КОРОНЫ
## ═══════════════════════════════════════════════════════

func tick_caravan_on_expedition_return() -> void:
	if SaveManager.caravan_pending:
		return
	SaveManager.expeditions_until_caravan -= 1
	if SaveManager.expeditions_until_caravan <= 0:
		_arrive_caravan()
	_tick_crown_order_deadline()
	SaveManager.save_game()


func _arrive_caravan() -> void:
	SaveManager.caravan_pending = true
	SaveManager.expeditions_until_caravan = BalanceConfig.CARAVAN_EXPEDITION_INTERVAL
	_advance_crown_order_if_needed()
	_deliver_caravan_supplies()
	var order_idx := SaveManager.crown_order_index
	Events.caravan_arrived.emit(order_idx)
	Events.caravan_pending_changed.emit(true)


func _deliver_caravan_supplies() -> void:
	var gold := BalanceConfig.get_caravan_supply_gold()
	var meat := BalanceConfig.get_caravan_supply_meat()
	gold = int(round(float(gold) * BalanceConfig.get_displeasure_gold_mult(SaveManager.crown_displeasure)))
	if gold > 0:
		GameManager.add_gold(gold)
	if meat > 0:
		GameManager.add_meat(meat)


func _advance_crown_order_if_needed() -> void:
	if SaveManager.crown_order_index <= 0:
		_issue_next_crown_order()
		return
	var order := BalanceConfig.get_crown_order(SaveManager.crown_order_index)
	if order.is_empty():
		return
	var required := int(order.get("ore_required", 0))
	if SaveManager.crown_order_ore_sent >= required:
		_issue_next_crown_order()


func _issue_next_crown_order() -> void:
	var next_idx := SaveManager.crown_order_index + 1
	var order := BalanceConfig.get_crown_order(next_idx)
	if order.is_empty():
		return
	SaveManager.crown_order_index = next_idx
	SaveManager.crown_order_ore_sent = 0
	SaveManager.crown_order_deadline_remaining = int(order.get("deadline_expeditions", 4))
	SaveManager.save_game()


func _tick_crown_order_deadline() -> void:
	if SaveManager.crown_order_index <= 0:
		return
	if SaveManager.crown_order_deadline_remaining > 0:
		SaveManager.crown_order_deadline_remaining -= 1
	if SaveManager.crown_order_deadline_remaining <= 0:
		var order := BalanceConfig.get_crown_order(SaveManager.crown_order_index)
		if order.is_empty():
			return
		var required := int(order.get("ore_required", 0))
		if SaveManager.crown_order_ore_sent < int(required * 0.5):
			_apply_order_failure()


func _apply_order_failure() -> void:
	SaveManager.crown_orders_failed += 1
	SaveManager.crown_displeasure = clampi(
		SaveManager.crown_displeasure + 1, 0, BalanceConfig.DISPLEASURE_MAX_LEVEL
	)
	if SaveManager.crown_favor > 0:
		SaveManager.crown_favor = 0
		Events.crown_favor_changed.emit(0)
	Events.crown_displeasure_changed.emit(SaveManager.crown_displeasure)
	SaveManager.save_game()


## ═══════════════════════════════════════════════════════
##  ОТПРАВКА РУДЫ КАРАВАНОМ
## ═══════════════════════════════════════════════════════

func try_play_caravan_arrival_if_pending() -> void:
	if not SaveManager.caravan_pending:
		return
	DialogueRegistry.try_start("caravan_arrival", false)


func get_current_order_info() -> Dictionary:
	if SaveManager.crown_order_index <= 0:
		return {}
	var order := BalanceConfig.get_crown_order(SaveManager.crown_order_index)
	if order.is_empty():
		return {}
	order["ore_sent"] = SaveManager.crown_order_ore_sent
	order["deadline_remaining"] = SaveManager.crown_order_deadline_remaining
	order["displeasure"] = SaveManager.crown_displeasure
	return order


func send_ore_with_caravan(ore_amount: int) -> bool:
	if ore_amount <= 0:
		return false
	if not SaveManager.caravan_pending:
		return false
	var actual := mini(ore_amount, SaveManager.ore_count)
	if actual <= 0:
		return false
	GameManager.add_ore(-actual)
	SaveManager.crown_order_ore_sent += actual
	SaveManager.ore_sent_to_crown_total += actual
	SaveManager.caravan_pending = false
	SaveManager.caravan_sent_count += 1
	_check_order_completion()
	_update_crown_title()
	_check_displeasure_recovery(actual)
	SaveManager.save_game()
	Events.caravan_pending_changed.emit(false)
	Events.caravan_dispatched.emit(actual, SaveManager.caravan_sent_count)
	return true


func dismiss_caravan_empty() -> void:
	SaveManager.caravan_pending = false
	SaveManager.save_game()
	Events.caravan_pending_changed.emit(false)


func _check_order_completion() -> void:
	var order := BalanceConfig.get_crown_order(SaveManager.crown_order_index)
	if order.is_empty():
		return
	var required := int(order.get("ore_required", 0))
	if SaveManager.crown_order_ore_sent >= required:
		SaveManager.crown_order_deadline_remaining = 0


func _check_displeasure_recovery(ore_sent_now: int) -> void:
	var order := BalanceConfig.get_crown_order(SaveManager.crown_order_index)
	if order.is_empty():
		return
	var required := int(order.get("ore_required", 0))
	if required <= 0:
		return
	var sent := SaveManager.crown_order_ore_sent
	if SaveManager.crown_displeasure > 0:
		if sent >= int(required * 1.2):
			SaveManager.crown_displeasure = maxi(0, SaveManager.crown_displeasure - 1)
			SaveManager.crown_orders_failed = maxi(0, SaveManager.crown_orders_failed - 1)
			Events.crown_displeasure_changed.emit(SaveManager.crown_displeasure)
	elif sent >= required:
		_try_increase_crown_favor()


func _try_increase_crown_favor() -> void:
	if SaveManager.crown_displeasure > 0:
		return
	if SaveManager.crown_favor >= BalanceConfig.CROWN_FAVOR_MAX_LEVEL:
		return
	SaveManager.crown_favor = clampi(SaveManager.crown_favor + 1, 0, BalanceConfig.CROWN_FAVOR_MAX_LEVEL)
	Events.crown_favor_changed.emit(SaveManager.crown_favor)


## ═══════════════════════════════════════════════════════
##  ТИТУЛЫ КОРОНЫ
## ═══════════════════════════════════════════════════════

func get_current_title() -> Dictionary:
	return BalanceConfig.get_crown_title_for_ore_sent(SaveManager.ore_sent_to_crown_total)


func get_current_title_name() -> String:
	return str(get_current_title().get("name", "Рекрут Авроры"))


func get_current_title_flavor() -> String:
	return BalanceConfig.pick_crown_title_flavor(get_current_title())


## Арт титула: `res://Asets/титулы/1.png` … `6.png` (номер = индекс в BalanceConfig.CROWN_TITLES + 1).
const CROWN_TITLE_ART_BASE := "res://Asets/титулы"


func get_crown_title_art_path_for_index(title_index: int) -> String:
	var n := BalanceConfig.CROWN_TITLES.size()
	var i := clampi(title_index, 0, maxi(0, n - 1))
	return "%s/%d.png" % [CROWN_TITLE_ART_BASE, i + 1]


func get_current_crown_title_art_path() -> String:
	var idx := BalanceConfig.get_crown_title_index_for_ore_sent(SaveManager.ore_sent_to_crown_total)
	return get_crown_title_art_path_for_index(idx)


func load_crown_title_texture_for_index(title_index: int) -> Texture2D:
	var path := get_crown_title_art_path_for_index(title_index)
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	return null


func load_current_crown_title_texture() -> Texture2D:
	var path := get_current_crown_title_art_path()
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	return null


func _update_crown_title() -> void:
	var new_idx := BalanceConfig.get_crown_title_index_for_ore_sent(SaveManager.ore_sent_to_crown_total)
	if new_idx > SaveManager.crown_title_index:
		SaveManager.crown_title_index = new_idx
		var title: Dictionary = BalanceConfig.CROWN_TITLES[new_idx]
		Events.crown_title_changed.emit(new_idx, str(title.get("name", "")))
		SaveManager.save_game()


## ═══════════════════════════════════════════════════════
##  НЕМИЛОСТЬ / ОДОБРЕНИЕ — модификаторы для других систем
## ═══════════════════════════════════════════════════════

func get_gold_reward_crown_mult() -> float:
	var title_bonus := 1.0 + BalanceConfig.get_crown_gold_bonus_ratio(SaveManager.ore_sent_to_crown_total)
	var displeasure_mult := BalanceConfig.get_displeasure_gold_mult(SaveManager.crown_displeasure)
	return title_bonus * displeasure_mult


func get_building_cost_crown_mult() -> float:
	var discount := 1.0 - BalanceConfig.get_crown_service_discount(SaveManager.ore_sent_to_crown_total)
	var penalty := BalanceConfig.get_displeasure_building_cost_mult(SaveManager.crown_displeasure)
	return maxf(0.5, discount * penalty)


func get_crown_favor() -> int:
	return clampi(SaveManager.crown_favor, 0, BalanceConfig.CROWN_FAVOR_MAX_LEVEL)


func get_heal_modifier() -> float:
	return BalanceConfig.get_supply_heal_mult(SaveManager.crown_displeasure, SaveManager.crown_favor)


func get_rest_modifier() -> float:
	return BalanceConfig.get_supply_rest_mult(SaveManager.crown_displeasure, SaveManager.crown_favor)


func get_service_cost_modifier() -> float:
	return BalanceConfig.get_supply_service_cost_mult(SaveManager.crown_displeasure, SaveManager.crown_favor)


func get_archer_damage_modifier() -> float:
	return BalanceConfig.get_supply_archer_damage_mult(SaveManager.crown_displeasure, SaveManager.crown_favor)


## ═══════════════════════════════════════════════════════
##  ИЗНОС СНАРЯЖЕНИЯ
## ═══════════════════════════════════════════════════════


func get_armor_durability() -> int:
	return clampi(SaveManager.armor_durability, 0, BalanceConfig.ARMOR_MAX_DURABILITY)


func degrade_armor() -> int:
	var wear := BalanceConfig.ARMOR_WEAR_PER_EXPEDITION
	SaveManager.armor_durability = maxi(0, SaveManager.armor_durability - wear)
	Events.armor_durability_changed.emit(SaveManager.armor_durability)
	SaveManager.save_game()
	return SaveManager.armor_durability


func get_armor_repair_cost() -> Dictionary:
	var d := SaveManager.crown_displeasure
	var f := SaveManager.crown_favor
	return {
		"gold": BalanceConfig.get_armor_repair_gold_cost(d, f),
		"ore": BalanceConfig.get_armor_repair_ore_cost(d, f),
	}


func try_repair_armor() -> bool:
	if SaveManager.armor_durability >= BalanceConfig.ARMOR_MAX_DURABILITY:
		return false
	var cost := get_armor_repair_cost()
	var gold_cost: int = int(cost.get("gold", 0))
	var ore_cost: int = int(cost.get("ore", 0))
	if not GameplayFacade.try_spend_gold_plus_ore(gold_cost, ore_cost):
		return false
	SaveManager.armor_durability = BalanceConfig.ARMOR_MAX_DURABILITY
	Events.armor_durability_changed.emit(SaveManager.armor_durability)
	SaveManager.save_game()
	return true


func get_armor_block_penalty() -> float:
	return BalanceConfig.get_armor_block_penalty(SaveManager.armor_durability)
