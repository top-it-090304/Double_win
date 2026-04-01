extends Node

## Список ресурсов DialogueDefinition. Добавьте сюда путь при создании нового диалога.
const DEFINITION_PATHS: PackedStringArray = [
	"res://dialogue/definitions/boss_post_1_def.tres",
	"res://dialogue/definitions/boss_post_2_def.tres",
	"res://dialogue/definitions/boss_post_3_def.tres",
	"res://dialogue/definitions/boss_post_4_def.tres",
	"res://dialogue/definitions/truth_and_choice_def.tres",
	"res://dialogue/definitions/monk_finale_refused_def.tres",
	"res://dialogue/definitions/boss_post_5_def.tres",
	"res://dialogue/definitions/gate_lv5_blocked_def.tres",
	"res://dialogue/definitions/intro_base_island_def.tres",
	"res://dialogue/definitions/dock_worker_youth_intro_def.tres",
	"res://dialogue/definitions/dock_worker_youth_recruit_def.tres",
	"res://dialogue/definitions/dock_worker_youth_ask_again_def.tres",
	"res://dialogue/definitions/monk_worker_youth_warning_def.tres",
	"res://dialogue/definitions/monk_worker_youth_lament_def.tres",
	"res://dialogue/definitions/monk_interact_hub_def.tres",
	"res://dialogue/definitions/lore_crown_purse_def.tres",
	"res://dialogue/definitions/lore_crown_contract_def.tres",
	"res://dialogue/definitions/lore_order_oath_def.tres",
	"res://dialogue/definitions/lore_chain_seal_def.tres",
	"res://dialogue/definitions/lore_deaths_liturgy_def.tres",
	"res://dialogue/definitions/lore_archer_sentinel_def.tres",
	"res://dialogue/definitions/lore_mine_chain_def.tres",
	"res://dialogue/definitions/lore_worker_island_def.tres",
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
	"res://dialogue/definitions/worker_youth_death_def.tres",
	"res://dialogue/definitions/worker_youth_alive_truth_def.tres",
	"res://dialogue/definitions/veteran_archer_intro_def.tres",
	"res://dialogue/definitions/veteran_archer_hub_def.tres",
	"res://dialogue/definitions/veteran_archer_banter_def.tres",
	"res://dialogue/definitions/veteran_story_1_def.tres",
	"res://dialogue/definitions/veteran_story_2_def.tres",
	"res://dialogue/definitions/veteran_story_3_def.tres",
	"res://dialogue/definitions/veteran_story_4_def.tres",
	"res://dialogue/definitions/veteran_truth_react_def.tres",
	"res://dialogue/definitions/veteran_youth_death_def.tres",
	"res://dialogue/definitions/worker_youth_camp_def.tres",
	"res://dialogue/definitions/worker_youth_letter_1_def.tres",
	"res://dialogue/definitions/worker_youth_letter_2_def.tres",
	"res://dialogue/definitions/lore_veteran_first_expedition_def.tres",
	"res://dialogue/definitions/lore_veteran_training_def.tres",
	"res://dialogue/definitions/youth_belongings_def.tres",
	"res://dialogue/definitions/monk_youth_death_reaction_def.tres",
	"res://dialogue/definitions/youth_postmortem_letter_1_def.tres",
	"res://dialogue/definitions/youth_postmortem_letter_2_def.tres",
	"res://dialogue/definitions/youth_letter_healer_prompt_def.tres",
	"res://dialogue/definitions/youth_letter_caravan_reminder_def.tres",
	"res://dialogue/definitions/youth_letter_sent_def.tres",
	"res://dialogue/definitions/caravan_arrival_def.tres",
]

var _by_id: Dictionary = {}
## Очередь: если `try_start` вызван во время активного диалога, следующий id ждёт конца текущего (кроме NO_QUEUE_WHEN_BUSY).
var _pending_dialogue_queue: Array[String] = []

## Хабы и бантер не ставим в очередь — иначе «атака» у NPC уйдёт в хвост сюжета.
const NO_QUEUE_WHEN_BUSY: PackedStringArray = [
	"monk_interact_hub",
	"heal_banter",
	"healer_idle_fallback",
	"veteran_archer_hub",
	"veteran_archer_banter",
]


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
	if DialogueManager.is_active():
		if dialogue_id in NO_QUEUE_WHEN_BUSY:
			return false
		if dialogue_id in _pending_dialogue_queue:
			return true
		_pending_dialogue_queue.append(dialogue_id)
		return true
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
	if sequence.id == "youth_letter_caravan_reminder":
		StoryState.clear_flag("youth_letter_reminder_pending")
	if sequence.id == "youth_letter_sent":
		StoryState.clear_flag("youth_letter_send_deferred")
		StoryState.clear_flag("youth_letter_reminder_pending")
	if sequence.id == "monk_story_6":
		MonkInteractiveDialogue.grant_ending_flag_after_finale()
	if sequence.id == "veteran_story_4":
		VeteranArcherStoryDialogue.grant_ending_flag_after_finale()
	PostFinaleWorld.dialogue_maybe_trigger_ending(sequence.id)
	if sequence.id in ["heal_banter", "healer_idle_fallback", "monk_interact_hub", "veteran_archer_banter", "veteran_archer_hub", "rest_quota_exhausted"]:
		sequence.lines.clear()
	call_deferred("_flush_pending_dialogue_queue")


func _flush_pending_dialogue_queue() -> void:
	if DialogueManager.is_active():
		return
	while not _pending_dialogue_queue.is_empty():
		var next_id: String = _pending_dialogue_queue.pop_front()
		if not can_play(next_id):
			continue
		var next_def := get_definition(next_id) as DialogueDefinition
		if next_def == null or next_def.sequence == null:
			continue
		DialogueManager.start_dialogue(next_def.sequence, false)
		return
