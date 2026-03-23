extends "res://Game/game_level_spawn_layer.gd"


func _ready() -> void:
	# Стартовая позиция героя — центр тайла лодки (см. GameManager.get_boat_tile_center_global).
	super._ready()
