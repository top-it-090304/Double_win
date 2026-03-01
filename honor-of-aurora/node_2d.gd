extends Node2D
@onready var building = $Building


func _on_button_pressed() -> void:
	building.upgrade_building()
