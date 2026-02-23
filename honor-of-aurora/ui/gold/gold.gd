extends NinePatchRect
 
@onready var gold_label = $GoldLabel  

func _ready():
	GameManager.connect("gold_changed", _on_gold_changed)
	
	_on_gold_changed(GameManager.gold)

func _on_gold_changed(new_value):
	gold_label.text = str(new_value)
