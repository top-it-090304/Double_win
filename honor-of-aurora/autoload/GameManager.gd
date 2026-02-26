extends Node

func _ready() -> void:
	Events.location_changed.connect(handle_location_changed)

var gold: int = 0
const location_to_scene = {
	Events.LOCATION.BASE: preload("res://world/islads/base/base_islad.tscn"), 
	Events.LOCATION.LVL1: preload("res://world/islads/levels/level_1.tscn"), 
	Events.LOCATION.LVL2: preload("res://world/islads/levels/level_2.tscn"), 
	Events.LOCATION.LVL3: preload("res://world/islads/levels/level_3.tscn"), 
	Events.LOCATION.LVL4: preload("res://world/islads/levels/level_4.tscn"), 
	Events.LOCATION.LVL5: preload("res://world/islads/levels/level_5.tscn"), 
	
}

func handle_location_changed(location: Events.LOCATION):
	get_tree().change_scene_to_packed(location_to_scene.get(location))
	
func add_gold(amount: int):
	gold += amount
	Events.gold_changed.emit(gold)
	
	
	
	
