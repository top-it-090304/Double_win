extends Node

## Сюжетные флаги хранятся в SaveManager.story_flags и попадают в сохранение.


func has_flag(key: String) -> bool:
	return bool(SaveManager.story_flags.get(key, false))


func set_flag(key: String, value: Variant = true) -> void:
	SaveManager.story_flags[key] = value
	SaveManager.save_game()


func clear_flag(key: String) -> void:
	SaveManager.story_flags.erase(key)
	SaveManager.save_game()
