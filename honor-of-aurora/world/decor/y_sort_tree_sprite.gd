extends Sprite2D
## Спрайт дерева после миграции с тайлмапа: участвует в YSortManager.


func _ready() -> void:
	add_to_group("y_sortable")


func get_y_sort_bottom_y() -> float:
	var y := YSortSpriteBounds.max_global_y_from_descendants(self)
	if not is_nan(y):
		return y
	return global_position.y
