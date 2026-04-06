extends TextureProgressBar

func _ready() -> void:
	_try_connect_player()


func _try_connect_player() -> void:
	var tree := get_tree()
	if tree == null:
		return
	await tree.process_frame
	if not is_inside_tree():
		return
	tree = get_tree()
	if tree == null:
		return
	var player := tree.get_first_node_in_group("player")
	if player:
		if not player.health_changed.is_connected(_on_player_health_changed):
			player.health_changed.connect(_on_player_health_changed)
		_sync_from_player(player)
		return
	await tree.create_timer(1.0).timeout
	if is_inside_tree():
		_try_connect_player()


func _on_player_health_changed(current_health) -> void:
	if not is_inside_tree():
		return
	var tree := get_tree()
	if tree == null:
		return
	var p := tree.get_first_node_in_group("player")
	if p:
		_sync_from_player(p)
	else:
		value = current_health


func _sync_from_player(player: Node) -> void:
	if not is_inside_tree() or player == null or not is_instance_valid(player):
		return
	max_value = player.max_health
	value = player.health
