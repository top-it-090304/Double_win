extends "res://enemies/enemy_base.gd"

func _ready() -> void:
	super._ready()

	speed = 165.0
	health = 620
	attack_damage = 48
	attack_cooldown = 1.55
	enemy_level = 5
	reward_mult = 4.2
	detection_radius = 700.0
	attack_radius = 180.0
