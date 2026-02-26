extends Node

var gold: int = 0

func handle_location_changed(location: Events.LOCATION):
	pass
	
func add_gold(amount: int):
	gold += amount
	Events.gold_changed.emit(gold)
	
	
	
