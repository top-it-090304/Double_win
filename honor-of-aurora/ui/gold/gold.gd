extends NinePatchRect
 
@onready var gold_label = $GoldLabel  

func _ready() -> void:
	Events.gold_changed.connect(_on_gold_changed)
	_on_gold_changed(SaveManager.gold)

func _on_gold_changed(new_value: int) -> void:
	gold_label.text = str(new_value)
