extends Node
## Погода: счётчик телепортов из меню причала.
## Дождь один «ход» за цикл: активен, пока число телепортов кратно 5 (5, 10, 15…); после следующего телепорта — снова сухо до следующего кратного 5.
## В дождь награды за убийство монстров x2 (см. enemy_base.die).

const TELEPORTS_PER_RAIN_PULSE := 5

const _RAIN_OVERLAY_SCENE := preload("res://environment/weather/base_island_rain.tscn")


func is_rain_weather_active() -> bool:
	var c: int = SaveManager.teleport_usage_count
	return c > 0 and c % TELEPORTS_PER_RAIN_PULSE == 0


func get_monster_kill_reward_multiplier() -> float:
	return 2.0 if is_rain_weather_active() else 1.0


func register_teleport_use() -> void:
	SaveManager.teleport_usage_count = maxi(0, SaveManager.teleport_usage_count + 1)
	SaveManager.save_game()
	Events.teleport_usage_count_changed.emit(SaveManager.teleport_usage_count)


## После смены игровой сцены: добавить слой дождя на островах или обновить узел с базы (.tscn).
func sync_rain_overlay_for_scene(scene_root: Node) -> void:
	if scene_root == null or not is_instance_valid(scene_root):
		return
	if Events.current_location == Events.LOCATION.MENU:
		return
	var want_rain := is_rain_weather_active()
	var existing: Node = scene_root.get_node_or_null("BaseIslandRain")
	if want_rain:
		if existing == null:
			var r: Node = _RAIN_OVERLAY_SCENE.instantiate()
			r.name = "BaseIslandRain"
			scene_root.add_child(r)
		elif existing.has_method("refresh_rain_state"):
			existing.call_deferred("refresh_rain_state")
	else:
		if existing != null and existing.has_method("refresh_rain_state"):
			existing.call_deferred("refresh_rain_state")
