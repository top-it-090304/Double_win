extends Area2D
## Зона лесоруба: одно активное дерево на зону; спавн при отсутствии готовых деревьев на острове.

const WOOD_JOB_TREE_SCENE := preload("res://objects/wood_zone/wood_zone_tree.tscn")

var _active_tree: Node2D = null


func _ready() -> void:
	add_to_group("wood_zone")


func try_spawn_job_tree() -> Node2D:
	if _active_tree != null and is_instance_valid(_active_tree):
		return null
	var tree: Node2D = WOOD_JOB_TREE_SCENE.instantiate()
	var parent := get_parent()
	if parent == null:
		tree.queue_free()
		return null
	parent.add_child(tree)
	tree.global_position = global_position + _random_offset_in_shape()
	_active_tree = tree
	tree.tree_exiting.connect(_on_tree_exiting, CONNECT_ONE_SHOT)
	return tree


func _on_tree_exiting() -> void:
	_active_tree = null


func _random_offset_in_shape() -> Vector2:
	var cs := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if cs == null or cs.shape == null:
		return Vector2.ZERO
	var r := 40.0
	if cs.shape is CircleShape2D:
		r = (cs.shape as CircleShape2D).radius * 0.55
	return Vector2(randf_range(-r, r), randf_range(-r, r))
