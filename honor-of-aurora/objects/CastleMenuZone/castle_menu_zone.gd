extends Area2D

func _on_body_entered(body):
	var hud = get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("show_teleport_menu"):
		hud.show_castle_menu()
