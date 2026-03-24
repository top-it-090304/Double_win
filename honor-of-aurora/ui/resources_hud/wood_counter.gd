extends NinePatchRect
## HUD: дерево (улучшение зданий).

@onready var _label: Label = $WoodLabel


func _ready() -> void:
	Events.wood_changed.connect(_on_wood_changed)
	_on_wood_changed(SaveManager.wood_count)


func _on_wood_changed(new_value: int) -> void:
	if _label:
		_label.text = str(new_value)
