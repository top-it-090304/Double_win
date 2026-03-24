extends NinePatchRect
## HUD: мясо (лимит воинов).

@onready var _label: Label = $MeatLabel


func _ready() -> void:
	Events.meat_changed.connect(_on_meat_changed)
	_on_meat_changed(SaveManager.meat_count)


func _on_meat_changed(new_value: int) -> void:
	if _label:
		_label.text = str(new_value)
