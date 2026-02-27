extends Node
var gold: int = 0
var current_scene_player: Node = null

func _ready() -> void:
	Events.location_changed.connect(handle_location_changed)
	

const location_to_scene = {
	Events.LOCATION.BASE: preload("res://Game/Game_base_islad.tscn"), 
	Events.LOCATION.LVL1: preload("res://Game/Game_level_1.tscn"), 
	Events.LOCATION.LVL2: preload("res://Game/Game_level_2.tscn"), 
	Events.LOCATION.LVL3: preload("res://Game/Game_level_3.tscn"), 
	Events.LOCATION.LVL4: preload("res://Game/Game_level_4.tscn"), 
	Events.LOCATION.LVL5: preload("res://Game/Game_level_5.tscn"), 
	Events.LOCATION.MENU: preload("res://Game/Game_menu.tscn"), 
	
}

func handle_location_changed(new_location: Events.LOCATION):
	teleport_player_to_scene(new_location)
	get_tree().change_scene_to_packed(location_to_scene.get(new_location))
	
func add_gold(amount: int):
	gold += amount
	Events.gold_changed.emit(gold)
	
	
func teleport_player_to_scene(location: Events.LOCATION):
	var current_scene = get_tree().current_scene
	var player = get_tree().get_first_node_in_group("player")
	
	if player and is_instance_valid(player):
		var player_parent = player.get_parent()
		if player_parent:
			player_parent.remove_child(player)
		current_scene_player = player
		
	

	await get_tree().process_frame
	await get_tree().process_frame
	

	var new_scene = get_tree().current_scene
	if not new_scene:
		return
	
	if current_scene_player and is_instance_valid(current_scene_player):
		new_scene.add_child(current_scene_player)
		
		if  "spawn_position" in new_scene:
			current_scene_player.global_position = new_scene.spawn_position


		if location == Events.LOCATION.MENU:
			remove_camera_from_player(current_scene_player)
		else:
			add_camera_to_player(current_scene_player)


func add_camera_to_player(player: Node):
	var camera = player.get_node_or_null("Camera2D")
	if not camera:
		camera = Camera2D.new()
		camera.name = "Camera2D"
		player.add_child(camera)
	
	camera.make_current()

func remove_camera_from_player(player: Node):
	var camera = player.get_node_or_null("Camera2D")
	if camera:
		camera.queue_free()
