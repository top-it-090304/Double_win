extends CharacterBody2D

@export var speed: float = 100.0
@export var cloud_textures: Array[Texture2D] = []

func _ready():
	var random_index = randi() % cloud_textures.size()
	var selected_texture = cloud_textures[random_index]
	$Sprite2D.texture = selected_texture


func _physics_process(delta):
	velocity.x = speed
	move_and_slide()
