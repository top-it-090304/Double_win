extends Node2D
## Минимальный тест лесоруба: герой + пешка + дерево + зона + навигация + HUD.
## Запуск: F6 на `test_wood_worker_minimal.tscn`.
## Пешка должна быть в группе `squad_member` — иначе атака рядом с ней не откроет меню приказов (так вешает GameManager).
## Нужен HUD с группой `hud` — иначе `GameplayFacade.get_hud` вернёт null.

func _ready() -> void:
	Events.current_location = Events.LOCATION.BASE
	var player := get_node_or_null("Player") as Node2D
	if player != null:
		GameManager.current_scene_player = player
	var pawn := get_node_or_null("PawnBase") as Node
	if pawn != null:
		pawn.add_to_group("squad_member")
	call_deferred("_apply_test_setup")


func _apply_test_setup() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	SquadOrders.set_mode(SquadOrders.Mode.COMBAT)
	var pawn := get_node_or_null("PawnBase") as Node
	if pawn != null and pawn.has_method("set_worker_job_from_dialogue"):
		pawn.call("set_worker_job_from_dialogue", "wood")
