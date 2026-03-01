extends Control

func get_hud():
	return get_tree().get_first_node_in_group("hud")


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
	pass # Replace with function body.


func _on_upgreat_pressed() -> void:
	pass # Replace with function body.


func _on_info_pressed() -> void:
	pass # Replace with function body.
