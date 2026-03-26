extends NinePatchRect
## HUD: руда. Icon_07; цвет через ore_icon_gold.gdshader (гасит зелёный, золотой оттенок).

@onready var _label: Label = $OreLabel


func _ready() -> void:
	Events.ore_changed.connect(_on_ore_changed)
	_on_ore_changed(SaveManager.ore_count)


func _on_ore_changed(new_value: int) -> void:
	if _label:
		_label.text = str(new_value)
