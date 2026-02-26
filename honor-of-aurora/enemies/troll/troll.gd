extends "res://enemies/enemy_base.gd"

func _ready():
	super()  
	
   
	speed = 150.0  
	health = 200   
	attack_damage = 35 
	gold_reward = 2000
	detection_radius = 700.0  
	attack_radius = 200.0
