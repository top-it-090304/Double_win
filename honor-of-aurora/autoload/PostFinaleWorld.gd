extends Node
## После победы над последним стражом: затемнение, красноватая вода и пена волн (слой vawe), тишина врагов.
## Финал: зум камеры, затем тот же оверлей, что при старте из меню (облака + «Честь / Авроры»), с тёплым оттенком облаков; пауза на чтение; уход облаков и выход в меню.
## Срабатывает: (1) после monk_story_6; (2) после monk_finale_refused — на последней реплике нарратора (или по таймеру чтения).

const VIGNETTE_MAX_ALPHA := 0.38
const VIGNETTE_TWEEN_SEC := 5.0
const WATER_DRAMATIC_TINT_SEC := 10.0
## Умножение modulate слоя: тайлы воды в тайлсете синие — равномерный «розовый» даёт серость; нужен перевес R.
const WATER_TINT_MULT := Color(2.75, 0.36, 0.30, 1.0)
const _DRAMATIC_DONE_FLAG := "post_finale_water_dramatic_done"
const _META_WATER_BASE := &"post_finale_water_base_modulate"
const ENDING_ZOOM := Vector2(0.32, 0.32)
const ENDING_ZOOM_SEC := 4.5
## Пауза с полным экраном заголовка на облаках перед уходом в меню.
const ENDING_TITLE_HOLD_SEC := 5.0
const _ENDING_OVERLAY_SCENE: PackedScene = preload("res://ui/transitions/menu_start_transition_overlay.tscn")
## Лёгкий «рассветный» оттенок облаков (тёплый R, приглушённый B).
const ENDING_CLOUD_TINT_MULT := Color(1.08, 0.92, 0.86, 1.0)
const ENDING_CLOUD_GLOW_TINT := Color(1.0, 0.62, 0.48, 1.0)
## Ветка отказа: если в monk_finale_refused последняя строка — нарратор, короткая пауза и авто-закрытие диалога (иначе игрок жмёт «Далее» на последней реплике персонажа).
const REFUSAL_NARRATOR_READ_SEC := 2.5

var player_movement_locked: bool = false

var _vignette_layer: CanvasLayer
var _vignette_rect: ColorRect
var _ending_started: bool = false
var _water_tween: Tween
var _refusal_narrator_timer_epoch: int = 0
var _refusal_skip_narrator_timer: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_vignette()
	DialogueManager.dialogue_started.connect(_on_dialogue_started_credits)
	DialogueManager.line_changed.connect(_on_dialogue_line_changed_credits)
	DialogueManager.dialogue_ended.connect(_on_dialogue_ended_credits)


## Пока идёт финальная сценка (зум, оверлей с заголовком) — не открывать новые диалоги у монаха/ветерана.
func is_ending_cinematic_active() -> bool:
	return _ending_started


func discard_vignette() -> void:
	if _vignette_layer and is_instance_valid(_vignette_layer):
		_vignette_layer.queue_free()
	_vignette_layer = null
	_vignette_rect = null


func reset_state_for_main_menu() -> void:
	discard_vignette()
	_ending_started = false
	player_movement_locked = false
	_refusal_narrator_timer_epoch += 1
	_refusal_skip_narrator_timer = false


func is_finale_world() -> bool:
	return StoryState.has_flag("story_island_5_cleared")


func blocks_new_enemy_spawns() -> bool:
	return is_finale_world()


func on_story_island_5_boss_won() -> void:
	if not is_finale_world():
		return
	_refresh_finale_bgm_if_needed()
	call_deferred("_apply_after_first_frame_after_boss_kill")
	call_deferred("_clear_all_enemies_soon")


func apply_after_scene_loaded() -> void:
	if not is_finale_world():
		return
	_ensure_vignette()
	_vignette_rect.color.a = VIGNETTE_MAX_ALPHA
	_refresh_finale_bgm_if_needed()
	call_deferred("_apply_after_first_frame")


## После смены локации: вода сразу красная (если уже был эффект на острове 5).
func _apply_after_first_frame() -> void:
	await get_tree().process_frame
	_apply_water_tint_instant_to_scene(get_tree().current_scene)
	if _vignette_rect and _vignette_rect.color.a >= VIGNETTE_MAX_ALPHA * 0.95:
		return
	_show_vignette_target()


## Первый раз после убийства последнего стража: медленное покраснение; дальше — только мгновенно при загрузках.
func _apply_after_first_frame_after_boss_kill() -> void:
	await get_tree().process_frame
	var root := get_tree().current_scene
	if StoryState.has_flag(_DRAMATIC_DONE_FLAG):
		_apply_water_tint_instant_to_scene(root)
	else:
		_apply_water_tint_dramatic_to_scene(root, WATER_DRAMATIC_TINT_SEC)
	if _vignette_rect and _vignette_rect.color.a >= VIGNETTE_MAX_ALPHA * 0.95:
		return
	_show_vignette_target()


func _clear_all_enemies_soon() -> void:
	await get_tree().create_timer(0.8).timeout
	for n in get_tree().get_nodes_in_group("enemy"):
		if is_instance_valid(n):
			n.queue_free()
	for z in get_tree().get_nodes_in_group("encounter_zone"):
		if z is EncounterZone:
			(z as EncounterZone).apply_finale_spawn_shutdown()


func dialogue_maybe_trigger_ending(dialogue_id: String) -> void:
	if _ending_started:
		return
	if dialogue_id != "monk_story_6":
		return
	if not StoryState.has_flag("monk_story_6_done"):
		return
	_start_ending_sequence()


func _on_dialogue_started_credits(sequence: DialogueSequence) -> void:
	if sequence != null and sequence.id == "monk_finale_refused":
		_refusal_skip_narrator_timer = false


func _on_dialogue_line_changed_credits(line: DialogueLine, index: int, line_count: int) -> void:
	if _ending_started:
		return
	if not DialogueManager.is_active():
		return
	var seq := DialogueManager.get_current_sequence()
	if seq == null or seq.id != "monk_finale_refused":
		return
	if line.speaker_id != "narrator" or index != line_count - 1:
		return
	_refusal_narrator_timer_epoch += 1
	var epoch := _refusal_narrator_timer_epoch
	call_deferred("_refusal_narrator_read_then_end", epoch)


func _refusal_narrator_read_then_end(epoch: int) -> void:
	await get_tree().create_timer(REFUSAL_NARRATOR_READ_SEC).timeout
	if epoch != _refusal_narrator_timer_epoch:
		return
	if _refusal_skip_narrator_timer:
		return
	if _ending_started:
		return
	if not DialogueManager.is_active():
		return
	var seq := DialogueManager.get_current_sequence()
	if seq == null or seq.id != "monk_finale_refused":
		return
	DialogueManager.end_dialogue()


func _on_dialogue_ended_credits(sequence: DialogueSequence) -> void:
	if sequence == null or sequence.id != "monk_finale_refused":
		return
	_refusal_skip_narrator_timer = true
	if _ending_started:
		return
	call_deferred("_start_ending_sequence")


func _start_ending_sequence() -> void:
	_ending_started = true
	player_movement_locked = true
	var player := GameManager.current_scene_player
	if player == null or not is_instance_valid(player):
		player = _find_player_fallback()
	var cam := player.get_node_or_null("Camera2D") as Camera2D if player else null
	if cam == null:
		_show_ending_title_then_menu()
		return
	var tw := create_tween()
	tw.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(cam, "zoom", ENDING_ZOOM, ENDING_ZOOM_SEC)
	await tw.finished
	_show_ending_title_then_menu()


func _find_player_fallback() -> Node:
	for p in get_tree().get_nodes_in_group("player"):
		if p and is_instance_valid(p):
			return p
	return null


func _show_ending_title_then_menu() -> void:
	var overlay: Node = _ENDING_OVERLAY_SCENE.instantiate()
	overlay.show_game_title = true
	overlay.cloud_modulate_multiplier = ENDING_CLOUD_TINT_MULT
	overlay.opaque_cloud_glow_tint = ENDING_CLOUD_GLOW_TINT
	get_tree().root.add_child(overlay)
	await overlay.play_cover()
	await get_tree().create_timer(ENDING_TITLE_HOLD_SEC).timeout
	if is_instance_valid(overlay) and overlay.has_method("play_exit"):
		await overlay.play_exit()
	else:
		if is_instance_valid(overlay):
			overlay.queue_free()
	player_movement_locked = false
	GameManager.handle_location_changed(Events.LOCATION.MENU)


func _ensure_vignette() -> void:
	if _vignette_layer:
		return
	_vignette_layer = CanvasLayer.new()
	_vignette_layer.layer = 90
	_vignette_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_vignette_layer)
	_vignette_rect = ColorRect.new()
	_vignette_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_vignette_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vignette_rect.color = Color(0.02, 0.02, 0.06, 0.0)
	_vignette_layer.add_child(_vignette_rect)


func _show_vignette_target() -> void:
	_ensure_vignette()
	if _vignette_rect == null:
		return
	_vignette_rect.color.a = 0.0
	var tw := create_tween()
	tw.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_property(_vignette_rect, "color:a", VIGNETTE_MAX_ALPHA, VIGNETTE_TWEEN_SEC)


func _refresh_finale_bgm_if_needed() -> void:
	SoundManager.refresh_adventure_bgm_state()

func _apply_water_tint_instant_to_scene(root: Node) -> void:
	if root == null or not is_finale_world():
		return
	_refresh_finale_bgm_if_needed()
	if _water_tween and is_instance_valid(_water_tween):
		_water_tween.kill()
		_water_tween = null
	var layers: Array[TileMapLayer] = []
	_collect_water_layers(root, layers)
	for layer in layers:
		if not layer.has_meta(_META_WATER_BASE):
			layer.set_meta(_META_WATER_BASE, layer.modulate)
		var base: Color = layer.get_meta(_META_WATER_BASE) as Color
		layer.modulate = base * WATER_TINT_MULT
	## Смена сцены после финала — драматичный твин только один раз при убийстве стража.
	if is_finale_world():
		StoryState.set_flag(_DRAMATIC_DONE_FLAG, true)


func _apply_water_tint_dramatic_to_scene(root: Node, duration_sec: float) -> void:
	if root == null or not is_finale_world():
		return
	_refresh_finale_bgm_if_needed()
	if _water_tween and is_instance_valid(_water_tween):
		_water_tween.kill()
	var layers: Array[TileMapLayer] = []
	_collect_water_layers(root, layers)
	if layers.is_empty():
		StoryState.set_flag(_DRAMATIC_DONE_FLAG, true)
		return
	_water_tween = create_tween()
	_water_tween.set_parallel(true)
	_water_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	for layer in layers:
		if not layer.has_meta(_META_WATER_BASE):
			layer.set_meta(_META_WATER_BASE, layer.modulate)
		var base: Color = layer.get_meta(_META_WATER_BASE) as Color
		layer.modulate = base
		var c1 := base * WATER_TINT_MULT
		_water_tween.tween_property(layer, "modulate", c1, duration_sec).from(base)
	_water_tween.finished.connect(_on_water_dramatic_tween_finished, CONNECT_ONE_SHOT)


func _on_water_dramatic_tween_finished() -> void:
	_water_tween = null
	StoryState.set_flag(_DRAMATIC_DONE_FLAG, true)


func _collect_water_layers(n: Node, out: Array[TileMapLayer]) -> void:
	if n is TileMapLayer:
		var nm := String(n.name).to_lower()
		## vawe — анимированная пена (res://world/resources/other/vawe.tres, Water Foam.png).
		if nm == "water" or nm == "under_water" or nm == "vawe":
			out.append(n as TileMapLayer)
	for c in n.get_children():
		_collect_water_layers(c, out)

