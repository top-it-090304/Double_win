extends "res://ally/pawn/scripts/pawn_base.gd"
## Сюжетный рабочий: один узел = `pawn_base` (добыча, бой, приказы) + сюжет (диалоги, периодические просьбы в отряд).
## Не в pawn_count; смерть → worker_youth_dead. Узел помещается на базе в сцену (причал); дублирующий спавн GameManager не создаёт второй экземпляр.
## Интро (без выбора): доброволец, хлопоты, связник на холме; после — добыча мяса на базе.
## Периодические просьбы в отряд — только из зоны (авто). Набор в отряд и меню приказов — по удару, как у остальных.

const MAX_STORY_INTERACT_DISTANCE := 152.0
## Повторная авто-просьба в отряд (`dock_worker_youth_ask_again`): не чаще, чем раз на
## RETURNS_BETWEEN_SQUAD_ASKS успешных возвратов с экспедиции (`SaveManager.expedition_return_count`),
## считая от последнего завершения интро / recruit / ask_again (якорь `worker_youth_last_prompt_expedition_return`).
## Не срабатывает, если юноша уже в отряде, мёртв или закреплён за работой на базе.
const RETURNS_BETWEEN_SQUAD_ASKS := 2
## Дистанция, на которой при первом заходе на базу начинается интро (после бега к герою или при уже близком герое).
const INTRO_RUN_STOP_DIST := 140.0

@onready var _story_interact_area: Area2D = $StoryInteractArea
## Пока true — юноша бежит к герою, чтобы начать интро (только если интро ещё не пройдено).
var _intro_chase_active: bool = false


func _ready() -> void:
	if StoryState.has_flag("worker_youth_dead"):
		queue_free()
		return
	add_to_group("story_youth_companion")
	add_to_group("dock_youth_interact")
	max_health = 55
	attack_damage = 12
	super._ready()
	speed = 130.0
	_sync_youth_base_worker_job()
	if _story_interact_area:
		_story_interact_area.body_entered.connect(_on_story_interact_body_entered)
	DialogueManager.dialogue_ended.connect(_on_dialogue_ended)
	Events.expedition_returned.connect(_on_expedition_returned)
	Events.location_changed.connect(_on_location_changed)
	call_deferred("_refresh_periodic_squad_prompt_flag")
	call_deferred("_maybe_begin_intro_sequence")


func _exit_tree() -> void:
	if DialogueManager.dialogue_ended.is_connected(_on_dialogue_ended):
		DialogueManager.dialogue_ended.disconnect(_on_dialogue_ended)
	if Events.expedition_returned.is_connected(_on_expedition_returned):
		Events.expedition_returned.disconnect(_on_expedition_returned)
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
	super._physics_process(delta)


func _process_follow_custom(delta: float) -> bool:
	if _process_intro_run_to_player(delta):
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
		return true
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null or not is_instance_valid(player):
		velocity = Vector2.ZERO
		_play_idle()
		return true
	if global_position.distance_to(player.global_position) <= INTRO_RUN_STOP_DIST:
		_intro_chase_active = false
		DialogueRegistry.try_start("dock_worker_youth_intro")
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
	velocity = (to_player / dist) * speed
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
	if player != null and is_instance_valid(player) and _is_player_in_interact_range(player):
		DialogueRegistry.try_start("dock_worker_youth_intro")
		return
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


func _youth_placed_in_world() -> bool:
	return StoryState.has_flag("worker_youth_recruited") or StoryState.has_flag("worker_youth_works_on_base")


func _is_player_in_interact_range(player: Node2D) -> bool:
	if player == null or not is_instance_valid(player):
		return false
	if global_position.distance_to(player.global_position) <= MAX_STORY_INTERACT_DISTANCE:
		return true
	if _story_interact_area and is_instance_valid(_story_interact_area) and _story_interact_area.overlaps_body(player):
		return true
	return false


func _on_expedition_returned(_new_count: int) -> void:
	call_deferred("_refresh_periodic_squad_prompt_flag")


func _on_location_changed(loc: Events.LOCATION) -> void:
	if loc == Events.LOCATION.BASE:
		call_deferred("_refresh_periodic_squad_prompt_flag")
		call_deferred("_maybe_begin_intro_sequence")


func _refresh_periodic_squad_prompt_flag() -> void:
	if not is_inside_tree():
		return
	if Events.current_location != Events.LOCATION.BASE:
		return
	if StoryState.has_flag("worker_youth_dead"):
		return
	if not StoryState.has_flag("worker_youth_intro_done"):
		return
	if StoryState.has_flag("worker_youth_recruited"):
		StoryState.set_flag("worker_youth_periodic_ask_ready", false)
		return
	if StoryState.has_flag("worker_youth_works_on_base"):
		StoryState.set_flag("worker_youth_periodic_ask_ready", false)
		return
	var last := int(SaveManager.story_flags.get("worker_youth_last_prompt_expedition_return", -1))
	var cur := SaveManager.expedition_return_count
	if last < 0:
		return
	if cur - last >= RETURNS_BETWEEN_SQUAD_ASKS:
		StoryState.set_flag("worker_youth_periodic_ask_ready", true)


func _on_dialogue_ended(sequence: DialogueSequence) -> void:
	if sequence == null:
		return
	var sid: String = sequence.id
	if sid == "dock_worker_youth_intro":
		_record_prompt_anchor_after_dialogue()
	elif sid == "dock_worker_youth_recruit" or sid == "dock_worker_youth_ask_again":
		_record_prompt_anchor_after_dialogue()
		StoryState.set_flag("worker_youth_periodic_ask_ready", false)
	_sync_youth_base_worker_job()


func _record_prompt_anchor_after_dialogue() -> void:
	SaveManager.story_flags["worker_youth_last_prompt_expedition_return"] = SaveManager.expedition_return_count
	SaveManager.save_game()


## Только авто-сюжет из зоны: первый интро и периодическая просьба в отряд (не набор и не меню).
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
		DialogueRegistry.try_start("dock_worker_youth_intro")
	elif StoryState.has_flag("worker_youth_periodic_ask_ready") and DialogueRegistry.can_play("dock_worker_youth_ask_again"):
		DialogueRegistry.try_start("dock_worker_youth_ask_again")


## По удару: первый выбор «в поход / на базе» и меню приказов — как у остальных союзников.
func try_open_priority_story_dialog() -> bool:
	return _try_open_attack_dialogs_internal(true)


func try_open_interact_dialog() -> bool:
	return _try_open_attack_dialogs_internal(false)


func _try_open_attack_dialogs_internal(require_attack_overlap: bool) -> bool:
	if DialogueManager.is_active():
		return false
	if StoryState.has_flag("worker_youth_dead"):
		return false
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if not _is_player_in_interact_range(player):
		return false
	if require_attack_overlap and player != null and is_instance_valid(player):
		var p_attack := player.get_node_or_null("AttackArea") as Area2D
		if p_attack == null or not p_attack.overlaps_body(self):
			return false
	if DialogueRegistry.can_play("dock_worker_youth_recruit"):
		return DialogueRegistry.try_start("dock_worker_youth_recruit")
	if _youth_placed_in_world():
		var hud := GameplayFacade.get_hud(get_tree())
		if hud and hud.has_method("try_open_squad_orders_menu"):
			return hud.try_open_squad_orders_menu(self)
	return false
