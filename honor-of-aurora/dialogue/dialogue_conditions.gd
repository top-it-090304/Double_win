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
	if use_location_filter and Events.current_location != location:
		return false
	return true
