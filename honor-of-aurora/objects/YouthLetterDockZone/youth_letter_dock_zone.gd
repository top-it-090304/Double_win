extends Area2D
## Зона у лодки (спавн героя на базе): при ожидании каравана — окно «отправить письмо Мирона или нет».

const _DOCK_OFFER_PANEL := preload("res://objects/YouthLetterDockZone/youth_letter_dock_offer_panel.tscn")

var _player_overlaps: bool = false
var _offered_this_visit: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	if not Events.caravan_pending_changed.is_connected(_on_caravan_pending_changed):
		Events.caravan_pending_changed.connect(_on_caravan_pending_changed)
	monitoring = true
	monitorable = false
	collision_layer = 0
	collision_mask = 10
	## Зона создаётся deferred после героя: без этого body_entered не приходит, если игрок уже внутри.
	call_deferred("_sync_overlap_after_physics")


func _sync_overlap_after_physics() -> void:
	await get_tree().physics_frame
	if not is_inside_tree():
		return
	for b in get_overlapping_bodies():
		_on_body_entered(b)


func _exit_tree() -> void:
	if Events.caravan_pending_changed.is_connected(_on_caravan_pending_changed):
		Events.caravan_pending_changed.disconnect(_on_caravan_pending_changed)


func _on_caravan_pending_changed(pending: bool) -> void:
	if pending:
		_offered_this_visit = false
	call_deferred("_try_open_dock_offer")


func _on_body_entered(body: Node) -> void:
	if not GameplayFacade.is_player_body(body):
		return
	_player_overlaps = true
	call_deferred("_try_open_dock_offer")


func _on_body_exited(body: Node) -> void:
	if not GameplayFacade.is_player_body(body):
		return
	_player_overlaps = false
	_offered_this_visit = false


func _try_open_dock_offer() -> void:
	if not _player_overlaps:
		return
	if Events.current_location != Events.LOCATION.BASE:
		return
	if not SaveManager.caravan_pending:
		return
	if _offered_this_visit:
		return
	if DialogueManager.is_active():
		return
	if not DialogueRegistry.can_play("youth_letter_sent"):
		return
	_offered_this_visit = true
	_show_confirmation()


func _show_confirmation() -> void:
	var panel: Control = _DOCK_OFFER_PANEL.instantiate() as Control
	if panel == null:
		return
	panel.name = "YouthLetterDockOffer"
	get_tree().root.add_child(panel)
	panel.offer_confirmed.connect(
		func() -> void:
			if DialogueManager.is_active():
				return
			DialogueRegistry.try_start("youth_letter_sent", false)
	)
	panel.offer_canceled.connect(func() -> void: _offered_this_visit = false)
	panel.call_deferred(
		"setup",
		"У причала",
		"Казённый борт у причала. Отправить на материк прощальное письмо мальчика — в свёртке, как он просил?",
		"Отправить письмо",
		"Не сейчас"
	)
