extends "res://enemies/enemy_base.gd"

func _ready():
	super()  
	
   
	speed = 150.0  
	health = 1000   
	attack_damage = 80 
	gold_reward = 1000 
	detection_radius = 700.0  
	attack_radius = 500.0
