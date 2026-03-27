extends Node

enum LOCATION {BASE, LVL1, LVL2, LVL3, LVL4, LVL5, MENU}

## Последняя известная локация (для условий диалогов). Обновляется при смене сцены.
var current_location: LOCATION = LOCATION.BASE

## Устанавливается при телепорте на базу с острова; забирает монах (см. GameManager / monk_base).
var pending_healer_dialogue_after_expedition: bool = false

## Игрок ушёл в главное меню с острова (LVL*), не через базу — при «Продолжить» на базу нужен жетон диалога.
var was_on_adventure_before_menu: bool = false

signal location_changed(location: LOCATION)
signal gold_changed(value: int)
signal meat_changed(value: int)
signal wood_changed(value: int)
## Запас руды с базовой шахты (пока только счётчик для будущей механики).
signal ore_changed(value: int)
signal premium_ore_pack_purchased(pack_id: String, ore_added: int)
## Закрыто окно приказов отряду (после беседы / «Далее»): нужно сбросить «attack», иначе ЛКМ снова откроет меню.
signal squad_orders_menu_closed()
## Герой вернулся с острова на базу (счётчик SaveManager.expedition_return_count уже увеличен).
signal expedition_returned(new_count: int)
## Мясо на базе подобрано (игрок или рабочий) — сброс целей у pawn.
signal base_island_meat_collected()


func is_adventure_location(loc: LOCATION) -> bool:
	match loc:
		LOCATION.LVL1, LOCATION.LVL2, LOCATION.LVL3, LOCATION.LVL4, LOCATION.LVL5:
			return true
		_:
			return false


func sync_story_state_from_save() -> void:
	was_on_adventure_before_menu = SaveManager.was_on_adventure_before_menu
