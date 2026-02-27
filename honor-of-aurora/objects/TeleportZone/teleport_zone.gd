extends Area2D

@export var target_location: Events.LOCATION
var player_inside = false  # Флаг, чтобы не вызывать много раз

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	# Ждем один кадр, чтобы сцена полностью загрузилась
	await get_tree().process_frame

func _on_body_entered(body):
	if player_inside:  # Игрок уже внутри, не вызываем повторно
		return
		
	if body.is_in_group("player"):
		player_inside = true
		var hud = get_tree().get_first_node_in_group("hud")
		if hud and hud.has_method("show_teleport_menu"):
			hud.show_teleport_menu()
			if hud.has_method("set_target_location"):
				hud.set_target_location(target_location)

func _on_body_exited(body):
	if body.is_in_group("player"):
		player_inside = false
		var hud = get_tree().get_first_node_in_group("hud")
		if hud and hud.has_method("hide_teleport_menu"):
			hud.hide_teleport_menu()
