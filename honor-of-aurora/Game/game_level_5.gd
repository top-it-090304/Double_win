extends TileMapLayer


const spawn_position = Vector2(600, 740)
func _ready() -> void:
	pass 


func _process(delta: float) -> void:
	pass

func add_player_on_sscene(player: Node2D):
	self.add_child(player)
	
