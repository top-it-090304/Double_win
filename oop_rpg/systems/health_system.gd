class_name HealthSystem
extends Node

var max_health: int
var current_health: int

func initialize(starting_health: int) -> void:
    max_health = starting_health
    current_health = max_health

func take_damage(amount: int) -> int:
    current_health = max(current_health - amount, 0)
    return current_health

func heal(amount: int) -> int:
    current_health = min(current_health + amount, max_health)
    return current_health

func get_health_percentage() -> float:
    return float(current_health) / float(max_health)
