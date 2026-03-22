extends Node

enum LOCATION {BASE, LVL1, LVL2, LVL3, LVL4, LVL5, MENU}

## Последняя известная локация (для условий диалогов). Обновляется при смене сцены.
var current_location: LOCATION = LOCATION.BASE

## Устанавливается при телепорте на базу с острова; забирает монах (см. GameManager / monk_base).
var pending_healer_dialogue_after_expedition: bool = false

## Игрок ушёл в главное меню с острова (LVL*), не через базу — при «Продолжить» на базу нужен жетон диалога.
var was_on_adventure_before_menu: bool = false

signal location_changed(location: LOCATION)
signal gold_changed(gold: int)


func is_adventure_location(loc: LOCATION) -> bool:
	match loc:
		LOCATION.LVL1, LOCATION.LVL2, LOCATION.LVL3, LOCATION.LVL4, LOCATION.LVL5:
			return true
		_:
			return false


func sync_story_state_from_save() -> void:
	was_on_adventure_before_menu = SaveManager.was_on_adventure_before_menu
