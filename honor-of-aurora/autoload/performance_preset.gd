extends RefCounted
class_name PerformancePreset
## Пресеты производительности: FPS, физика, Y-sort, VSync. Не добавлять в autoload — только вызовы из SaveManager.

enum Mode { MINIMAL = 0, MEDIUM = 1, MAXIMUM = 2, CUSTOM = 3, SLIPPER = 4 }

## «На тапке»: в `Window.CONTENT_SCALE_MODE_VIEWPORT` внутреннее разрешение = base / factor (~75% по ширине/высоте, ~56% пикселей).
## См. `Save_manager.apply_window_and_engine_settings`.
const SLIPPER_RENDER_STRETCH_SCALE: float = 4.0 / 3.0
## Сцена главного меню: без понижения внутреннего разрешения (см. `should_apply_slipper_viewport_stretch`).
const MAIN_MENU_SCENE_FILE := "Game_menu.tscn"

## Максимум `refresh_every_frames` для YSortManager — должен совпадать с `@export_range` в `YSortManager.gd`.
const YSORT_REFRESH_FRAMES_MAX: int = 16


static func clamp_mode(m: int) -> int:
	return clampi(m, 0, Mode.SLIPPER)


## Режим «На тапке» (`Mode.SLIPPER`): централизованная проверка для отключения тяжёлого визуала (погода, частицы и т.д.) без смены логики наград/сохранений.
static func is_slipper_mode(sm: Node) -> bool:
	if sm == null:
		return false
	return clamp_mode(int(sm.performance_mode)) == Mode.SLIPPER


## Понижение внутреннего разрешения (viewport stretch) в SLIPPER — только в игровых сценах, не в главном меню.
static func should_apply_slipper_viewport_stretch(sm: Node) -> bool:
	if sm == null or not is_slipper_mode(sm):
		return false
	var tree: SceneTree = sm.get_tree()
	if tree == null:
		tree = Engine.get_main_loop() as SceneTree
	if tree == null:
		return false
	if Events.current_location == Events.LOCATION.MENU:
		return false
	var cs: Node = tree.current_scene
	if cs == null:
		return false
	var path := str(cs.scene_file_path)
	if path.is_empty():
		return false
	if path.get_file() == MAIN_MENU_SCENE_FILE:
		return false
	return true


## Применить к движку и YSortManager. Для CUSTOM max_fps из SaveManager; физика 60 Гц и Y-sort раз в 2 кадра — для ручного лимита FPS без урезания симуляции.
static func apply_from_save_manager(sm: Node) -> void:
	if sm == null:
		return
	var mode: int = clamp_mode(int(sm.performance_mode))
	var max_fps_val: int = int(sm.max_fps)
	var ticks: int = 60
	var ysort_every: int = 2
	var vsync: int = DisplayServer.VSYNC_ENABLED
	match mode:
		Mode.SLIPPER:
			## «На тапке» (волна 2, TASK-011): целевые значения — 30 FPS, physics_ticks_per_second = 30, Y-sort раз в 16 кадров, VSync.
			## Риск снижения physics_ticks ниже 30: боёвка и быстрые снаряды; не уменьшать без отдельной проверки геймплея.
			## Риск Y-sort реже 8 кадров: возможные артефакты порядка слоёв при быстром движении; реже пересчёт z_index — меньше CPU.
			max_fps_val = 30
			ticks = 30
			ysort_every = 16
			vsync = DisplayServer.VSYNC_ENABLED
		Mode.MINIMAL:
			max_fps_val = 30
			ticks = 30
			ysort_every = 4
			vsync = DisplayServer.VSYNC_ENABLED
		Mode.MEDIUM:
			## 60 FPS на экране, но нагрузка как у «слабого» профиля: 30 Гц физики + редкий Y-sort (см. physics_interpolation у CharacterUnit).
			max_fps_val = 60
			ticks = 30
			ysort_every = 4
			vsync = DisplayServer.VSYNC_ENABLED
		Mode.MAXIMUM:
			max_fps_val = 0
			ticks = 60
			## Раньше каждый кадр — дорого при сотнях y_sortable; 2 кадра — заметно дешевле, слои всё ещё часто обновляются.
			ysort_every = 2
			## ADAPTIVE на части ПК/драйверов даёт неочевидное поведение; для «макс. плавности» — обычный VSync.
			vsync = DisplayServer.VSYNC_ENABLED
		Mode.CUSTOM:
			ticks = 60
			ysort_every = 2
			vsync = DisplayServer.VSYNC_ENABLED
			max_fps_val = clampi(max_fps_val, 0, 240)

	if mode != Mode.CUSTOM:
		sm.max_fps = max_fps_val

	if max_fps_val <= 0:
		Engine.max_fps = 0
	else:
		Engine.max_fps = clampi(max_fps_val, 30, 240)

	Engine.physics_ticks_per_second = float(ticks)

	var tree: SceneTree = sm.get_tree()
	if tree == null:
		tree = Engine.get_main_loop() as SceneTree
	if tree:
		var ys: Node = tree.root.get_node_or_null("YSortManager")
		if ys:
			ys.set("refresh_every_frames", clampi(ysort_every, 1, YSORT_REFRESH_FRAMES_MAX))

	DisplayServer.window_set_vsync_mode(vsync)
