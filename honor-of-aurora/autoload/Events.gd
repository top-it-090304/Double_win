extends Node

enum LOCATION {BASE, LVL1, LVL2, LVL3, LVL4, LVL5, MENU}

## Последняя известная локация (для условий диалогов). Обновляется при смене сцены.
var current_location: LOCATION = LOCATION.BASE

## Устанавливается при телепорте на базу с острова; забирает монах (см. GameManager / monk_base).
var pending_healer_dialogue_after_expedition: bool = false

## Прибыл караван и есть посмертная почта Мирона — ждём конца диалога `caravan_arrival`, затем монах идёт к герою.
var monk_miron_mail_chase_defer: bool = false
## Монах движется к герою, пока тот не войдёт в зону хила (там стартует постмортем-письмо).
var monk_miron_mail_chase_pending: bool = false

## Игрок ушёл в главное меню с острова (LVL*), не через базу — при «Продолжить» на базу нужен жетон диалога.
var was_on_adventure_before_menu: bool = false

signal location_changed(location: LOCATION)
## Счётчик использований телепорта (меню причала); см. RainSystem.
signal teleport_usage_count_changed(new_count: int)
signal gold_changed(value: int)
signal meat_changed(value: int)
signal wood_changed(value: int)
signal ore_changed(value: int)
signal premium_ore_pack_purchased(pack_id: String, ore_added: int)
## Караван Короны прибыл на базу и ожидает загрузки.
signal caravan_arrived(order_index: int)
## `caravan_pending` в сохранении сменился — визуал второго борта у причала и т.п.
signal caravan_pending_changed(pending: bool)
## Караван отправлен с рудой.
signal caravan_dispatched(ore_sent: int, caravan_count: int)
## Титул Короны повышен.
signal crown_title_changed(new_title_index: int, title_name: String)
## Немилость Короны изменилась.
signal crown_displeasure_changed(level: int)
## Одобрение Короны изменилось.
signal crown_favor_changed(level: int)
## Износ снаряжения изменился.
signal armor_durability_changed(durability: int)
## Шахта выдала руду при возврате с похода.
signal mine_harvested(ore_amount: int)
## Привал на острове: герой исцелён мясом.
signal rest_used(heal_amount: int, rests_remaining: int)
## Закрыто окно приказов отряду (после беседы / «Далее»): нужно сбросить «attack», иначе ЛКМ снова откроет меню.
signal squad_orders_menu_closed()
## Герой вернулся с острова на базу (счётчик SaveManager.expedition_return_count уже увеличен).
signal expedition_returned(new_count: int)
## Мясо на базе подобрано (игрок или рабочий) — сброс целей у pawn.
signal base_island_meat_collected()
## Сундук открыт: id, словарь лута (gold, wood, meat, ore, lore_note_id).
signal chest_opened(chest_id: String, loot: Dictionary)


func is_adventure_location(loc: LOCATION) -> bool:
	match loc:
		LOCATION.LVL1, LOCATION.LVL2, LOCATION.LVL3, LOCATION.LVL4, LOCATION.LVL5:
			return true
		_:
			return false


func sync_story_state_from_save() -> void:
	was_on_adventure_before_menu = SaveManager.was_on_adventure_before_menu


## Вызывается из CrownSystem при фактическом прибытии каравана (не из UI замка).
func arm_miron_mail_chase_defer_if_eligible() -> void:
	if not StoryState.has_flag("worker_youth_dead"):
		return
	if not DialogueRegistry.can_play("youth_postmortem_letter_1") and not DialogueRegistry.can_play(
		"youth_postmortem_letter_2"
	):
		return
	monk_miron_mail_chase_defer = true


func clear_miron_mail_chase_state() -> void:
	monk_miron_mail_chase_defer = false
	monk_miron_mail_chase_pending = false


## Караван ушёл с причала (руда или порожняком): если диалог прибытия не отыгрался, всё равно включить погоню с письмом.
func on_caravan_no_longer_pending() -> void:
	if not monk_miron_mail_chase_defer:
		return
	monk_miron_mail_chase_defer = false
	if not StoryState.has_flag("worker_youth_dead"):
		return
	if not DialogueRegistry.can_play("youth_postmortem_letter_1") and not DialogueRegistry.can_play(
		"youth_postmortem_letter_2"
	):
		return
	monk_miron_mail_chase_pending = true
