extends Node
## Показ окна чтения грамоты Короны поверх HUD (не DialogueWindow).


const _PANEL_SCENE := preload("res://ui/crown_patent/crown_patent_reading.tscn")

var _open: Node = null


func try_show_for_title_index(tier: int, on_closed: Callable) -> bool:
	if tier < 1:
		return false
	var tree := get_tree()
	if tree == null:
		return false
	var hud: Node = tree.get_first_node_in_group("hud")
	if hud == null:
		return false
	if _open != null and is_instance_valid(_open):
		return false
	if tier >= BalanceConfig.CROWN_TITLES.size():
		return false
	var raw: Variant = BalanceConfig.CROWN_TITLES[tier].get("patent_lines", null)
	if not (raw is Array) or (raw as Array).is_empty():
		return false

	var panel: Control = _PANEL_SCENE.instantiate() as Control
	if panel == null:
		return false
	_open = panel
	panel.tree_exiting.connect(_on_panel_tree_exiting)
	hud.add_child(panel)
	if panel.has_method("setup_patent"):
		panel.call("setup_patent", tier, on_closed)
	return true


func _on_panel_tree_exiting() -> void:
	_open = null
