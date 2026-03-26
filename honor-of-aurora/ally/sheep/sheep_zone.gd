@tool
extends Area2D
## Маркер пастбища: случайная точка внутри коллайдера для спавна овцы. В редакторе и в игре не рисуется.

func _ready() -> void:
	add_to_group("sheep_spawn_zone")
	monitoring = false
	monitorable = false
	visible = false
