extends Control


func _ready() -> void:
	## Autoplay до полного входа в дерево на GLES (Android Compatibility) даёт ERROR
	## «!is_inside_tree()» в AnimationPlayer::can_process и может вести к вылету.
	call_deferred("_start_float_animation")


func _start_float_animation() -> void:
	if not is_inside_tree():
		return
	var ap := get_node_or_null("AnimationPlayer") as AnimationPlayer
	if ap == null or not ap.is_inside_tree():
		return
	ap.play(&"float_up")


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == &"float_up":
		queue_free()
