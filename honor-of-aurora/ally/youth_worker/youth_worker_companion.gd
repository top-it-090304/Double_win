extends "res://ally/pawn/scripts/pawn_base.gd"
## Сюжетный рабочий: один узел = `pawn_base` (добыча, бой, приказы) + сюжет (диалоги, периодические просьбы в отряд).
## Не в pawn_count; смерть → worker_youth_dead. Узел помещается на базе в сцену (причал); дублирующий спавн GameManager не создаёт второй экземпляр.
## Интро (без выбора): доброволец, хлопоты, связник на холме; после — добыча мяса на базе.
## Набор и работа на базе — через меню приказов по удару; в походе остаётся рабочим (без переобучения лучник/копейщик).
## Интро и лагерь: при появлении на базе. Живые письма — только при прибытии каравана (см. `on_caravan_arrived_for_mail`).

const MAX_STORY_INTERACT_DISTANCE := 152.0
## Дистанция, на которой после бега стартует сюжетный диалог.
const INTRO_RUN_STOP_DIST := 140.0
## Явно быстрее обычного follow — иначе «мясо»/овцы уводят в ATTACK и визуально «не бежит».
const STORY_CHASE_SPEED := 168.0

@onready var _story_interact_area: Area2D = $StoryInteractArea
## Пока true — юноша бежит к герою, чтобы начать интро (только если интро ещё не пройдено).
var _intro_chase_active: bool = false
## Непусто — бежит к герою и запускает этот id диалога (письма, беседа в лагере).
var _story_chase_dialog_id: String = ""
## Во время погони отключаем удар по овцам — иначе снова ATTACK и цикл follow не крутится.
var _attack_disabled_for_pursuit: bool = false


func _ready() -> void:
	if StoryState.has_flag("worker_youth_dead"):
		if StoryState.has_flag("worker_youth_death_scene_done"):
			queue_free()
			return
		visible = false
		set_physics_process(false)
		set_process(false)
		DialogueManager.dialogue_ended.connect(_on_dialogue_ended)
		Events.location_changed.connect(_on_location_changed)
		call_deferred("_maybe_trigger_death_scene")
		return
	add_to_group("story_youth_companion")
	add_to_group("miron_mail_carrier")
	add_to_group("dock_youth_interact")
	## Как у спавна в GameManager: удар по союзнику открывает меню приказов (`squad_member` в worrier_base).
	add_to_group("squad_member")
	max_health = 12
	attack_damage = 12
	## Старые сохранения: сброс неиспользуемого пути «обучение у стрельбища/замка».
	if StoryState.has_flag("worker_youth_training_archer") or StoryState.has_flag("worker_youth_training_lancer"):
		StoryState.clear_flag("worker_youth_training_archer")
		StoryState.clear_flag("worker_youth_training_lancer")
	super._ready()
	speed = 130.0
	_sync_youth_base_worker_job()
	if _story_interact_area:
		_story_interact_area.body_entered.connect(_on_story_interact_body_entered)
	DialogueManager.dialogue_ended.connect(_on_dialogue_ended)
	Events.location_changed.connect(_on_location_changed)
	call_deferred("_maybe_begin_intro_sequence")
	## После телепорта НА базу узел только появился — лагерь (не письма).
	call_deferred("_sync_youth_story_triggers_after_base_spawn")
	call_deferred("_migrate_miron_caravan_mail_flags")


func _exit_tree() -> void:
	if DialogueManager.dialogue_ended.is_connected(_on_dialogue_ended):
		DialogueManager.dialogue_ended.disconnect(_on_dialogue_ended)
	if Events.location_changed.is_connected(_on_location_changed):
		Events.location_changed.disconnect(_on_location_changed)


func _physics_process(delta: float) -> void:
	if DialogueManager.is_active() and state != State.DEAD:
		if state == State.ATTACK:
			state = State.FOLLOW
		velocity = Vector2.ZERO
		_cancel_base_worker()
		_play_idle()
		if _nav_agent and is_instance_valid(_nav_agent):
			_nav_agent.target_position = global_position
			_nav_agent.velocity = Vector2.ZERO
		move_and_slide()
		return
	var pursuing := (
		state != State.DEAD
		and Events.current_location == Events.LOCATION.BASE
		and (_intro_chase_active or not _story_chase_dialog_id.is_empty())
	)
	if not pursuing:
		_restore_attack_after_pursuit_if_needed()
	## `_process_follow_custom` только при FOLLOW; на мясе — ATTACK по овцам. Сюжетный бег — здесь, без soft-separation (оно размывает курс к герою).
	if pursuing:
		if attack_area and attack_area.monitoring:
			attack_area.monitoring = false
			_attack_disabled_for_pursuit = true
		if not player or not is_instance_valid(player):
			player = get_tree().get_first_node_in_group("player") as Node2D
		_attack_cd = maxf(0.0, _attack_cd - delta)
		var chased := false
		if _process_intro_run_to_player(delta):
			chased = true
		elif _process_story_chase_to_player(delta):
			chased = true
		if chased:
			state = State.FOLLOW
			var vel_before := velocity
			move_and_slide()
			_sync_follow_movement_animation(vel_before)
			if _nav_agent and is_instance_valid(_nav_agent):
				_nav_agent.velocity = velocity
			return
	super._physics_process(delta)


func _pursuit_run_speed() -> float:
	return maxf(speed, STORY_CHASE_SPEED)


func _restore_attack_after_pursuit_if_needed() -> void:
	if not _attack_disabled_for_pursuit:
		return
	_attack_disabled_for_pursuit = false
	if state == State.DEAD:
		return
	if attack_area and is_instance_valid(attack_area):
		attack_area.monitoring = true


func _sync_youth_story_triggers_after_base_spawn() -> void:
	if not is_inside_tree():
		return
	if Events.current_location != Events.LOCATION.BASE:
		return
	_run_base_youth_camp_when_ready()


## Старые сохранения: pending второго письма → общий флаг после босса 1; без флага при уже убитом боссе 1 — догоняем.
## Письмо 6 раньше вешалось на босса 5 — переносим на `youth_miron_letter6_pending_next_caravan` после письма 5.
func _migrate_miron_caravan_mail_flags() -> void:
	if not is_inside_tree():
		return
	if StoryState.has_flag("worker_youth_dead"):
		return
	if StoryState.has_flag("youth_miron_mail_after_boss_5"):
		if (
			StoryState.has_flag("youth_letter_5_done")
			and not StoryState.has_flag("youth_letter_6_done")
		):
			StoryState.set_flag("youth_miron_letter6_pending_next_caravan", true)
		StoryState.clear_flag("youth_miron_mail_after_boss_5")
		SaveManager.save_game()
	if (
		StoryState.has_flag("youth_letter_5_done")
		and not StoryState.has_flag("youth_letter_6_done")
		and not StoryState.has_flag("youth_miron_letter6_pending_next_caravan")
	):
		StoryState.set_flag("youth_miron_letter6_pending_next_caravan", true)
		SaveManager.save_game()
	if StoryState.has_flag("youth_miron_letter2_pending_next_caravan"):
		StoryState.set_flag("youth_miron_mail_after_boss_1", true)
		StoryState.clear_flag("youth_miron_letter2_pending_next_caravan")
		SaveManager.save_game()
		return
	if not StoryState.has_flag("story_island_1_cleared"):
		return
	if not StoryState.has_flag("youth_letter_1_done") or StoryState.has_flag("youth_letter_2_done"):
		return
	if StoryState.has_flag("youth_miron_mail_after_boss_1"):
		return
	StoryState.set_flag("youth_miron_mail_after_boss_1", true)
	SaveManager.save_game()


## Вызывается из CrownSystem перед диалогом прибытия каравана (группа `miron_mail_carrier` — только рабочий у причала).
## После четвёртого стража подряд два приезда: письмо 5, затем письмо 6 (флаг `youth_miron_letter6_pending_next_caravan` после конца письма 5).
func on_caravan_arrived_for_mail() -> void:
	if StoryState.has_flag("worker_youth_dead"):
		return
	if not StoryState.has_flag("worker_youth_intro_done"):
		return
	if not is_inside_tree() or Events.current_location != Events.LOCATION.BASE:
		return
	if not _story_chase_dialog_id.is_empty():
		return
	var completed_dispatches := SaveManager.caravan_sent_count
	if not StoryState.has_flag("youth_letter_1_done"):
		if completed_dispatches != 0:
			return
		if not DialogueRegistry.can_play("worker_youth_letter_1"):
			return
		_arm_story_chase("worker_youth_letter_1")
		return
	for n in range(2, 6):
		var prev_done_key := "youth_letter_%d_done" % (n - 1)
		var this_done_key := "youth_letter_%d_done" % n
		if not StoryState.has_flag(prev_done_key) or StoryState.has_flag(this_done_key):
			continue
		var boss_idx := n - 1
		if not StoryState.has_flag("youth_miron_mail_after_boss_%d" % boss_idx):
			continue
		var did := "worker_youth_letter_%d" % n
		if not DialogueRegistry.can_play(did):
			continue
		_arm_story_chase(did)
		return
	if (
		StoryState.has_flag("youth_letter_5_done")
		and not StoryState.has_flag("youth_letter_6_done")
		and StoryState.has_flag("youth_miron_letter6_pending_next_caravan")
		and DialogueRegistry.can_play("worker_youth_letter_6")
	):
		_arm_story_chase("worker_youth_letter_6")


func _arm_story_chase(dialog_id: String) -> void:
	if dialog_id.is_empty():
		return
	_story_chase_dialog_id = dialog_id
	if state != State.DEAD:
		state = State.FOLLOW
	_cancel_base_worker()


func _process_follow_custom(delta: float) -> bool:
	if _process_intro_run_to_player(delta):
		return true
	if _process_story_chase_to_player(delta):
		return true
	return super._process_follow_custom(delta)


func _process_intro_run_to_player(_delta: float) -> bool:
	if StoryState.has_flag("worker_youth_intro_done"):
		_intro_chase_active = false
		return false
	if not _intro_chase_active:
		return false
	if Events.current_location != Events.LOCATION.BASE:
		return false
	if DialogueManager.is_active():
		velocity = Vector2.ZERO
		_play_idle()
		_cancel_base_worker()
		if _nav_agent and is_instance_valid(_nav_agent):
			_nav_agent.target_position = global_position
			_nav_agent.velocity = Vector2.ZERO
		return true
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null or not is_instance_valid(player):
		velocity = Vector2.ZERO
		_play_idle()
		return true
	if global_position.distance_to(player.global_position) <= INTRO_RUN_STOP_DIST:
		_intro_chase_active = false
		DialogueRegistry.try_start("dock_worker_youth_intro", false)
		velocity = Vector2.ZERO
		_play_idle()
		return true
	## Прямо к герою: не `_steer_toward_goal` из добычи (веер лучей даёт «хаотичный» обход) и не `_apply_base_move_wall_slide` с чужим `_gather_target`.
	var to_player := player.global_position - global_position
	var dist := to_player.length()
	if dist < 0.5:
		velocity = Vector2.ZERO
		_play_idle()
		return true
	_cancel_base_worker()
	velocity = (to_player / dist) * _pursuit_run_speed()
	_face_velocity(velocity)
	_play_run()
	return true


func _process_story_chase_to_player(_delta: float) -> bool:
	if _story_chase_dialog_id.is_empty():
		return false
	if StoryState.has_flag("worker_youth_dead"):
		_story_chase_dialog_id = ""
		return false
	if Events.current_location != Events.LOCATION.BASE:
		_story_chase_dialog_id = ""
		return false
	if DialogueManager.is_active():
		velocity = Vector2.ZERO
		_play_idle()
		_cancel_base_worker()
		if _nav_agent and is_instance_valid(_nav_agent):
			_nav_agent.target_position = global_position
			_nav_agent.velocity = Vector2.ZERO
		return true
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null or not is_instance_valid(player):
		velocity = Vector2.ZERO
		_play_idle()
		return true
	if global_position.distance_to(player.global_position) <= INTRO_RUN_STOP_DIST:
		var sid: String = _story_chase_dialog_id
		_story_chase_dialog_id = ""
		if not DialogueRegistry.try_start(sid, false):
			_story_chase_dialog_id = sid
			velocity = Vector2.ZERO
			_play_idle()
			return true
		velocity = Vector2.ZERO
		_play_idle()
		return true
	var to_player := player.global_position - global_position
	var dist := to_player.length()
	if dist < 0.5:
		velocity = Vector2.ZERO
		_play_idle()
		return true
	_cancel_base_worker()
	velocity = (to_player / dist) * _pursuit_run_speed()
	_face_velocity(velocity)
	_play_run()
	return true


func _maybe_begin_intro_sequence() -> void:
	if not is_inside_tree():
		return
	if StoryState.has_flag("worker_youth_intro_done"):
		return
	if Events.current_location != Events.LOCATION.BASE:
		return
	if DialogueManager.is_active():
		return
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player != null and is_instance_valid(player):
		if global_position.distance_to(player.global_position) <= INTRO_RUN_STOP_DIST:
			DialogueRegistry.try_start("dock_worker_youth_intro", false)
			return
	state = State.FOLLOW
	_cancel_base_worker()
	_intro_chase_active = true


## Руда — только после явного «шахта» в диалоге набора. После интро — мясо, пока не взяли в отряд.
func _sync_youth_base_worker_job() -> void:
	if StoryState.has_flag("worker_youth_dead"):
		return
	if StoryState.has_flag("worker_youth_works_on_base"):
		set_worker_job_from_dialogue("ore")
	elif StoryState.has_flag("worker_youth_recruited"):
		set_worker_job_from_dialogue("none")
	elif StoryState.has_flag("worker_youth_intro_done"):
		set_worker_job_from_dialogue("meat")
	else:
		set_worker_job_from_dialogue("none")


func _is_player_in_interact_range(player: Node2D) -> bool:
	if player == null or not is_instance_valid(player):
		return false
	if global_position.distance_to(player.global_position) <= MAX_STORY_INTERACT_DISTANCE:
		return true
	if _story_interact_area and is_instance_valid(_story_interact_area) and _story_interact_area.overlaps_body(player):
		return true
	return false


func _on_location_changed(loc: Events.LOCATION) -> void:
	if loc == Events.LOCATION.BASE:
		call_deferred("_maybe_begin_intro_sequence")
		call_deferred("_maybe_trigger_death_scene")
		call_deferred("_maybe_trigger_alive_truth_scene")
		call_deferred("_run_base_youth_camp_when_ready")


func _maybe_trigger_death_scene() -> void:
	if not StoryState.has_flag("worker_youth_dead"):
		return
	if StoryState.has_flag("worker_youth_death_scene_done"):
		return
	if DialogueManager.is_active():
		return
	DialogueRegistry.try_start("worker_youth_death")


## Лагерь после прихода на базу (письма — только с караваном). Монах может держать диалог — ждём конца.
func _run_base_youth_camp_when_ready() -> void:
	if not is_inside_tree():
		return
	if DialogueManager.is_active():
		call_deferred("_run_base_youth_camp_when_ready")
		return
	_maybe_trigger_camp_scene()


func _maybe_trigger_camp_scene() -> void:
	if not StoryState.has_flag("worker_youth_recruited"):
		return
	if StoryState.has_flag("worker_youth_camp_done"):
		return
	if StoryState.has_flag("worker_youth_dead"):
		return
	if DialogueManager.is_active():
		return
	if not _story_chase_dialog_id.is_empty():
		return
	if not DialogueRegistry.can_play("worker_youth_camp"):
		return
	_arm_story_chase("worker_youth_camp")


func _maybe_trigger_alive_truth_scene() -> void:
	if StoryState.has_flag("worker_youth_dead"):
		return
	if StoryState.has_flag("worker_youth_recruited"):
		return
	if not StoryState.has_flag("truth_and_choice_done"):
		return
	if StoryState.has_flag("worker_youth_alive_truth_done"):
		return
	if DialogueManager.is_active():
		return
	DialogueRegistry.try_start("worker_youth_alive_truth")


func _on_dialogue_ended(sequence: DialogueSequence) -> void:
	if sequence == null:
		return
	var sid: String = sequence.id
	if sid == "worker_youth_death":
		get_tree().paused = false
		queue_free()
		return
	if sid == "dock_worker_youth_intro":
		_record_prompt_anchor_after_dialogue()
		call_deferred("_run_base_youth_camp_when_ready")
	elif sid == "dock_worker_youth_recruit" or sid == "dock_worker_youth_ask_again":
		_record_prompt_anchor_after_dialogue()
		call_deferred("_run_base_youth_camp_when_ready")
	elif sid == "worker_youth_camp":
		call_deferred("_run_base_youth_camp_when_ready")
	elif sid.begins_with("worker_youth_letter_"):
		var num_str := sid.trim_prefix("worker_youth_letter_")
		if num_str.is_valid_int():
			var n := int(num_str)
			if n >= 2 and n <= 5:
				StoryState.clear_flag("youth_miron_mail_after_boss_%d" % (n - 1))
				if n == 5:
					StoryState.set_flag("youth_miron_letter6_pending_next_caravan", true)
					SaveManager.save_game()
			elif n == 6:
				StoryState.clear_flag("youth_miron_letter6_pending_next_caravan")
	_sync_youth_base_worker_job()


func _record_prompt_anchor_after_dialogue() -> void:
	SaveManager.story_flags["worker_youth_last_prompt_expedition_return"] = SaveManager.expedition_return_count
	SaveManager.save_game()


## Только авто-интро из зоны (без авто-просьбы в отряд — это в меню приказов).
func _on_story_interact_body_entered(body: Node2D) -> void:
	if not GameplayFacade.is_player_body(body):
		return
	if DialogueManager.is_active():
		return
	if StoryState.has_flag("worker_youth_dead"):
		return
	var player := body as Node2D
	if not _is_player_in_interact_range(player):
		return
	if not StoryState.has_flag("worker_youth_intro_done"):
		state = State.FOLLOW
		_cancel_base_worker()
		_intro_chase_active = true


func _handle_death() -> void:
	StoryState.set_flag("worker_youth_dead", true)
	StoryState.clear_flag("worker_youth_recruited")
	set_meta("no_squad_death", true)
	state = State.DEAD
	_attack_cd = 999.0
	velocity = Vector2.ZERO
	var col := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if col:
		col.set_deferred("disabled", true)
	if attack_area:
		attack_area.set_deferred("monitoring", false)
	if sprite:
		if sprite.sprite_frames and sprite.sprite_frames.has_animation(&"dead"):
			sprite.stop()
			sprite.play(&"dead")
			await sprite.animation_finished
	get_tree().paused = true
	DialogueRegistry.try_start("worker_youth_death")


## Сюжетные окна по удару отключены — всё через меню приказов (как у остальных рабочих).
func try_open_priority_story_dialog() -> bool:
	return false


func try_open_interact_dialog() -> bool:
	return false


func _after_menu_recruit_choice() -> void:
	_record_prompt_anchor_after_dialogue()
	StoryState.set_flag("worker_youth_periodic_ask_ready", false)


func is_youth_narrative_recruit_menu_visible() -> bool:
	if StoryState.has_flag("worker_youth_dead"):
		return false
	if not StoryState.has_flag("worker_youth_intro_done"):
		return false
	if StoryState.has_flag("worker_youth_recruited"):
		return false
	if StoryState.has_flag("worker_youth_works_on_base"):
		return false
	return true


func menu_apply_youth_recruit_expedition() -> void:
	StoryState.set_flag("worker_youth_recruited", true)
	StoryState.clear_flag("worker_youth_works_on_base")
	_after_menu_recruit_choice()
	_sync_youth_base_worker_job()
	SaveManager.save_game()


func menu_apply_youth_recruit_base_worker() -> void:
	StoryState.set_flag("worker_youth_works_on_base", true)
	StoryState.clear_flag("worker_youth_recruited")
	_after_menu_recruit_choice()
	_sync_youth_base_worker_job()
	SaveManager.save_game()


func menu_apply_youth_recruit_wait() -> void:
	_after_menu_recruit_choice()
	SaveManager.save_game()
