class_name DialogueDefinition
extends Resource

## Уникальный id; должен совпадать с DialogueSequence.id для выдачи флагов после конца.
@export var id: String = ""
@export var sequence: DialogueSequence
@export var conditions: DialogueConditions
## Флаги StoryState, которые выставляются после нормального завершения диалога.
@export var grant_flags_on_complete: Array[String] = []
