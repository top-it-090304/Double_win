extends Node

## Только выход из главного меню в игру. Явные шаги без Callable — GameManager вызывает run_cover / run_exit по очереди.

const OVERLAY_SCENE := preload("res://ui/transitions/menu_start_transition_overlay.tscn")


func run_cover() -> Node:
	var overlay: Node = OVERLAY_SCENE.instantiate()
	get_tree().root.add_child(overlay)
	await overlay.play_cover()
	return overlay


func run_exit(overlay: Node) -> void:
	if is_instance_valid(overlay) and overlay.has_method("play_exit"):
		await overlay.play_exit()
