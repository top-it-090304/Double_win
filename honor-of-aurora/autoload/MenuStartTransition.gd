extends Node

## Меню → игра и телепорт. GameManager вызывает run_cover / run_exit по очереди.

const OVERLAY_SCENE := preload("res://ui/transitions/menu_start_transition_overlay.tscn")


func run_cover(with_title: bool = true) -> Node:
	var overlay: Node = OVERLAY_SCENE.instantiate()
	overlay.show_game_title = with_title
	get_tree().root.add_child(overlay)
	await overlay.play_cover()
	return overlay


func run_exit(overlay: Node) -> void:
	if is_instance_valid(overlay) and overlay.has_method("play_exit"):
		await overlay.play_exit()
