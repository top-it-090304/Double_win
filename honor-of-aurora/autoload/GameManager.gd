extends Node

func _ready() -> void:
	Events.location_changed.connect(handle_location_changed)

var gold: int = 0
const location_to_scene = {
	Events.LOCATION.BASE: preload("res://Game/Game_base_islad.tscn"), 
	Events.LOCATION.LVL1: preload("res://Game/Game_level_1.tscn"), 
	Events.LOCATION.LVL2: preload("res://Game/Game_level_2.tscn"), 
	Events.LOCATION.LVL3: preload("res://Game/Game_level_3.tscn"), 
	Events.LOCATION.LVL4: preload("res://Game/Game_level_4.tscn"), 
	Events.LOCATION.LVL5: preload("res://Game/Game_level_5.tscn"), 
	Events.LOCATION.MENU: preload("res://Game/Game_menu.tscn"), 
	
}

func handle_location_changed(location: Events.LOCATION):
	get_tree().change_scene_to_packed(location_to_scene.get(location))
	
func add_gold(amount: int):
	gold += amount
	Events.gold_changed.emit(gold)
	
	
	
	
