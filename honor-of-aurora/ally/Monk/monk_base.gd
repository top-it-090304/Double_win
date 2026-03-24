extends "res://characters/support_npc.gd"
## NPC-поддержка (монах): сюжет и хил зоны.

enum State { IDLE, RUN, HEAL }
var state = State.IDLE
var target_player = null
var can_heal = true

@export var speed = 150.0
@export var heal_amount = 50
@export var heal_cooldown = 3.0
@export var spawn_health: int = 100
@export var max_health: int = 60


var health: int:
	get:
		return health_component.current_health if health_component else 0

## Сюжет при входе в heal_area (авто) и после закрытия диалога — не снова по body_entered, пока герой не выйдет из зоны.
## Лор/бантер — по «attack» рядом с монахом (в зоне хила при атаке сначала сюжет, если ещё доступен).
const STORY_DIALOGUE_IDS: PackedStringArray = [
	"boss_post_1",
	"boss_post_2",
	"boss_post_3",
	"boss_post_4",
	"truth_and_choice",
	"monk_finale_refused",
	"boss_post_5",
	"intro_base_island",
	"monk_story_1",
	"monk_story_2",
	"monk_story_3",
	"monk_story_4",
	"monk_letter_1",
	"monk_story_5",
	"monk_letter_2",
	"monk_story_6",
]

const NON_STORY_DIALOGUE_IDS: PackedStringArray = [
	"lore_crown_purse",
	"lore_crown_contract",
	"lore_order_oath",
	"lore_chain_seal",
	"lore_deaths_liturgy",
	"lore_archer_sentinel",
	"lore_gold_blood",
	"lore_return_veteran",
	"heal_banter",
]

## Если не пусто — сюжетные id (см. STORY_DIALOGUE_IDS) при атаке в зоне хила, остальные — при атаке вне неё.
@export var heal_zone_dialogue_ids: PackedStringArray = []
## Устаревшее: один id. Используется только если heal_zone_dialogue_ids пуст.
@export var heal_zone_dialogue_id: String = ""
@export var heal_zone_dialogue_pause_game: bool = false

@onready var anim = $AnimatedSprite2D
@onready var detection = $detection_area
@onready var heal_area = $heal_area
@onready var cooldown = $HealCooldown
## После возврата с острова: сколько раз по клику можно взять шутку (heal_banter), 3–4 за поход.
var _expedition_click_jokes_remaining: int = 0
## После любого закрытия диалога не автозапускать сюжет по входу в зону, пока игрок не выйдет из heal_area.
var _block_zone_story_autostart_until_leave_heal_area: bool = false


func _ready() -> void:
	super._ready()
	process_priority = -10
	add_to_group("healer")
	DialogueManager.dialogue_ended.connect(_on_dialogue_ended_zone_flags)
	detection.body_entered.connect(_on_detection)
	heal_area.body_entered.connect(_on_heal_area)
	heal_area.body_entered.connect(_on_heal_zone_enter_for_story_dialogue)
	heal_area.body_exited.connect(_on_heal_zone_player_exited)
	cooldown.timeout.connect(_on_cooldown)
	cooldown.one_shot = true
	call_deferred("_try_story_dialogue_if_player_starts_in_zone", false)


func _is_story_dialogue_id(d_id: String) -> bool:
	return not d_id.is_empty() and d_id in STORY_DIALOGUE_IDS


func _on_dialogue_ended_zone_flags(sequence: DialogueSequence) -> void:
	_block_zone_story_autostart_until_leave_heal_area = true
	_handle_monk_hub_deferred(sequence)


func _on_heal_zone_player_exited(body: Node2D) -> void:
	if not GameplayFacade.is_player_body(body):
		return
	_block_zone_story_autostart_until_leave_heal_area = false


func _physics_process(delta):
	if state == State.HEAL:
		return
		
	if target_player and is_instance_valid(target_player):
		var should_move = true
		var in_heal_zone = heal_area.overlaps_body(target_player)
		
		var health_full := false
		if target_player.is_in_group("character_unit") and target_player.has_method("is_health_full"):
			health_full = target_player.is_health_full()
		elif target_player.has_method("is_health_full"):
			health_full = target_player.is_health_full()
		elif "health" in target_player and "max_health" in target_player:
			health_full = target_player.health >= target_player.max_health
		
		if in_heal_zone or health_full:
			should_move = false
		
		if should_move:
			var dir = global_position.direction_to(target_player.global_position)
			velocity = dir * speed
			move_and_slide()
			state = State.RUN if velocity.length() > 0 else State.IDLE
		else:
			velocity = Vector2.ZERO
			state = State.IDLE

	else:
		velocity = Vector2.ZERO
		state = State.IDLE

	# Герой, союзники в отряде: один «пульс» на кулдаун на всех раненых в зоне.
	if can_heal and not _collect_wounded_healable_in_zone().is_empty():
		_heal_pulse()
	
	update_animation()

func update_animation():
	match state:
		State.IDLE:
			anim.play("idle")
		State.RUN:
			anim.play("run")
			anim.flip_h = velocity.x < 0

func _on_detection(body: Node2D) -> void:
	if GameplayFacade.is_player_body(body):
		target_player = body


## Вызывается из GameManager после загрузки сцены базы — после возврата с острова.
func apply_pending_healer_dialogue_token() -> void:
	if not Events.pending_healer_dialogue_after_expedition:
		return
	_expedition_click_jokes_remaining = randi_range(3, 4)
	Events.pending_healer_dialogue_after_expedition = false
	call_deferred("_try_story_dialogue_if_player_starts_in_zone", true)


func _heal_zone_dialogue_ids_resolved() -> PackedStringArray:
	if not heal_zone_dialogue_ids.is_empty():
		return heal_zone_dialogue_ids
	if not heal_zone_dialogue_id.is_empty():
		return PackedStringArray([heal_zone_dialogue_id])
	return PackedStringArray()


func _pick_story_dialogue_id() -> String:
	if not heal_zone_dialogue_ids.is_empty() or not heal_zone_dialogue_id.is_empty():
		for d_id in _heal_zone_dialogue_ids_resolved():
			if not _is_story_dialogue_id(d_id):
				continue
			if DialogueRegistry.can_play(d_id):
				return d_id
		return ""
	for d_id in STORY_DIALOGUE_IDS:
		if DialogueRegistry.can_play(d_id):
			return d_id
	return ""


func _pick_non_story_dialogue_id() -> String:
	if not heal_zone_dialogue_ids.is_empty() or not heal_zone_dialogue_id.is_empty():
		for d_id in _heal_zone_dialogue_ids_resolved():
			if _is_story_dialogue_id(d_id):
				continue
			if d_id == "heal_banter" and _expedition_click_jokes_remaining <= 0:
				continue
			if DialogueRegistry.can_play(d_id):
				return d_id
		return ""
	for d_id in NON_STORY_DIALOGUE_IDS:
		if d_id == "heal_banter" and _expedition_click_jokes_remaining <= 0:
			continue
		if DialogueRegistry.can_play(d_id):
			return d_id
	return ""


func _attempt_start_zone_story_dialogue(ignore_zone_block: bool = false) -> bool:
	if DialogueManager.is_active():
		return false
	if not ignore_zone_block and _block_zone_story_autostart_until_leave_heal_area:
		return false
	var d_id := _pick_story_dialogue_id()
	if d_id.is_empty() or not DialogueRegistry.can_play(d_id):
		return false
	return DialogueRegistry.try_start(d_id, heal_zone_dialogue_pause_game)


func _attempt_start_attack_dialogue() -> bool:
	if DialogueManager.is_active():
		return false
	var d_id := _pick_non_story_dialogue_id()
	if d_id.is_empty() or not DialogueRegistry.can_play(d_id):
		return false
	if not DialogueRegistry.try_start(d_id, heal_zone_dialogue_pause_game):
		return false
	if d_id == "heal_banter":
		_expedition_click_jokes_remaining = maxi(0, _expedition_click_jokes_remaining - 1)
	return true


func try_open_interact_dialog() -> bool:
	return _try_healer_interact_from_player_close()


func _handle_monk_hub_deferred(sequence: DialogueSequence) -> void:
	if sequence == null or sequence.id != "monk_interact_hub":
		return
	if StoryState.has_flag("monk_hub_def_story"):
		StoryState.set_flag("monk_hub_def_story", false)
		call_deferred("_deferred_run_story_after_hub")
		return
	if StoryState.has_flag("monk_hub_def_banter"):
		StoryState.set_flag("monk_hub_def_banter", false)
		call_deferred("_deferred_run_banter_after_hub")


func _deferred_run_story_after_hub() -> void:
	if not is_inside_tree():
		return
	await get_tree().process_frame
	if DialogueManager.is_active():
		return
	if _attempt_start_zone_story_dialogue(true):
		return
	if _attempt_start_attack_dialogue():
		return
	DialogueRegistry.try_start("healer_idle_fallback", heal_zone_dialogue_pause_game)


func _deferred_run_banter_after_hub() -> void:
	if not is_inside_tree():
		return
	await get_tree().process_frame
	if DialogueManager.is_active():
		return
	if _attempt_start_attack_dialogue():
		return
	DialogueRegistry.try_start("healer_idle_fallback", heal_zone_dialogue_pause_game)


func _try_healer_interact_from_player_close() -> bool:
	if DialogueManager.is_active():
		return false
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null or not is_instance_valid(player):
		return false
	## Диалог по «атаке» только в зоне лечения (heal_area), не во всей зоне detection.
	if not heal_area.overlaps_body(player):
		return false
	if not DialogueRegistry.can_play("monk_interact_hub"):
		return false
	return DialogueRegistry.try_start("monk_interact_hub", heal_zone_dialogue_pause_game)


func _on_heal_zone_enter_for_story_dialogue(body: Node2D) -> void:
	if not GameplayFacade.is_player_body(body):
		return
	_attempt_start_zone_story_dialogue(false)


func _try_story_dialogue_if_player_starts_in_zone(ignore_zone_block: bool = false) -> void:
	if DialogueManager.is_active():
		return
	for body in heal_area.get_overlapping_bodies():
		if GameplayFacade.is_player_body(body):
			_attempt_start_zone_story_dialogue(ignore_zone_block)
			break


func _on_heal_area(_body: Node2D) -> void:
	if not can_heal:
		return
	if _collect_wounded_healable_in_zone().is_empty():
		return
	_heal_pulse()


func _is_wounded_healable_unit(node: Node) -> bool:
	if not GameplayFacade.can_receive_monk_heal(node):
		return false
	if node.is_in_group("character_unit") and node.has_method("is_health_full"):
		return not node.is_health_full()
	if node.has_method("is_health_full"):
		return not node.is_health_full()
	if "health" in node and "max_health" in node:
		return node.health < node.max_health
	return false


func _collect_wounded_healable_in_zone() -> Array[Node]:
	var out: Array[Node] = []
	for body in heal_area.get_overlapping_bodies():
		if _is_wounded_healable_unit(body):
			out.append(body)
	return out


func _heal_pulse() -> void:
	if not can_heal:
		return
	var targets := _collect_wounded_healable_in_zone()
	if targets.is_empty():
		return
	can_heal = false
	cooldown.start(heal_cooldown)
	for target in targets:
		GameplayFacade.try_apply_heal(target, heal_amount)
		if target.has_method("play_heal_effect"):
			target.play_heal_effect()
	SoundManager.play_heal()
	play_heal_effect()
	state = State.HEAL
	anim.play("heal")
	await anim.animation_finished
	state = State.IDLE


func _heal_single(target: Node) -> void:
	can_heal = false
	cooldown.start(heal_cooldown)
	GameplayFacade.try_apply_heal(target, heal_amount)
	if target.has_method("play_heal_effect"):
		target.play_heal_effect()
	SoundManager.play_heal()
	play_heal_effect()
	state = State.HEAL
	anim.play("heal")
	await anim.animation_finished
	state = State.IDLE

func play_heal_effect():
	if anim.sprite_frames.has_animation("heal_effect"):
		anim.play("heal_effect")
		await get_tree().create_timer(0.3).timeout
		update_animation()

func _on_cooldown():
	can_heal = true

func take_damage(amount: Variant) -> void:
	if health_component == null:
		return
	var a: int = int(amount)
	health_component.apply_damage(a)
	if health_component.current_health <= 0:
		return
	if a > 0 and can_heal and health_component.current_health < health_component.max_health:
		_heal_single(self)


func _get_initial_max_health() -> int:
	return max_health


func _get_initial_health() -> int:
	return mini(spawn_health, max_health)
