class_name HealthSystem
extends Node

var max_health: int = 100
var current_health: int = 100
var regeneration_rate: float = 0.0  # HP в секунду
var regeneration_timer: float = 0.0
var last_damage_time: float = 0.0
var regeneration_delay: float = 3.0

func initialize(starting_health: int) -> void:
	max_health = starting_health
	current_health = max_health

func take_damage(amount: int) -> int:
	if amount <= 0:
		return current_health
	
	current_health = max(current_health - amount, 0)
	last_damage_time = Time.get_ticks_msec() / 1000.0
	regeneration_timer = 0.0
	
	return current_health

func heal(amount: int) -> int:
	if amount <= 0:
		return current_health
	
	current_health = min(current_health + amount, max_health)
	return current_health

func update(delta: float) -> void:
	if regeneration_rate > 0 and current_health < max_health:
		var time_since_damage = (Time.get_ticks_msec() / 1000.0) - last_damage_time
		
		if time_since_damage >= regeneration_delay:
			regeneration_timer += delta
			
			if regeneration_timer >= 1.0:
				var heal_amount = floor(regeneration_rate)
				heal(heal_amount)
				regeneration_timer -= 1.0

func get_health_percentage() -> float:
	if max_health == 0:
		return 0.0
	return float(current_health) / float(max_health)

func is_dead() -> bool:
	return current_health <= 0

func set_regeneration_rate(rate: float) -> void:
	regeneration_rate = max(rate, 0.0)

func set_regeneration_delay(delay: float) -> void:
	regeneration_delay = max(delay, 0.0)
