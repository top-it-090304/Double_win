extends AnimatedSprite2D
## Дерево/куст с тайловой анимацией: YSortManager спрашивает нижний край в мировых координатах.
## Нельзя кешировать абсолютный Y в _ready — после загрузки сцены global_transform родителя
## может стать финальным позже, и тогда z_index считается от устаревшего ключа (кажется сдвигом на высоту спрайта).
## Сортировка по кадру 0 без присвоения frame — иначе при частом YSort (макс. режим) сбрасывается анимация.


func _ready() -> void:
	add_to_group("y_sortable")
	add_to_group("wind_decor_sprite")
	call_deferred("apply_wind_speed_from_settings")


func apply_wind_speed_from_settings() -> void:
	if not is_inside_tree():
		return
	## Один темп ветра на всех пресетах: 1.0 давало слишком быстрый цикл на среднем/максимальном (0.35 — эталон с минимального).
	speed_scale = 0.35


func get_y_sort_bottom_y() -> float:
	var y := YSortSpriteBounds.max_global_y_for_animated_sprite_at_frame(self, animation, 0)
	if not is_nan(y):
		return y
	return global_position.y
