extends Control

func get_hud():
	return get_tree().get_first_node_in_group("hud")

@export var archer_cost: int = 150
@export var archer_scene: PackedScene = preload("res://ally/archer/arche_baser.tscn")
@export var spawn_offset: Vector2 = Vector2(80, 0)


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_back_pressed() -> void:
	var hud = get_hud()
	hud.hide_castle_menu()


func _on_hire_pressed() -> void:
	_hire_archer()


func _on_upgreat_pressed() -> void:
	pass # Replace with function body.


func _on_info_pressed() -> void:
	pass # Replace with function body.

func _hire_archer() -> void:
	if SaveManager.gold < archer_cost:
		return
	if not archer_scene:
		return
	
	var player = get_tree().get_first_node_in_group("player") as Node2D
	if not player:
		return
	
	var archer = archer_scene.instantiate() as Node2D
	if not archer:
		return
	
	GameManager.add_gold(-archer_cost)
	get_tree().current_scene.add_child(archer)
	archer.global_position = player.global_position + spawn_offset
