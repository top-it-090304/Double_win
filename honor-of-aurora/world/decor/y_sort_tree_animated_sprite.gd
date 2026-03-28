extends AnimatedSprite2D
## Дерево/куст с тайловой анимацией: YSortManager спрашивает нижний край в мировых координатах.
## Нельзя кешировать абсолютный Y в _ready — после загрузки сцены global_transform родителя
## может стать финальным позже, и тогда z_index считается от устаревшего ключа (кажется сдвигом на высоту спрайта).
## Для стабильности между кадрами анимации сортировка всегда по кадру 0 текущего клипа.


func _ready() -> void:
	add_to_group("y_sortable")


func get_y_sort_bottom_y() -> float:
	var saved_frame := frame
	frame = 0
	var y := YSortSpriteBounds.max_global_y_from_descendants(self)
	frame = saved_frame
	if not is_nan(y):
		return y
	return global_position.y
