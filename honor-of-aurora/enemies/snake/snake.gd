extends "res://enemies/enemy_base.gd"

func _ready():
	super._ready()  
	
   
	speed = 150.0  
	health = 100   
	attack_damage = 10 
	enemy_level = 1 
	detection_radius = 700.0  
	attack_radius = 160.0
