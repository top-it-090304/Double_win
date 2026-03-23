extends Node
## Композиция: единая точка учёта HP, сигналов и смерти. Родитель — CharacterUnit.

signal health_changed(current: int, maximum: int)
signal died
signal damage_applied(amount: int)

var max_health: int = 1
var current_health: int = 1


func set_max_and_current(spawn_health: int) -> void:
	var h: int = maxi(1, int(spawn_health))
	max_health = h
	current_health = h
	health_changed.emit(current_health, max_health)


func set_max_health(h: int) -> void:
	max_health = maxi(1, int(h))
	current_health = mini(current_health, max_health)
	health_changed.emit(current_health, max_health)


func set_current_health(h: int) -> void:
	current_health = clampi(int(h), 0, max_health)
	health_changed.emit(current_health, max_health)


func apply_damage(amount: int) -> void:
	var a: int = int(amount)
	if a < 0:
		heal(-a)
		return
	a = maxi(0, a)
	current_health = maxi(0, current_health - a)
	health_changed.emit(current_health, max_health)
	damage_applied.emit(a)
	if current_health <= 0:
		died.emit()


func heal(amount: int) -> void:
	var a: int = maxi(0, int(amount))
	current_health = mini(max_health, current_health + a)
	health_changed.emit(current_health, max_health)
