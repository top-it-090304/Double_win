extends "res://Game/game_level_spawn_layer.gd"
## База: стражи-лучники стоят на месте; мини HP над юнитами скрыты (у героя отдельный HUD).

const _WorldMiniHpBarScript := preload("res://ui/hp_bar/world_mini_hp_bar.gd")


func _ready() -> void:
	# Стартовая позиция героя — центр тайла лодки (см. GameManager.get_boat_tile_center_global).
	super._ready()
	var tree := get_tree()
	tree.node_added.connect(_on_tree_node_added_hide_unit_hp)
	# После кадров GameManager добавляет героя и отряд — убираем бары со всех юнитов, кроме игрока.
	await tree.process_frame
	await tree.process_frame
	await tree.process_frame
	_hide_mini_hp_bars_on_all_non_player_units()


func _exit_tree() -> void:
	var tree := get_tree()
	if tree and tree.node_added.is_connected(_on_tree_node_added_hide_unit_hp):
		tree.node_added.disconnect(_on_tree_node_added_hide_unit_hp)


func _on_tree_node_added_hide_unit_hp(node: Node) -> void:
	if not is_inside_tree() or not is_ancestor_of(node):
		return
	if not (node is CharacterBody2D):
		return
	call_deferred("_apply_hide_unit_hp_after_ready", node)


func _apply_hide_unit_hp_after_ready(node: Node) -> void:
	if not is_instance_valid(node) or not is_ancestor_of(node):
		return
	if node.is_in_group("player"):
		return
	await node.ready
	if not is_instance_valid(node) or not is_ancestor_of(node):
		return
	if node.is_in_group("player"):
		return
	if not node.is_in_group("character_unit"):
		return
	_remove_world_mini_hp_bar_children(node)


func _hide_mini_hp_bars_on_all_non_player_units() -> void:
	var root := get_tree().current_scene
	if root == null:
		return
	for node in get_tree().get_nodes_in_group("character_unit"):
		if not root.is_ancestor_of(node):
			continue
		if node.is_in_group("player"):
			continue
		_remove_world_mini_hp_bar_children(node)


func _remove_world_mini_hp_bar_children(unit: Node) -> void:
	for c in unit.get_children():
		if c is Control and c.get_script() == _WorldMiniHpBarScript:
			c.queue_free()
