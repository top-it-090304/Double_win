extends Node2D

enum BuildingColor {
	BLACK,
	BLUE,
	RED,
	PURPLE,
	YELLOW
}

const COLOR_FOLDERS := {
	BuildingColor.BLACK: "Black Buildings",
	BuildingColor.BLUE: "Blue Buildings",
	BuildingColor.RED: "Red Buildings",
	BuildingColor.PURPLE: "Purple Buildings",
	BuildingColor.YELLOW: "Yellow Buildings"
}

@export var building_type: String = "Archery"
@export var current_color: BuildingColor = BuildingColor.BLACK

@onready var sprite = $Sprite

func _ready():
	update_texture()

func update_texture() -> bool:
	var color_folder = COLOR_FOLDERS[current_color]
	var texture_path = "res://Asets/Unit_pack/Buildings/%s/%s.png" % [color_folder, building_type]
	
	if ResourceLoader.exists(texture_path):
		sprite.texture = load(texture_path)
		return true
	
	return false

func upgrade_building() -> bool:
	if current_color < BuildingColor.YELLOW:
		current_color = current_color + 1
		return update_texture()
	return false
