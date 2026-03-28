extends AnimatedSprite2D
## Дерево с анимацией тайла: рисуется полным циклом; для YSortManager sort_y
## берётся с первого кадра (нижний край не «прыгает» между кадрами).


var _y_sort_bottom_y_cached: float = NAN


func _ready() -> void:
	add_to_group("y_sortable")
	var saved := frame
	frame = 0
	var y := YSortSpriteBounds.max_global_y_from_descendants(self)
	frame = saved
	if not is_nan(y):
		_y_sort_bottom_y_cached = y
	else:
		_y_sort_bottom_y_cached = global_position.y


func get_y_sort_bottom_y() -> float:
	return _y_sort_bottom_y_cached
