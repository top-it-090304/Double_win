extends TextureRect
## Иконка руды с ShaderMaterial: в SLIPPER материал снимается (меньше нагрузка на GPU), при смене пресета восстанавливается.

var _ore_shader_material: Material


func _ready() -> void:
	_ore_shader_material = material
	add_to_group("slipper_visual_material_toggle")
	apply_slipper_visual_material()


func apply_slipper_visual_material() -> void:
	if not is_inside_tree():
		return
	if PerformancePreset.is_slipper_mode(SaveManager):
		material = null
	else:
		material = _ore_shader_material
