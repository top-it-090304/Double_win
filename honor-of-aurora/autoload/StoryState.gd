extends Node

## Сюжетные флаги хранятся в SaveManager.story_flags и попадают в сохранение.


func has_flag(key: String) -> bool:
	return bool(SaveManager.story_flags.get(key, false))


## Без сохранения — вызывающий обязан вызвать `SaveManager.save_game(true)` (например пакетная выдача наград).
func write_flag(key: String, value: Variant = true) -> void:
	SaveManager.story_flags[key] = value


func set_flag(key: String, value: Variant = true) -> void:
	SaveManager.story_flags[key] = value
	SaveManager.save_game(true)
	## Сразу после выбора в диалоге: юноша должен появиться на базе без перезагрузки сцены.
	if bool(value) and (key == "worker_youth_works_on_base" or key == "worker_youth_recruited"):
		var tree := Engine.get_main_loop() as SceneTree
		if tree and tree.root:
			var gm := tree.root.get_node_or_null("/root/GameManager")
			if gm and gm.has_method("ensure_youth_companion_on_base_scene"):
				gm.call_deferred("ensure_youth_companion_on_base_scene")


func clear_flag(key: String) -> void:
	SaveManager.story_flags.erase(key)
	SaveManager.save_game(true)
