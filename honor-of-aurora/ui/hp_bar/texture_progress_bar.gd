extends TextureProgressBar

func _ready():
	await get_tree().process_frame
	
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.health_changed.connect(_on_player_health_changed)
		max_value = player.max_health
		value = player.health
	else:
		await get_tree().create_timer(1.0).timeout
		_ready() 

func _on_player_health_changed(current_health):
	value = current_health
	SaveManager.current_health = value
