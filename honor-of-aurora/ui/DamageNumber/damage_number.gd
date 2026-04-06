extends Control

## Завершение анимации: отключаем плеер и удаляем узел отложенно (меньше гонок с AnimationPlayer / is_inside_tree).


func _ready() -> void:
	## Autoplay до полного входа в дерево на GLES (Android Compatibility) даёт ERROR
	## «!is_inside_tree()» в AnimationPlayer::can_process и может вести к вылету.
	call_deferred("_start_float_animation")


func _damage_number_anim_speed_scale() -> float:
	## «На тапке»: быстрее проигрываем float_up — короче жизнь узла и меньше кадров обработки плеера.
	if PerformancePreset.is_slipper_mode(SaveManager):
		return 1.45
	return 1.0


func _start_float_animation() -> void:
	if not is_instance_valid(self) or not is_inside_tree():
		return
	var ap := get_node_or_null("AnimationPlayer") as AnimationPlayer
	if ap == null or not is_instance_valid(ap) or not ap.is_inside_tree():
		return
	ap.active = true
	ap.speed_scale = _damage_number_anim_speed_scale()
	ap.play(&"float_up")


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name != &"float_up":
		return
	if not is_instance_valid(self) or not is_inside_tree():
		return
	var ap := get_node_or_null("AnimationPlayer") as AnimationPlayer
	if ap != null and is_instance_valid(ap) and ap.is_inside_tree():
		var fin := Callable(self, "_on_animation_player_animation_finished")
		if ap.animation_finished.is_connected(fin):
			ap.animation_finished.disconnect(fin)
		ap.stop()
		ap.active = false
		ap.process_mode = Node.PROCESS_MODE_DISABLED
	call_deferred(&"queue_free")
