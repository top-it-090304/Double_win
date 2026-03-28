extends Area2D


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	call_deferred("_check_overlapping")


func _check_overlapping() -> void:
	for body in get_overlapping_bodies():
		if _try_trigger(body):
			return


func _on_body_entered(body: Node2D) -> void:
	_try_trigger(body)


func _try_trigger(body: Node2D) -> bool:
	if not GameplayFacade.is_player_body(body):
		return false
	if DialogueManager.is_active():
		return false
	if not StoryState.has_flag("worker_youth_dead"):
		return false
	if StoryState.has_flag("youth_belongings_found"):
		return false
	if not DialogueRegistry.can_play("youth_belongings"):
		return false
	DialogueRegistry.try_start("youth_belongings")
	return true
