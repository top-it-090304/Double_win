extends Area2D

@export var target_location: Events.LOCATION
var player_inside = false  # Флаг, чтобы не вызывать много раз

## Визуальный маркер «К ОСТРОВАМ» — направляет игрока к причалу после прохождения intro-диалога.
## Скрывается, как только игрок впервые войдёт в зону (в этой сессии).
## Появляется только на базе (target_location != BASE) и только когда флаг intro_base_island_done выставлен —
## до этого новичок ведётся к целителю по жёлтым точкам (BreadcrumbTrail), а маркер причала только мешал бы.
const _INTRO_DONE_FLAG := "intro_base_island_done"
var _hint_marker: Label = null
var _hint_tween: Tween = null

func _ready():
	add_to_group("base_patrol_zone")
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	## Если intro закончится в этой же сессии — показать маркер сразу, без перезахода в сцену.
	if not DialogueManager.dialogue_ended.is_connected(_on_dialogue_ended_check_intro):
		DialogueManager.dialogue_ended.connect(_on_dialogue_ended_check_intro)
	# Ждем один кадр, чтобы сцена полностью загрузилась
	await get_tree().process_frame
	_setup_hint_marker_if_eligible()


func _on_dialogue_ended_check_intro(sequence) -> void:
	if sequence == null:
		return
	if sequence.id != "intro_base_island":
		return
	_setup_hint_marker_if_eligible()

func _on_body_entered(body: Node2D) -> void:
	if player_inside:  # Игрок уже внутри, не вызываем повторно
		return

	if GameplayFacade.is_player_body(body):
		player_inside = true
		_remove_hint_marker()
		var hud := GameplayFacade.get_hud(get_tree())
		if hud:
			hud.show_teleport_menu()
			hud.set_target_location(target_location)

func _on_body_exited(body: Node2D) -> void:
	if GameplayFacade.is_player_body(body):
		player_inside = false
		var hud := GameplayFacade.get_hud(get_tree())
		if hud:
			hud.hide_teleport_menu()


func _setup_hint_marker_if_eligible() -> void:
	if _hint_marker != null and is_instance_valid(_hint_marker):
		return
	## Маркер «К ОСТРОВАМ» — только на базе (зона ведёт НА остров, не обратно на базу).
	if target_location == Events.LOCATION.BASE:
		return
	## Не показываем подсказку до прохождения intro — иначе она конкурирует с тропой к целителю.
	if not StoryState.has_flag(_INTRO_DONE_FLAG):
		return
	var lbl := Label.new()
	lbl.name = "TeleportHintMarker"
	lbl.text = "К ОСТРОВАМ ↓"
	lbl.add_theme_font_size_override("font_size", 28)
	lbl.add_theme_color_override("font_color", Color(1.0, 0.94, 0.55))
	lbl.add_theme_color_override("font_outline_color", Color(0.05, 0.04, 0.02))
	lbl.add_theme_constant_override("outline_size", 6)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.size = Vector2(280, 48)
	lbl.position = Vector2(-140, -120)
	lbl.top_level = false
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl.z_index = 50
	add_child(lbl)
	_hint_marker = lbl
	_hint_tween = create_tween().set_loops()
	_hint_tween.tween_property(lbl, "position:y", -132.0, 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_hint_tween.tween_property(lbl, "position:y", -120.0, 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _remove_hint_marker() -> void:
	if _hint_tween != null and _hint_tween.is_valid():
		_hint_tween.kill()
	_hint_tween = null
	if _hint_marker != null and is_instance_valid(_hint_marker):
		_hint_marker.queue_free()
	_hint_marker = null
