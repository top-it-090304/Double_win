extends "res://enemies/enemy_base.gd"

func _ready():
	super._ready()  
	
   
	speed = 150.0  
	health = 200   
	attack_damage = 35 
	enemy_level = 2 
	detection_radius = 700.0  
	attack_radius = 160.0
