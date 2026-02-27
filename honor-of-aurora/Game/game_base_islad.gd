extends TileMapLayer


const spawn_position = Vector2(-600, 750)
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func add_player_on_sscene(player: Node2D):
	self.add_child(player)
	
