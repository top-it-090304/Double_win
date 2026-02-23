extends TextureProgressBar

func _ready():
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.health_changed.connect(_on_player_health_changed)
		max_value = player.max_health
		value = player.health
	else:
		push_error("Player not found for health bar")

func _on_player_health_changed(current_health):
	value = current_health
