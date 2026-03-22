class_name DialogueChoiceOption
extends Resource

@export var label: String = ""
## Флаги StoryState при выборе (строковые ключи).
@export var grant_flags: PackedStringArray = []
## Реплики после выбора (герой, целитель, письмо…).
@export var continuation: Array[DialogueLine] = []
