extends TileMapLayer
## Общий корень островных сцен: точка появления героя и добавление игрока в дерево.


@export var spawn_position: Vector2 = Vector2(600, 740)


func _ready() -> void:
	pass


## Узлы боссов из .tscn (группа BOSS + story_island): при повторной загрузке уровня после победы не должны появляться снова.
func _remove_defeated_scene_bosses_for_island(island_index: int) -> void:
	for c in get_children():
		if not (c is Node):
			continue
		var n := c as Node
		if not n.is_in_group("BOSS"):
			continue
		if not ("story_island" in n):
			continue
		if int(n.get("story_island")) != island_index:
			continue
		n.queue_free()


func get_spawn_position() -> Vector2:
	return spawn_position


func add_player_on_sscene(player: Node2D) -> void:
	add_child(player)
