class_name DialogueConditions
extends Resource

## Все перечисленные флаги должны быть выставлены в StoryState (логическое И).
@export var required_flags: Array[String] = []
## Если любой из этих флагов выставлен, диалог не показывается.
@export var blocked_flags: Array[String] = []
## Не показывать, пока boss_kill меньше этого значения (-1 = не проверять).
@export var min_boss_kill: int = -1
## Не показывать, пока boss_kill больше этого значения (-1 = не проверять).
@export var max_boss_kill: int = -1
## Золото (SaveManager.gold). -1 = не проверять.
@export var min_gold: int = -1
@export var max_gold: int = -1
## Уровень героя (SaveManager.current_level).
@export var min_level: int = -1
@export var max_level: int = -1
## Смерти героя (SaveManager.death_count).
@export var min_death_count: int = -1
@export var max_death_count: int = -1
## Лучники на базе (SaveManager.archer_count).
@export var min_archer_count: int = -1
@export var max_archer_count: int = -1
## Сколько раз герой вернулся на базу с острова (SaveManager.expedition_return_count).
@export var min_expedition_return_count: int = -1
@export var max_expedition_return_count: int = -1
@export var use_location_filter: bool = false
@export var location: Events.LOCATION = Events.LOCATION.BASE


func is_satisfied() -> bool:
	for f in required_flags:
		if not StoryState.has_flag(f):
			return false
	for f in blocked_flags:
		if StoryState.has_flag(f):
			return false
	if min_boss_kill >= 0 and SaveManager.boss_kill < min_boss_kill:
		return false
	if max_boss_kill >= 0 and SaveManager.boss_kill > max_boss_kill:
		return false
	if min_gold >= 0 and SaveManager.gold < min_gold:
		return false
	if max_gold >= 0 and SaveManager.gold > max_gold:
		return false
	if min_level >= 0 and SaveManager.current_level < min_level:
		return false
	if max_level >= 0 and SaveManager.current_level > max_level:
		return false
	if min_death_count >= 0 and SaveManager.death_count < min_death_count:
		return false
	if max_death_count >= 0 and SaveManager.death_count > max_death_count:
		return false
	if min_archer_count >= 0 and SaveManager.archer_count < min_archer_count:
		return false
	if max_archer_count >= 0 and SaveManager.archer_count > max_archer_count:
		return false
	if min_expedition_return_count >= 0 and SaveManager.expedition_return_count < min_expedition_return_count:
		return false
	if max_expedition_return_count >= 0 and SaveManager.expedition_return_count > max_expedition_return_count:
		return false
	if use_location_filter and Events.current_location != location:
		return false
	return true
