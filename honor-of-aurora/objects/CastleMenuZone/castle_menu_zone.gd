extends Area2D


func _on_body_entered(body: Node2D) -> void:
	if not GameplayFacade.is_player_body(body):
		return
	var hud := GameplayFacade.get_hud(get_tree())
	if hud:
		hud.show_castle_menu()
