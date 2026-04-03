extends "res://characters/support_npc.gd"
## NPC-поддержка (монах): сюжет и хил зоны.

enum State { IDLE, RUN, HEAL }
var state = State.IDLE
var target_player = null
var can_heal = true

## Движение как у рабочих: нав-сетка + SquadWorkerLikeSteering; без гонки — возврат на стартовую точку.
var _follow_nav: SquadNavFollow = SquadNavFollow.new()
var _sync_nav_attempts: int = 0
var _home_spawn: Vector2 = Vector2.ZERO
var _home_spawn_ready: bool = false

@export var follow_use_navigation: bool = true
@export_range(0.15, 1.0, 0.01) var patrol_speed_scale: float = 0.62
@export var home_return_reach_distance: float = 36.0

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
	"intro_base_island",
	"boss_post_1",
	"boss_post_2",
	"boss_post_3",
	"boss_post_4",
	"truth_and_choice",
	"monk_finale_refused",
	"boss_post_5",
	"monk_youth_death_reaction",
	"youth_postmortem_letter_1",
	"youth_postmortem_letter_2",
	"youth_letter_caravan_reminder",
	"youth_letter_healer_prompt",
	"monk_story_1",
	"monk_story_2",
	"monk_story_3",
	"monk_story_4",
	"monk_letter_1",
	"monk_story_5",
	"monk_letter_2",
	"monk_story_6",
]

## Письма матери после смерти Мирона: не автостарт по жетону возвращения с острова — только погоня после каравана + вход в зону хила.
const MIRON_CARAVAN_MAIL_STORY_IDS: PackedStringArray = [
	"youth_postmortem_letter_1",
	"youth_postmortem_letter_2",
	"youth_letter_caravan_reminder",
	"youth_letter_healer_prompt",
]
## Не цеплять автоматически после другого сюжета в зоне — письмо Мирона у причала; беседа у целителя — отдельно.
const NO_AUTO_CHAIN_STORY_IDS: PackedStringArray = [
	"youth_letter_healer_prompt",
	"youth_letter_caravan_reminder",
]

const NON_STORY_DIALOGUE_IDS: PackedStringArray = [
	"lore_crown_purse",
	"lore_crown_contract",
	"lore_order_oath",
	"lore_chain_seal",
	"lore_deaths_liturgy",
	"lore_archer_sentinel",
	"lore_mine_chain",
	"lore_worker_island",
	"lore_gold_blood",
	"lore_return_veteran",
	"heal_banter",
]

## Если не пусто — сюжетные id (см. STORY_DIALOGUE_IDS) при атаке в зоне хила, остальные — при атаке вне неё.
@export var heal_zone_dialogue_ids: PackedStringArray = []
## Устаревшее: один id. Используется только если heal_zone_dialogue_ids пуст.
@export var heal_zone_dialogue_id: String = ""
@onready var anim = $AnimatedSprite2D
@onready var detection = $detection_area
@onready var heal_area = $heal_area
@onready var cooldown = $HealCooldown
## После возврата с острова: сколько раз по клику можно взять шутку (heal_banter), 3–4 за поход.
var _expedition_click_jokes_remaining: int = 0
## После закрытия диалога у целителя не автозапускать следующий сюжет по тому же входу — пока игрок не выйдет из heal_area.
## Чужие диалоги (причал и т.д.) не должны блокировать первый визит к целителю.
var _block_zone_story_autostart_until_leave_heal_area: bool = false


func _ready() -> void:
	super._ready()
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	max_slides = 6
	process_priority = -10
	add_to_group("healer")
	DialogueManager.dialogue_ended.connect(_on_dialogue_ended_zone_flags)
	detection.body_entered.connect(_on_detection)
	detection.body_exited.connect(_on_detection_exited)
	heal_area.body_entered.connect(_on_heal_area)
	heal_area.body_entered.connect(_on_heal_zone_enter_for_story_dialogue)
	heal_area.body_exited.connect(_on_heal_zone_player_exited)
	cooldown.timeout.connect(_on_cooldown)
	cooldown.one_shot = true
	if not Events.location_changed.is_connected(_on_location_changed_sync_nav):
		Events.location_changed.connect(_on_location_changed_sync_nav)
	call_deferred("_capture_home_spawn")
	call_deferred("_sync_follow_nav_layers_from_scene")
	call_deferred("_try_story_dialogue_if_player_starts_in_zone", false)


func _exit_tree() -> void:
	if Events.location_changed.is_connected(_on_location_changed_sync_nav):
		Events.location_changed.disconnect(_on_location_changed_sync_nav)
	if detection != null and detection.body_exited.is_connected(_on_detection_exited):
		detection.body_exited.disconnect(_on_detection_exited)


func _capture_home_spawn() -> void:
	if not is_inside_tree():
		return
	_home_spawn = global_position
	_home_spawn_ready = true


func _on_location_changed_sync_nav(loc: Events.LOCATION) -> void:
	if loc != Events.LOCATION.BASE:
		Events.clear_miron_mail_chase_state()
	_follow_nav.clear()
	call_deferred("_sync_follow_nav_layers_from_scene")


func _sync_follow_nav_layers_from_scene() -> void:
	if not is_inside_tree():
		if _sync_nav_attempts < 8:
			_sync_nav_attempts += 1
			call_deferred("_sync_follow_nav_layers_from_scene")
		return
	_sync_nav_attempts = 0
	_follow_nav.sync_nav_layers_from_scene(self)


func _on_detection_exited(body: Node2D) -> void:
	if GameplayFacade.is_player_body(body):
		target_player = null


func _is_story_dialogue_id(d_id: String) -> bool:
	return not d_id.is_empty() and d_id in STORY_DIALOGUE_IDS


func _on_dialogue_ended_zone_flags(sequence: DialogueSequence) -> void:
	_try_activate_miron_mail_chase_after_caravan(sequence)
	_arm_youth_letter_caravan_reminder_if_eligible(sequence)
	_handle_monk_hub_deferred(sequence)
	call_deferred("_deferred_chain_monk_zone_story_after_dialogue")


func _on_heal_zone_player_exited(body: Node2D) -> void:
	if not GameplayFacade.is_player_body(body):
		return
	_block_zone_story_autostart_until_leave_heal_area = false


## После любого закрытого диалога: если в зоне целителя ещё есть ожидающие сюжетные — запуск подряд; иначе блок до выхода из зоны (как раньше).
func _deferred_chain_monk_zone_story_after_dialogue() -> void:
	if not is_inside_tree():
		return
	if PostFinaleWorld.is_ending_cinematic_active():
		return
	if Events.current_location != Events.LOCATION.BASE:
		return
	if DialogueManager.is_active():
		return
	var player := get_tree().get_first_node_in_group("player") as Node2D
	var in_heal: bool = (
		player != null
		and is_instance_valid(player)
		and bool(heal_area.overlaps_body(player))
	)
	if in_heal and _attempt_start_zone_story_dialogue(true, NO_AUTO_CHAIN_STORY_IDS):
		return
	if in_heal:
		_block_zone_story_autostart_until_leave_heal_area = true


func _is_player_wounded_for_heal(node: Node) -> bool:
	if node.is_in_group("character_unit") and node.has_method("is_health_full"):
		return not node.is_health_full()
	if node.has_method("is_health_full"):
		return not node.is_health_full()
	if "health" in node and "max_health" in node:
		return node.health < node.max_health
	return false


func _player_needs_heal_chase() -> bool:
	if Events.current_location != Events.LOCATION.BASE:
		return false
	if target_player == null or not is_instance_valid(target_player):
		return false
	if heal_area.overlaps_body(target_player):
		return false
	return _is_player_wounded_for_heal(target_player)


func _physics_process(delta: float) -> void:
	if state == State.HEAL:
		return

	if Events.current_location != Events.LOCATION.BASE:
		velocity = Vector2.ZERO
		state = State.IDLE
		move_and_slide()
		update_animation()
		return

	var moving := false
	if _monk_needs_miron_mail_chase():
		var p_miron := get_tree().get_first_node_in_group("player") as Node2D
		if p_miron != null and is_instance_valid(p_miron):
			var goal_m: Vector2 = p_miron.global_position
			velocity = SquadBaseBuildingPatrol.velocity_toward_goal_worker_like(
				self, _follow_nav, goal_m, speed, patrol_speed_scale, follow_use_navigation, delta
			)
			if velocity.length_squared() > 4.0:
				SquadWorkerLikeSteering.apply_wall_slide_toward(self, goal_m, speed * patrol_speed_scale)
			moving = velocity.length_squared() > 1.0
			state = State.RUN if moving else State.IDLE
	elif _player_needs_heal_chase():
		var goal: Vector2 = target_player.global_position
		velocity = SquadBaseBuildingPatrol.velocity_toward_goal_worker_like(
			self, _follow_nav, goal, speed, patrol_speed_scale, follow_use_navigation, delta
		)
		if velocity.length_squared() > 4.0:
			SquadWorkerLikeSteering.apply_wall_slide_toward(self, goal, speed * patrol_speed_scale)
		moving = velocity.length_squared() > 1.0
		state = State.RUN if moving else State.IDLE
	elif not _collect_wounded_healable_in_zone().is_empty():
		velocity = Vector2.ZERO
		state = State.IDLE
		_follow_nav.clear()
	elif _home_spawn_ready and global_position.distance_to(_home_spawn) > home_return_reach_distance:
		velocity = SquadBaseBuildingPatrol.velocity_toward_goal_worker_like(
			self, _follow_nav, _home_spawn, speed, patrol_speed_scale, follow_use_navigation, delta
		)
		if velocity.length_squared() > 4.0:
			SquadWorkerLikeSteering.apply_wall_slide_toward(self, _home_spawn, speed * patrol_speed_scale)
		moving = velocity.length_squared() > 1.0
		state = State.RUN if moving else State.IDLE
	else:
		velocity = Vector2.ZERO
		state = State.IDLE
		_follow_nav.clear()

	_apply_soft_separation_to_velocity(delta)
	move_and_slide()

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
	call_deferred("_try_expedition_story_skip_miron_mail")


func _heal_zone_dialogue_ids_resolved() -> PackedStringArray:
	if not heal_zone_dialogue_ids.is_empty():
		return heal_zone_dialogue_ids
	if not heal_zone_dialogue_id.is_empty():
		return PackedStringArray([heal_zone_dialogue_id])
	return PackedStringArray()


func _pick_miron_caravan_mail_id() -> String:
	if not StoryState.has_flag("worker_youth_dead"):
		return ""
	if GameplayFacade.is_story_youth_miron_alive_in_scene():
		return ""
	for d_id in MIRON_CARAVAN_MAIL_STORY_IDS:
		if DialogueRegistry.can_play(d_id):
			return d_id
	return ""


func _pick_story_dialogue_id(exclude_ids: PackedStringArray = PackedStringArray()) -> String:
	if not heal_zone_dialogue_ids.is_empty() or not heal_zone_dialogue_id.is_empty():
		for d_id in _heal_zone_dialogue_ids_resolved():
			if not _is_story_dialogue_id(d_id):
				continue
			if not exclude_ids.is_empty() and d_id in exclude_ids:
				continue
			if DialogueRegistry.can_play(d_id):
				return d_id
		return ""
	for d_id in STORY_DIALOGUE_IDS:
		if not exclude_ids.is_empty() and d_id in exclude_ids:
			continue
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


func _attempt_start_zone_story_dialogue(
	ignore_zone_block: bool = false, exclude_ids: PackedStringArray = PackedStringArray()
) -> bool:
	if PostFinaleWorld.is_ending_cinematic_active():
		return false
	if Events.current_location != Events.LOCATION.BASE:
		return false
	if DialogueManager.is_active():
		return false
	if not ignore_zone_block and _block_zone_story_autostart_until_leave_heal_area:
		return false
	var d_id := _pick_story_dialogue_id(exclude_ids)
	if d_id.is_empty() or not DialogueRegistry.can_play(d_id):
		return false
	return DialogueRegistry.try_start(d_id)


func _attempt_start_attack_dialogue() -> bool:
	if PostFinaleWorld.is_ending_cinematic_active():
		return false
	if DialogueManager.is_active():
		return false
	var d_id := _pick_non_story_dialogue_id()
	if d_id.is_empty() or not DialogueRegistry.can_play(d_id):
		return false
	if not DialogueRegistry.try_start(d_id):
		return false
	if d_id == "heal_banter":
		_expedition_click_jokes_remaining = maxi(0, _expedition_click_jokes_remaining - 1)
	return true


func try_open_interact_dialog() -> bool:
	return _try_healer_interact_from_player_close()


func _handle_monk_hub_deferred(sequence: DialogueSequence) -> void:
	if sequence == null or sequence.id != "monk_interact_hub":
		return
	if StoryState.has_flag("monk_hub_queue_truth_choice"):
		StoryState.set_flag("monk_hub_queue_truth_choice", false)
		call_deferred("_deferred_run_truth_choice_after_hub")
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
	DialogueRegistry.try_start("healer_idle_fallback")


func _deferred_run_truth_choice_after_hub() -> void:
	if not is_inside_tree():
		return
	await get_tree().process_frame
	if DialogueManager.is_active():
		return
	if DialogueRegistry.try_start("truth_and_choice"):
		return
	if _attempt_start_zone_story_dialogue(true):
		return
	if _attempt_start_attack_dialogue():
		return
	DialogueRegistry.try_start("healer_idle_fallback")


func _deferred_run_banter_after_hub() -> void:
	if not is_inside_tree():
		return
	await get_tree().process_frame
	if DialogueManager.is_active():
		return
	if _attempt_start_attack_dialogue():
		return
	DialogueRegistry.try_start("healer_idle_fallback")


func _try_healer_interact_from_player_close() -> bool:
	if PostFinaleWorld.is_ending_cinematic_active():
		return false
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
	return DialogueRegistry.try_start("monk_interact_hub")


func _on_heal_zone_enter_for_story_dialogue(body: Node2D) -> void:
	if not GameplayFacade.is_player_body(body):
		return
	if Events.monk_miron_mail_chase_pending:
		if (
			not StoryState.has_flag("worker_youth_dead")
			or GameplayFacade.is_story_youth_miron_alive_in_scene()
		):
			Events.monk_miron_mail_chase_pending = false
		else:
			var mid := _pick_miron_caravan_mail_id()
			if mid.is_empty():
				Events.monk_miron_mail_chase_pending = false
			elif not DialogueManager.is_active() and DialogueRegistry.try_start(mid):
				Events.monk_miron_mail_chase_pending = false
				return
	_attempt_start_zone_story_dialogue(false)


func _try_story_dialogue_if_player_starts_in_zone(ignore_zone_block: bool = false) -> void:
	if DialogueManager.is_active():
		return
	for body in heal_area.get_overlapping_bodies():
		if GameplayFacade.is_player_body(body):
			_attempt_start_zone_story_dialogue(ignore_zone_block)
			break


func _try_expedition_story_skip_miron_mail() -> void:
	if DialogueManager.is_active():
		return
	for body in heal_area.get_overlapping_bodies():
		if GameplayFacade.is_player_body(body):
			_attempt_start_zone_story_dialogue(true, MIRON_CARAVAN_MAIL_STORY_IDS)
			break


func _try_activate_miron_mail_chase_after_caravan(sequence: DialogueSequence) -> void:
	if sequence == null or sequence.id != "caravan_arrival":
		return
	if not Events.monk_miron_mail_chase_defer:
		return
	Events.monk_miron_mail_chase_defer = false
	if not StoryState.has_flag("worker_youth_dead"):
		return
	if GameplayFacade.is_story_youth_miron_alive_in_scene():
		return
	var mid := _pick_miron_caravan_mail_id()
	if mid.is_empty():
		return
	Events.monk_miron_mail_chase_pending = true


func _arm_youth_letter_caravan_reminder_if_eligible(sequence: DialogueSequence) -> void:
	if sequence == null or sequence.id != "caravan_arrival":
		return
	if not StoryState.has_flag("worker_youth_dead"):
		return
	if StoryState.has_flag("youth_letter_sent_done"):
		return
	if not StoryState.has_flag("youth_letter_send_deferred"):
		return
	if not StoryState.has_flag("youth_letter_healer_prompt_done"):
		return
	if not StoryState.has_flag("youth_postmortem_1_done") or not StoryState.has_flag("youth_belongings_found"):
		return
	if SaveManager.expedition_return_count < 3:
		return
	StoryState.set_flag("youth_letter_reminder_pending", true)


func _monk_needs_miron_mail_chase() -> bool:
	if not Events.monk_miron_mail_chase_pending:
		return false
	if not StoryState.has_flag("worker_youth_dead") or GameplayFacade.is_story_youth_miron_alive_in_scene():
		Events.monk_miron_mail_chase_pending = false
		return false
	if Events.current_location != Events.LOCATION.BASE:
		return false
	if DialogueManager.is_active():
		return false
	if _pick_miron_caravan_mail_id().is_empty():
		Events.monk_miron_mail_chase_pending = false
		return false
	var player_mc := get_tree().get_first_node_in_group("player") as Node2D
	if player_mc == null or not is_instance_valid(player_mc):
		return false
	if heal_area.overlaps_body(player_mc):
		return false
	return true


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


func _effective_heal() -> int:
	return maxi(1, int(round(float(heal_amount) * CrownSystem.get_heal_modifier())))


func _heal_pulse() -> void:
	if not can_heal:
		return
	var targets := _collect_wounded_healable_in_zone()
	if targets.is_empty():
		return
	can_heal = false
	cooldown.start(heal_cooldown)
	var eff := _effective_heal()
	for target in targets:
		GameplayFacade.try_apply_heal(target, eff)
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
	GameplayFacade.try_apply_heal(target, _effective_heal())
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
