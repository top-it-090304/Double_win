extends Area2D

@export var target_location: Events.LOCATION
var player_inside = false  # Флаг, чтобы не вызывать много раз

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	# Ждем один кадр, чтобы сцена полностью загрузилась
	await get_tree().process_frame

func _on_body_entered(body: Node2D) -> void:
	if player_inside:  # Игрок уже внутри, не вызываем повторно
		return
		
	if GameplayFacade.is_player_body(body):
		player_inside = true
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
