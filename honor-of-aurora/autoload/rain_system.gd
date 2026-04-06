extends Node
## Погода: счётчик телепортов из меню причала.
## Дождь один «ход» за цикл: активен, пока число телепортов кратно 5 (5, 10, 15…); после следующего телепорта — снова сухо до следующего кратного 5.
## В дождь награды за убийство монстров x2 (см. enemy_base.die) — по `is_rain_weather_active()`, без привязки к пресету «На тапке».
## Визуальный оверлей дождя при `PerformancePreset.Mode.SLIPPER` не показывается (`should_show_rain_overlay()`).

const TELEPORTS_PER_RAIN_PULSE := 5

const _RAIN_OVERLAY_SCENE := preload("res://environment/weather/base_island_rain.tscn")


func is_rain_weather_active() -> bool:
	var c: int = SaveManager.teleport_usage_count
	return c > 0 and c % TELEPORTS_PER_RAIN_PULSE == 0


## Оверлей с частицами: выключается в режиме «На тапке»; логика x2 остаётся по `is_rain_weather_active()`.
## После смены пресета в настройках оверлей синхронизируется из `Save_manager.apply_window_and_engine_settings` (TASK-017).
func should_show_rain_overlay() -> bool:
	return is_rain_weather_active() and not PerformancePreset.is_slipper_mode(SaveManager)


func get_monster_kill_reward_multiplier() -> float:
	return 2.0 if is_rain_weather_active() else 1.0


func register_teleport_use() -> void:
	SaveManager.teleport_usage_count = maxi(0, SaveManager.teleport_usage_count + 1)
	SaveManager.save_game(true)
	Events.teleport_usage_count_changed.emit(SaveManager.teleport_usage_count)


## После смены игровой сцены: добавить слой дождя на островах или обновить узел с базы (.tscn).
func sync_rain_overlay_for_scene(scene_root: Node) -> void:
	if scene_root == null or not is_instance_valid(scene_root):
		return
	if Events.current_location == Events.LOCATION.MENU:
		return
	var show_overlay := should_show_rain_overlay()
	var existing: Node = scene_root.get_node_or_null("BaseIslandRain")
	if show_overlay:
		if existing == null:
			var r: Node = _RAIN_OVERLAY_SCENE.instantiate()
			r.name = "BaseIslandRain"
			scene_root.add_child(r)
		elif existing.has_method("refresh_rain_state"):
			existing.call_deferred("refresh_rain_state")
	else:
		if existing != null and existing.has_method("refresh_rain_state"):
			existing.call_deferred("refresh_rain_state")
