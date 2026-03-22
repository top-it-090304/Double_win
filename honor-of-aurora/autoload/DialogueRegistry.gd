extends Node

## Список ресурсов DialogueDefinition. Добавьте сюда путь при создании нового диалога.
const DEFINITION_PATHS: PackedStringArray = [
	"res://dialogue/definitions/boss_post_1_def.tres",
	"res://dialogue/definitions/boss_post_2_def.tres",
	"res://dialogue/definitions/boss_post_3_def.tres",
	"res://dialogue/definitions/boss_post_4_def.tres",
	"res://dialogue/definitions/boss_post_5_def.tres",
	"res://dialogue/definitions/intro_base_island_def.tres",
	"res://dialogue/definitions/lore_crown_purse_def.tres",
	"res://dialogue/definitions/lore_crown_contract_def.tres",
	"res://dialogue/definitions/lore_order_oath_def.tres",
	"res://dialogue/definitions/lore_chain_seal_def.tres",
	"res://dialogue/definitions/lore_deaths_liturgy_def.tres",
	"res://dialogue/definitions/lore_archer_sentinel_def.tres",
	"res://dialogue/definitions/lore_gold_blood_def.tres",
	"res://dialogue/definitions/lore_return_veteran_def.tres",
	"res://dialogue/definitions/monk_story_1_def.tres",
	"res://dialogue/definitions/monk_story_2_def.tres",
	"res://dialogue/definitions/monk_story_3_def.tres",
	"res://dialogue/definitions/monk_story_4_def.tres",
	"res://dialogue/definitions/monk_letter_1_def.tres",
	"res://dialogue/definitions/monk_story_5_def.tres",
	"res://dialogue/definitions/monk_letter_2_def.tres",
	"res://dialogue/definitions/monk_story_6_def.tres",
	"res://dialogue/definitions/heal_banter_def.tres",
	"res://dialogue/definitions/healer_idle_fallback_def.tres",
]

var _by_id: Dictionary = {}


func _ready() -> void:
	_load_definitions()
	DialogueManager.dialogue_ended.connect(_on_dialogue_ended)


func _load_definitions() -> void:
	_by_id.clear()
	for path in DEFINITION_PATHS:
		if not ResourceLoader.exists(path):
			push_warning("DialogueRegistry: файл не найден: %s" % path)
			continue
		var def := load(path) as DialogueDefinition
		if def == null or def.id.is_empty():
			push_warning("DialogueRegistry: пропуск неверного определения: %s" % path)
			continue
		if _by_id.has(def.id):
			push_warning("DialogueRegistry: дубликат id \"%s\"" % def.id)
		_by_id[def.id] = def


func get_definition(dialogue_id: String) -> DialogueDefinition:
	return _by_id.get(dialogue_id) as DialogueDefinition


func can_play(dialogue_id: String) -> bool:
	var def := get_definition(dialogue_id)
	if def == null or def.sequence == null:
		return false
	def.sequence.ensure_lines_ready()
	if def.sequence.lines.is_empty():
		return false
	if def.conditions != null and not def.conditions.is_satisfied():
		return false
	return true


func try_start(dialogue_id: String, pause_game: bool = false) -> bool:
	if not can_play(dialogue_id):
		return false
	var def := get_definition(dialogue_id) as DialogueDefinition
	return DialogueManager.start_dialogue(def.sequence, pause_game)


func _on_dialogue_ended(sequence: DialogueSequence) -> void:
	if sequence == null or sequence.id.is_empty():
		return
	var def := get_definition(sequence.id)
	if def == null:
		return
	for flag in def.grant_flags_on_complete:
		StoryState.set_flag(flag, true)
	if sequence.id == "monk_story_6":
		MonkInteractiveDialogue.grant_ending_flag_after_finale()
	# Случайный бантер должен собираться заново при следующем заходе в зону.
	if sequence.id == "heal_banter" or sequence.id == "healer_idle_fallback":
		sequence.lines.clear()
