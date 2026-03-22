extends Control

func get_hud():
	return get_tree().get_first_node_in_group("hud")

@export var archer_cost: int = 150
@export var archer_scene: PackedScene = preload("res://ally/archer/arche_baser.tscn")
@export var spawn_offset: Vector2 = Vector2(80, 0)
@export var building_upgrade_radius: float = 600.0


func _on_back_pressed() -> void:
	SoundManager.play_ui_button()
	var hud = get_hud()
	hud.hide_castle_menu()


func _on_hire_pressed() -> void:
	SoundManager.play_ui_button()
	_hire_archer()


func _on_upgreat_pressed() -> void:
	SoundManager.play_ui_button()
	_upgrade_buildings_near_castle()


func _on_info_pressed() -> void:
	SoundManager.play_ui_button()
	_show_castle_info()

func _hire_archer() -> void:
	if SaveManager.gold < archer_cost:
		return
	if not archer_scene:
		return
	
	var player = get_tree().get_first_node_in_group("player") as Node2D
	if not player:
		return
	
	var archer = archer_scene.instantiate() as Node2D
	if not archer:
		return
	
	SaveManager.archer_count += 1
	GameManager.add_gold(-archer_cost)
	var avoid: Array[Vector2] = [player.global_position]
	for node in get_tree().get_nodes_in_group("ally"):
		if node is Node2D:
			avoid.append((node as Node2D).global_position)
	var positions := GameManager.pick_archer_spawn_positions(get_tree().current_scene, 1, avoid)
	get_tree().current_scene.add_child(archer)
	archer.global_position = positions[0]

func _upgrade_buildings_near_castle() -> void:
	var player = get_tree().get_first_node_in_group("player") as Node2D
	if not player:
		return
	
	for building in get_tree().current_scene.get_children():
		if not building.has_method("upgrade_building"):
			continue
		if building.global_position.distance_to(player.global_position) > building_upgrade_radius:
			continue
		building.upgrade_building()

func _show_castle_info() -> void:
	var info_panel := get_node_or_null("InfoPanel") as Control
	if info_panel:
		info_panel.visible = not info_panel.visible
