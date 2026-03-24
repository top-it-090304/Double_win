extends Node2D
## Здание на базе: текстура по фракции и апгрейд за золото.

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
@export var upgrade_cost_step: int = 300

@onready var sprite = $Sprite

func _ready() -> void:
	var saved_tier: int = SaveManager.get_building_tier(building_type)
	current_color = clampi(saved_tier, 0, int(BuildingColor.YELLOW)) as BuildingColor
	update_texture()

func update_texture() -> bool:
	var color_folder = COLOR_FOLDERS[current_color]
	var texture_path = "res://Asets/Unit_pack/Buildings/%s/%s.png" % [color_folder, building_type]
	
	if ResourceLoader.exists(texture_path):
		sprite.texture = load(texture_path)
		return true
	
	return false

func upgrade_building() -> bool:
	if current_color >= BuildingColor.YELLOW:
		return false
	
	var cost := BalanceConfig.get_building_upgrade_step() * (current_color + 1)
	var wood_cost := BalanceConfig.get_building_upgrade_wood_cost(int(current_color))
	if not GameplayFacade.try_spend_gold(cost):
		return false
	if not GameplayFacade.try_spend_wood(wood_cost):
		GameManager.add_gold(cost)
		return false
	current_color = current_color + 1
	SaveManager.set_building_tier(building_type, int(current_color))
	SaveManager.save_game()
	return update_texture()
