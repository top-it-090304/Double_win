extends "res://enemies/enemy_base.gd"

func _ready():
	super._ready()  
	
   
	speed = 130.0  
	health = 150   
	attack_damage = 25 
	enemy_level = 1 
	detection_radius = 700.0
	attack_radius = 96.0
