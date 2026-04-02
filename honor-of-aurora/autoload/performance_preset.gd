extends RefCounted
class_name PerformancePreset
## Пресеты производительности: FPS, физика, Y-sort, VSync. Не добавлять в autoload — только вызовы из SaveManager.

enum Mode { MINIMAL = 0, MEDIUM = 1, MAXIMUM = 2, CUSTOM = 3 }


static func clamp_mode(m: int) -> int:
	return clampi(m, 0, 3)


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
			ys.set("refresh_every_frames", clampi(ysort_every, 1, 8))

	DisplayServer.window_set_vsync_mode(vsync)
