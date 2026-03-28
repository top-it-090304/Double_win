extends CharacterBody2D

## NPC ветеран-лучник Бран у стрельбища. Стоит на месте, играет idle,
## запускает диалоги при подходе игрока (авто) и по атаке (хаб).
##
## ВАЖНО: на инстансе в `Game_base_islad.tscn` нельзя ставить `script = null` —
## иначе скрипт из `veteran_archer.tscn` сбрасывается и взаимодействие пропадает.

const STORY_DIALOGUE_IDS: PackedStringArray = [
	"veteran_archer_intro",
	"veteran_story_1",
	"veteran_story_2",
	"veteran_story_3",
	"veteran_story_4",
	"veteran_truth_react",
	"veteran_youth_death",
]

const NON_STORY_DIALOGUE_IDS: PackedStringArray = [
	"lore_veteran_first_expedition",
	"lore_veteran_training",
	"veteran_archer_banter",
]

## Как у монаха: heal_area радиус 108 — та же дистанция для авто-сюжета и разговора по «атаке».
const TALK_RADIUS: float = 108.0
const AUTO_STORY_RADIUS: float = 108.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var _player_was_in_zone: bool = false
var _block_auto_until_leave: bool = false


func _ready() -> void:
	add_to_group("veteran_npc")
	add_to_group("y_sortable")
	if sprite:
		sprite.play("idle")
	DialogueManager.dialogue_ended.connect(_on_dialogue_ended)


func _physics_process(_delta: float) -> void:
	var player := _get_player()
	if player == null:
		_player_was_in_zone = false
		return
	var dist: float = global_position.distance_to(player.global_position)
	var in_zone: bool = dist <= AUTO_STORY_RADIUS
	if in_zone and not _player_was_in_zone:
		_player_was_in_zone = true
		_on_player_entered_zone()
	elif not in_zone and _player_was_in_zone:
		_player_was_in_zone = false
		_block_auto_until_leave = false


func _on_player_entered_zone() -> void:
	_attempt_auto_story_dialogue()


func _attempt_auto_story_dialogue(ignore_block: bool = false) -> bool:
	if PostFinaleWorld.is_ending_cinematic_active():
		return false
	if DialogueManager.is_active():
		return false
	if not ignore_block and _block_auto_until_leave:
		return false
	var d_id := _pick_story_dialogue_id()
	if d_id.is_empty():
		return false
	return DialogueRegistry.try_start(d_id)


func try_open_interact_dialog() -> bool:
	if PostFinaleWorld.is_ending_cinematic_active():
		return false
	if DialogueManager.is_active():
		return false
	var player := _get_player()
	if player == null:
		return false
	if global_position.distance_to(player.global_position) > TALK_RADIUS:
		return false
	## Сюжет — только авто при входе в зону; по «атаке» — хаб и лор/бантер, как меню у монаха.
	if DialogueRegistry.can_play("veteran_archer_hub"):
		return DialogueRegistry.try_start("veteran_archer_hub")
	var banter_id := _pick_non_story_dialogue_id()
	if not banter_id.is_empty():
		return DialogueRegistry.try_start(banter_id)
	return false


func _pick_story_dialogue_id() -> String:
	for d_id in STORY_DIALOGUE_IDS:
		if DialogueRegistry.can_play(d_id):
			return d_id
	return ""


func _pick_non_story_dialogue_id() -> String:
	for d_id in NON_STORY_DIALOGUE_IDS:
		if DialogueRegistry.can_play(d_id):
			return d_id
	return ""


func _on_dialogue_ended(_sequence: DialogueSequence) -> void:
	call_deferred("_deferred_chain_veteran_story_after_dialogue")


func _deferred_chain_veteran_story_after_dialogue() -> void:
	if not is_inside_tree():
		return
	if DialogueManager.is_active():
		return
	var player := _get_player()
	var in_zone := player != null and global_position.distance_to(player.global_position) <= AUTO_STORY_RADIUS
	if in_zone and _attempt_auto_story_dialogue(true):
		return
	if in_zone:
		_block_auto_until_leave = true


func _get_player() -> Node2D:
	var p := get_tree().get_first_node_in_group("player") as Node2D
	if p != null and is_instance_valid(p):
		return p
	return null


func get_y_sort_bottom_y() -> float:
	var y := YSortSpriteBounds.max_global_y_from_descendants(self)
	if not is_nan(y):
		return y
	return global_position.y
