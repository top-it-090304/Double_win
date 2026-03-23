extends TileMapLayer
## Общий корень островных сцен: точка появления героя и добавление игрока в дерево.


@export var spawn_position: Vector2 = Vector2(600, 740)


func _ready() -> void:
	pass


func get_spawn_position() -> Vector2:
	return spawn_position


func add_player_on_sscene(player: Node2D) -> void:
	add_child(player)
