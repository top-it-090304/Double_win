extends Node2D
## NPC у причала: первый контакт и набор в отряд (флаги worker_youth_*).
## Диалог по «атаке» рядом — через try_open_interact_dialog (см. worrier_base).

## Макс. дистанция до героя для открытия диалога (как запас к InteractArea).
const MAX_INTERACT_DISTANCE := 152.0

@onready var _area: Area2D = $InteractArea
@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	add_to_group("dock_youth_interact")
	if StoryState.has_flag("worker_youth_dead"):
		remove_from_group("dock_youth_interact")
		queue_free()
		return
	if StoryState.has_flag("worker_youth_recruited"):
		visible = false
		return
	if _sprite and _sprite.sprite_frames:
		if _sprite.sprite_frames.has_animation(&"idle"):
			_sprite.play(&"idle")
		elif _sprite.sprite_frames.has_animation(&"idle_pickaxe"):
			_sprite.play(&"idle_pickaxe")
	if _area:
		_area.body_entered.connect(_on_body_entered)


func _is_player_in_interact_range(player: Node2D) -> bool:
	if player == null or not is_instance_valid(player):
		return false
	if global_position.distance_to(player.global_position) <= MAX_INTERACT_DISTANCE:
		return true
	if _area != null and is_instance_valid(_area) and _area.overlaps_body(player):
		return true
	return false


## Вызывается из worrier_base при нажатии «attack» рядом (как у целителя).
func try_open_interact_dialog() -> bool:
	if DialogueManager.is_active():
		return false
	if not visible:
		return false
	if StoryState.has_flag("worker_youth_dead"):
		return false
	if StoryState.has_flag("worker_youth_recruited"):
		return false
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if not _is_player_in_interact_range(player):
		return false
	if not StoryState.has_flag("worker_youth_intro_done"):
		return DialogueRegistry.try_start("dock_worker_youth_intro", false)
	if not StoryState.has_flag("worker_youth_recruited") and not StoryState.has_flag("worker_youth_refused"):
		return DialogueRegistry.try_start("dock_worker_youth_recruit", false)
	return false


func _on_body_entered(body: Node2D) -> void:
	if not GameplayFacade.is_player_body(body):
		return
	if DialogueManager.is_active():
		return
	if not StoryState.has_flag("worker_youth_intro_done"):
		DialogueRegistry.try_start("dock_worker_youth_intro", false)
	elif not StoryState.has_flag("worker_youth_recruited") and not StoryState.has_flag("worker_youth_refused"):
		DialogueRegistry.try_start("dock_worker_youth_recruit", false)
