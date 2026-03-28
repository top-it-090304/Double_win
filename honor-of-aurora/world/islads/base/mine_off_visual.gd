extends TileMapLayer
## Слой «шахта выключена»: виден, пока **никому** из рабочих не назначена добыча руды (один статус на всех, без мигания).

func _process(_delta: float) -> void:
	if Events.current_location != Events.LOCATION.BASE:
		return
	var tree := get_tree()
	if tree == null:
		return
	if tree.get_node_count_in_group(&"ally_pawn") < 1:
		visible = true
		return
	var any_ore_assigned := false
	for n in tree.get_nodes_in_group("ally_pawn"):
		if not n.has_method("is_assigned_to_ore_mining"):
			continue
		if n.is_assigned_to_ore_mining():
			any_ore_assigned = true
			break
	visible = not any_ore_assigned
