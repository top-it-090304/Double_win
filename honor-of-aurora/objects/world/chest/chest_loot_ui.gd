class_name ChestLootUi
extends Object

static var _chest_popup_open: bool = false


static func set_chest_popup_open(open: bool) -> void:
	_chest_popup_open = open


static func is_chest_popup_open() -> bool:
	return _chest_popup_open


static func show_loot_panel(tree: SceneTree, loot: Dictionary) -> void:
	if tree == null:
		return
	var root: Window = tree.root
	if root == null:
		return
	var packed: PackedScene = preload("res://ui/chest/chest_loot_panel.tscn")
	var panel: Node = packed.instantiate()
	if panel == null:
		return
	root.add_child(panel)
	if panel.has_method("setup_from_loot"):
		panel.call("setup_from_loot", loot)
