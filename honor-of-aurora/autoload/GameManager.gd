extends Node

var gold: int = 0
signal gold_changed

func reset_gold(amount: int):
	gold = amount
	emit_signal("gold_changed", gold)
	
func add_gold(amount: int):
	gold += amount
	emit_signal("gold_changed", gold)
