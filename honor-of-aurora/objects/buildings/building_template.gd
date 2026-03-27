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
## Линия «ног» для Y-сортировки по вертикали спрайта: 1 = низ картинки, <1 — выше (ворота/калитки на арте).
@export_range(0.0, 1.0, 0.01) var y_sort_ground_ratio: float = 1.0
@export var y_sort_bottom_pixel_offset: float = 0.0

@onready var sprite: Sprite2D = $Sprite

func _ready() -> void:
	add_to_group("y_sortable")
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
	var ore_cost := BalanceConfig.get_building_upgrade_ore_cost(int(current_color))
	if not GameplayFacade.try_spend_gold_plus_ore(cost, ore_cost):
		return false
	if not GameplayFacade.try_spend_wood_or_ore(wood_cost):
		return false
	current_color = current_color + 1
	SaveManager.set_building_tier(building_type, int(current_color))
	SaveManager.save_game()
	var ok := update_texture()
	GameManager.refresh_all_companion_progression()
	return ok


func get_y_sort_bottom_y() -> float:
	if sprite == null or sprite.texture == null:
		return global_position.y + y_sort_bottom_pixel_offset
	var tex_h := float(sprite.texture.get_height())
	var sy := absf(sprite.global_scale.y)
	var h := tex_h * sy
	var cy := sprite.global_position.y
	var ratio := clampf(y_sort_ground_ratio, 0.0, 1.0)
	return cy + h * (ratio - 0.5) + y_sort_bottom_pixel_offset
