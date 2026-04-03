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
	var ore := BalanceConfig.get_mine_ore_per_return(get_mine_tier(), pawns_on_base)
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
	_cancel_rest_regen_if_active()
	SaveManager.rest_used_this_expedition = 0
	SaveManager.expedition_ore_collected = 0
	SaveManager.expedition_wood_collected = 0
	SaveManager.expedition_meat_collected = 0


## ═══════════════════════════════════════════════════════
##  ПРИВАЛ — хил отряда за мясо на острове (стоимость = герой + лучники + копейщики)
## ═══════════════════════════════════════════════════════

var _rest_regen_active: bool = false
var _rest_regen_rows: Array[Dictionary] = []
var _rest_regen_elapsed: float = 0.0
var _rest_heal_vfx_accum: float = 0.0

const _REST_HEAL_VFX_INTERVAL_SEC := 0.85
const _REST_QUOTA_EXHAUSTED_SEQ := preload("res://dialogue/rest_quota_exhausted.tres")


func _ready() -> void:
	set_process(false)
	if not DialogueManager.dialogue_ended.is_connected(_on_dialogue_ended_maybe_patent_queue):
		DialogueManager.dialogue_ended.connect(_on_dialogue_ended_maybe_patent_queue)


## Очередь грамот при повышении титула (за одну отгрузку можно перескочить несколько порогов).
var _patent_dialogue_tier_queue: Array[int] = []


func _enqueue_crown_title_patents(from_exclusive: int, to_inclusive: int) -> void:
	for i in range(from_exclusive + 1, to_inclusive + 1):
		if i >= 1:
			_patent_dialogue_tier_queue.append(i)


func _try_start_next_crown_patent_dialogue() -> void:
	if _patent_dialogue_tier_queue.is_empty():
		return
	if DialogueManager.is_active():
		return
	var tier := int(_patent_dialogue_tier_queue.pop_front())
	if not CrownPatentReadingLayer.try_show_for_title_index(tier, Callable(self, "_on_crown_patent_reading_closed")):
		_patent_dialogue_tier_queue.push_front(tier)


func _on_crown_patent_reading_closed() -> void:
	call_deferred("_try_start_next_crown_patent_dialogue")


func _on_dialogue_ended_maybe_patent_queue(_sequence: DialogueSequence) -> void:
	call_deferred("_try_start_next_crown_patent_dialogue")


func is_rest_regen_active() -> bool:
	return _rest_regen_active


func _cancel_rest_regen_if_active() -> void:
	if not _rest_regen_active:
		return
	_rest_regen_rows.clear()
	_rest_regen_active = false
	_rest_regen_elapsed = 0.0
	_rest_heal_vfx_accum = 0.0
	set_process(false)


func get_squad_rest_meat_cost() -> int:
	return maxi(1, 1 + SaveManager.archer_count + SaveManager.lancer_count)


func can_rest() -> bool:
	if _rest_regen_active:
		return false
	## В зоне врага (обнаружение / атака / преследование) — привал недоступен (см. SquadCombatState).
	if SquadCombatState.is_engaged():
		return false
	if SaveManager.rest_used_this_expedition >= BalanceConfig.get_rest_max_per_expedition():
		return false
	if SaveManager.meat_count < get_squad_rest_meat_cost():
		return false
	return true


func get_rests_remaining() -> int:
	return maxi(0, BalanceConfig.get_rest_max_per_expedition() - SaveManager.rest_used_this_expedition)


## Лимит привалов на этот поход уже выбран (не путать с нехваткой мяса или полным HP).
func is_rest_blocked_by_quota() -> bool:
	if _rest_regen_active:
		return false
	return SaveManager.rest_used_this_expedition >= BalanceConfig.get_rest_max_per_expedition()


## Кнопка привала на острове: при исчерпанном лимите — нажатие открывает реплику; в бою кнопка неактивна.
func should_rest_button_be_interactive() -> bool:
	if SquadCombatState.is_engaged():
		return false
	return can_rest() or is_rest_blocked_by_quota()


## Окно с репликой рыцаря, если игрок жмёт привал при исчерпанном лимите.
func try_start_rest_quota_exhausted_dialogue() -> bool:
	if SquadCombatState.is_engaged():
		return false
	if not is_rest_blocked_by_quota():
		return false
	if DialogueManager.is_active():
		return false
	var seq: DialogueSequence = _REST_QUOTA_EXHAUSTED_SEQ as DialogueSequence
	if seq == null:
		return false
	seq.ensure_lines_ready()
	return DialogueManager.start_dialogue(seq, false)


## Один привал: к текущему HP добавляется не больше (REST_HEAL_RATIO×max HP × модификатор Короны).
## Если недостаёт меньше — всё равно доводим до max_hp (лишний «объём» привала не тратится в пустоту).
func _build_rest_regen_row(unit: Node) -> Dictionary:
	var hc := unit.get_node_or_null("HealthComponent")
	if hc == null:
		return {}
	var start_hp := int(hc.current_health)
	var max_hp := int(hc.max_health)
	var base_chunk := BalanceConfig.get_rest_heal_amount(max_hp)
	var heal_cap := maxi(1, int(round(float(base_chunk) * get_rest_modifier())))
	var target_hp := mini(max_hp, start_hp + heal_cap)
	return {
		"node": unit,
		"start_hp": start_hp,
		"max_hp": max_hp,
		"target_hp": target_hp,
	}


## Снимает мясо и плавно доводит HP до target (не выше max_hp).
func try_squad_rest() -> bool:
	if not can_rest():
		return false
	var targets := GameplayFacade.collect_squad_rest_heal_targets()
	if targets.is_empty():
		return false
	_rest_regen_rows.clear()
	for t in targets:
		var row := _build_rest_regen_row(t)
		if not row.is_empty():
			_rest_regen_rows.append(row)
	if _rest_regen_rows.is_empty():
		return false
	var someone_wounded := false
	for row in _rest_regen_rows:
		if int(row["start_hp"]) < int(row["max_hp"]):
			someone_wounded = true
			break
	if not someone_wounded:
		return false
	var cost := get_squad_rest_meat_cost()
	GameManager.add_meat(-cost)
	SaveManager.rest_used_this_expedition += 1
	_rest_regen_elapsed = 0.0
	_rest_heal_vfx_accum = 0.0
	_rest_regen_active = true
	set_process(true)
	SoundManager.play_ui_button()
	_pulse_rest_heal_visuals()
	SoundManager.play_heal()
	return true


func _pulse_rest_heal_visuals() -> void:
	for row in _rest_regen_rows:
		var node: Node = row["node"]
		if not is_instance_valid(node):
			continue
		if node.has_method("play_heal_effect"):
			node.call("play_heal_effect")


func _process(_delta: float) -> void:
	if not _rest_regen_active:
		return
	_rest_regen_elapsed += _delta
	_rest_heal_vfx_accum += _delta
	while _rest_heal_vfx_accum >= _REST_HEAL_VFX_INTERVAL_SEC:
		_rest_heal_vfx_accum -= _REST_HEAL_VFX_INTERVAL_SEC
		_pulse_rest_heal_visuals()
	var mod := get_rest_modifier()
	var dur := BalanceConfig.REST_REGEN_DURATION_SEC / maxf(0.1, mod)
	var t := _rest_regen_elapsed / dur
	if t >= 1.0:
		_finish_rest_regen()
		return
	t = minf(1.0, t)
	for row in _rest_regen_rows:
		var node: Node = row["node"]
		if not is_instance_valid(node):
			continue
		var hc := node.get_node_or_null("HealthComponent")
		if hc == null:
			continue
		var start_hp: int = int(row["start_hp"])
		var target_hp: int = int(row["target_hp"])
		var max_hp: int = int(row["max_hp"])
		var new_hp := int(round(lerpf(float(start_hp), float(target_hp), t)))
		hc.set_current_health(clampi(new_hp, 0, max_hp))


func _finish_rest_regen() -> void:
	var total_heal := 0
	for row in _rest_regen_rows:
		var node: Node = row["node"]
		if not is_instance_valid(node):
			continue
		var hc := node.get_node_or_null("HealthComponent")
		if hc == null:
			continue
		var start_hp: int = int(row["start_hp"])
		var target_hp: int = int(row["target_hp"])
		var max_hp: int = int(row["max_hp"])
		hc.set_current_health(clampi(target_hp, 0, max_hp))
		total_heal += maxi(0, hc.current_health - start_hp)
	_rest_regen_rows.clear()
	_rest_regen_active = false
	set_process(false)
	Events.rest_used.emit(total_heal, get_rests_remaining())


## ═══════════════════════════════════════════════════════
##  РЕСУРСНЫЕ CAP-Ы ЗА ПОХОД
## ═══════════════════════════════════════════════════════

func can_collect_expedition_ore() -> bool:
	return SaveManager.expedition_ore_collected < BalanceConfig.get_max_ore_per_expedition()


func can_collect_expedition_wood() -> bool:
	return SaveManager.expedition_wood_collected < BalanceConfig.get_max_wood_per_expedition()


func can_collect_expedition_meat() -> bool:
	return SaveManager.expedition_meat_collected < BalanceConfig.get_max_meat_per_expedition()


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
	## Один счётчик `crown_returns_remaining`: и срок приказа, и моменты прибытия каравана (кратно CARAVAN_EXPEDITION_INTERVAL, включая 0).
	## Пока срок истёк, но караван конца срока ещё не отправлен — счётчик не трогаем (ждём отгрузки).
	if SaveManager.crown_deadline_expired_awaiting_dispatch and SaveManager.crown_order_index > 0:
		SaveManager.save_game()
		return

	var interval := BalanceConfig.CARAVAN_EXPEDITION_INTERVAL
	var rem_before := SaveManager.crown_returns_remaining
	if SaveManager.crown_returns_remaining > 0:
		SaveManager.crown_returns_remaining -= 1
	var rem := SaveManager.crown_returns_remaining
	var just_hit_zero := rem_before > 0 and rem == 0

	if SaveManager.crown_order_index <= 0:
		if rem == 0:
			_try_arrive_caravan()
		SaveManager.save_game()
		return

	if rem % interval == 0:
		## Не вызывать повторное «прибытие» на каждом возврате, пока rem=0 и срок уже закрыт ожиданием отгрузки.
		var skip_repeat_arrival_at_zero := rem == 0 and not just_hit_zero and SaveManager.crown_order_index > 0
		if not skip_repeat_arrival_at_zero:
			_try_arrive_caravan()
	if just_hit_zero:
		SaveManager.crown_deadline_expired_awaiting_dispatch = true
	SaveManager.save_game()


## Сколько «дней» (тиков счётчика после возвращения на базу) до следующего прибытия каравана (для UI). До первого приказа — то же, что до первого рейса.
func get_returns_until_next_caravan() -> int:
	var interval := BalanceConfig.CARAVAN_EXPEDITION_INTERVAL
	var rem := maxi(0, SaveManager.crown_returns_remaining)
	if rem <= 0:
		return 0
	if SaveManager.crown_order_index <= 0:
		return rem
	var m := rem % interval
	if m == 0:
		return interval
	return m


func _try_arrive_caravan() -> void:
	if SaveManager.caravan_pending:
		SaveManager.caravan_arrival_queued += 1
		return
	_arrive_caravan()


func _process_caravan_arrival_queue() -> void:
	if SaveManager.caravan_pending:
		return
	if SaveManager.caravan_arrival_queued <= 0:
		return
	SaveManager.caravan_arrival_queued -= 1
	_arrive_caravan()
	SaveManager.save_game()


func _arrive_caravan() -> void:
	SaveManager.caravan_pending = true
	_advance_crown_order_if_needed()
	_deliver_caravan_supplies()
	var order_idx := SaveManager.crown_order_index
	Events.caravan_arrived.emit(order_idx)
	Events.caravan_pending_changed.emit(true)
	Events.arm_miron_mail_chase_defer_if_eligible()


func _deliver_caravan_supplies() -> void:
	var gold := BalanceConfig.get_caravan_supply_gold()
	var meat := BalanceConfig.get_caravan_supply_meat()
	gold = int(round(float(gold) * get_gold_reward_crown_mult()))
	if gold > 0:
		GameManager.add_gold(gold)
	if meat > 0:
		GameManager.add_meat(meat)


func _advance_crown_order_if_needed() -> void:
	## Следующий приказ после истечения срока выдаётся в `_resolve_crown_order_on_caravan_dispatch` (после отъезда рейса конца срока).
	## Здесь — только выдача самого первого приказа после старта.
	if SaveManager.crown_order_index <= 0:
		_issue_next_crown_order()
		return


func _issue_next_crown_order() -> void:
	var next_idx := SaveManager.crown_order_index + 1
	var order := BalanceConfig.get_crown_order(next_idx)
	if order.is_empty():
		return
	SaveManager.crown_order_index = next_idx
	SaveManager.crown_order_ore_sent = 0
	SaveManager.crown_returns_remaining = int(order.get("deadline_expeditions", BalanceConfig.DEFAULT_CROWN_ORDER_DEADLINE_EXPEDITIONS))
	SaveManager.save_game()


## Вызывается только из `_resolve_crown_order_on_caravan_dispatch` и при миграции/редком рассинхроне.
func _on_crown_order_deadline_expired() -> void:
	_resolve_crown_order_expiry_logic()


func _resolve_crown_order_expiry_logic() -> void:
	var order := BalanceConfig.get_crown_order(SaveManager.crown_order_index)
	if order.is_empty():
		return
	var required := int(order.get("ore_required", 0))
	var sent := SaveManager.crown_order_ore_sent
	var dl_default := int(order.get("deadline_expeditions", BalanceConfig.DEFAULT_CROWN_ORDER_DEADLINE_EXPEDITIONS))
	if sent >= required:
		_issue_next_crown_order()
		return
	if sent < int(required * 0.5):
		_apply_order_failure()
	SaveManager.crown_returns_remaining = dl_default
	SaveManager.save_game()


func _resolve_crown_order_on_caravan_dispatch() -> void:
	if not SaveManager.crown_deadline_expired_awaiting_dispatch:
		return
	SaveManager.crown_deadline_expired_awaiting_dispatch = false
	_resolve_crown_order_expiry_logic()


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
	## Письма Мирона привязаны к прибытию каравана — до старта диалога интенданта.
	var tree := get_tree()
	if tree:
		tree.call_group("miron_mail_carrier", "on_caravan_arrived_for_mail")
	DialogueRegistry.try_start("caravan_arrival", false)


func get_current_order_info() -> Dictionary:
	if SaveManager.crown_order_index <= 0:
		return {}
	var order := BalanceConfig.get_crown_order(SaveManager.crown_order_index)
	if order.is_empty():
		return {}
	order["ore_sent"] = SaveManager.crown_order_ore_sent
	order["deadline_remaining"] = SaveManager.crown_returns_remaining
	order["deadline_expired_awaiting_dispatch"] = SaveManager.crown_deadline_expired_awaiting_dispatch
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
	var skip_order_favor := _update_crown_title()
	_check_displeasure_recovery(actual, skip_order_favor)
	Events.caravan_pending_changed.emit(false)
	Events.caravan_dispatched.emit(actual, SaveManager.caravan_sent_count)
	Events.on_caravan_no_longer_pending()
	_resolve_crown_order_on_caravan_dispatch()
	_process_caravan_arrival_queue()
	SaveManager.save_game()
	return true


func dismiss_caravan_empty() -> void:
	SaveManager.caravan_pending = false
	Events.caravan_pending_changed.emit(false)
	Events.on_caravan_no_longer_pending()
	_resolve_crown_order_on_caravan_dispatch()
	_process_caravan_arrival_queue()
	SaveManager.save_game()


func _check_displeasure_recovery(ore_sent_now: int, skip_favor_from_order: bool = false) -> void:
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
	elif sent >= required and not skip_favor_from_order:
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

var _crown_title_texture_cache: Dictionary = {}


func get_crown_title_art_path_for_index(title_index: int) -> String:
	var n := BalanceConfig.CROWN_TITLES.size()
	var i := clampi(title_index, 0, maxi(0, n - 1))
	return "%s/%d.png" % [CROWN_TITLE_ART_BASE, i + 1]


func get_current_crown_title_art_path() -> String:
	var idx := BalanceConfig.get_crown_title_index_for_ore_sent(SaveManager.ore_sent_to_crown_total)
	return get_crown_title_art_path_for_index(idx)


func load_crown_title_texture_for_index(title_index: int) -> Texture2D:
	return _load_crown_title_texture_at_path(get_crown_title_art_path_for_index(title_index))


func load_current_crown_title_texture() -> Texture2D:
	return _load_crown_title_texture_at_path(get_current_crown_title_art_path())


func _load_crown_title_texture_at_path(path: String) -> Texture2D:
	if path.is_empty():
		return null
	if _crown_title_texture_cache.has(path):
		return _crown_title_texture_cache[path] as Texture2D
	if not ResourceLoader.exists(path):
		return null
	var tex: Texture2D = load(path) as Texture2D
	if tex:
		_crown_title_texture_cache[path] = tex
	return tex


## Ступень одобрения за новый титул; false — снята немилость или уже макс. одобрения.
func _apply_crown_mood_on_title_promotion() -> bool:
	## Новый титул: снять немилость целиком или, если её не было, дать ступень одобрения.
	if SaveManager.crown_displeasure > 0:
		var cleared: int = SaveManager.crown_displeasure
		SaveManager.crown_displeasure = 0
		SaveManager.crown_orders_failed = maxi(0, SaveManager.crown_orders_failed - cleared)
		Events.crown_displeasure_changed.emit(0)
		return false
	if SaveManager.crown_favor >= BalanceConfig.CROWN_FAVOR_MAX_LEVEL:
		return false
	SaveManager.crown_favor = clampi(SaveManager.crown_favor + 1, 0, BalanceConfig.CROWN_FAVOR_MAX_LEVEL)
	Events.crown_favor_changed.emit(SaveManager.crown_favor)
	return true


## true — в этом кадре за титул уже выдали одобрение (чтобы не дублировать с приказом в той же отгрузке).
func _update_crown_title() -> bool:
	var new_idx := BalanceConfig.get_crown_title_index_for_ore_sent(SaveManager.ore_sent_to_crown_total)
	if new_idx > SaveManager.crown_title_index:
		var prev_idx := SaveManager.crown_title_index
		SaveManager.crown_title_index = new_idx
		var favor_from_title := _apply_crown_mood_on_title_promotion()
		var title: Dictionary = BalanceConfig.CROWN_TITLES[new_idx]
		Events.crown_title_changed.emit(new_idx, str(title.get("name", "")))
		_enqueue_crown_title_patents(prev_idx, new_idx)
		call_deferred("_try_start_next_crown_patent_dialogue")
		SaveManager.save_game()
		return favor_from_title
	return false


## ═══════════════════════════════════════════════════════
##  НЕМИЛОСТЬ / ОДОБРЕНИЕ — модификаторы для других систем
## ═══════════════════════════════════════════════════════

func get_gold_reward_crown_mult() -> float:
	var title_bonus := 1.0 + BalanceConfig.get_crown_gold_bonus_ratio(SaveManager.ore_sent_to_crown_total)
	var mood := BalanceConfig.get_crown_caravan_gold_mult(SaveManager.crown_displeasure, SaveManager.crown_favor)
	return title_bonus * mood


func get_building_cost_crown_mult() -> float:
	var discount := 1.0 - BalanceConfig.get_crown_service_discount(SaveManager.ore_sent_to_crown_total)
	var mood := BalanceConfig.get_crown_building_cost_mult(SaveManager.crown_displeasure, SaveManager.crown_favor)
	return maxf(0.48, discount * mood)


func get_crown_favor() -> int:
	return clampi(SaveManager.crown_favor, 0, BalanceConfig.CROWN_FAVOR_MAX_LEVEL)


func get_heal_modifier() -> float:
	return BalanceConfig.get_supply_heal_mult(SaveManager.crown_displeasure, SaveManager.crown_favor) * DifficultyConfig.get_supply_effect_mult()


func get_rest_modifier() -> float:
	return BalanceConfig.get_supply_rest_mult(SaveManager.crown_displeasure, SaveManager.crown_favor) * DifficultyConfig.get_supply_effect_mult()


func get_service_cost_modifier() -> float:
	return BalanceConfig.get_supply_service_cost_mult(SaveManager.crown_displeasure, SaveManager.crown_favor) * DifficultyConfig.get_service_cost_mult()


func get_archer_damage_modifier() -> float:
	return BalanceConfig.get_supply_archer_damage_mult(SaveManager.crown_displeasure, SaveManager.crown_favor) * DifficultyConfig.get_archer_damage_mult()


## ═══════════════════════════════════════════════════════
##  ИЗНОС СНАРЯЖЕНИЯ
## ═══════════════════════════════════════════════════════


func get_armor_durability() -> int:
	return clampi(SaveManager.armor_durability, 0, BalanceConfig.ARMOR_MAX_DURABILITY)


## Износ брони/щита при ударе по герою (блок или нет — удар по щиту/доспеху).
func apply_armor_wear_on_hit_taken(wear: int = BalanceConfig.ARMOR_WEAR_PER_HIT_TAKEN) -> void:
	var w := int(round(float(wear) * DifficultyConfig.get_armor_wear_mult()))
	if w <= 0:
		return
	if SaveManager.armor_durability <= 0:
		return
	var new_d: int = maxi(0, SaveManager.armor_durability - w)
	if new_d == SaveManager.armor_durability:
		return
	SaveManager.armor_durability = new_d
	Events.armor_durability_changed.emit(SaveManager.armor_durability)
	SaveManager.request_save_game_deferred()


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
