extends TileMapLayer

const spawn_position = Vector2(-600, 750)


func add_player_on_sscene(player: Node2D) -> void:
	add_child(player)
	
