extends Node
## Глобальная сортировка 2D-объектов по Y (группа `y_sortable`).
## Ключ сортировки задаёт `get_y_sort_bottom_y()`; общая геометрия спрайтов — `YSortSpriteBounds`.
## В Godot Y вниз: больший sort_y = ниже на экране → больший z_index → рисуем поверх.

const SORT_GROUP := "y_sortable"
const META_ANCHOR_OFFSET := "y_sort_anchor_offset"
const META_BOTTOM_OFFSET := "y_sort_bottom_offset"
const META_MANUAL := "y_sort_manual"

@export var enabled: bool = true
@export var z_offset: int = 0
@export_range(0.1, 10.0, 0.1) var z_scale: float = 1.0
## Не даём юнитам уходить "под землю", если y уходит в отрицательные координаты карты.
@export var min_z_index: int = 1
@export var max_z_index: int = 4096
## 1 = точнее слои при движении, выше нагрузка. 2–3 — компромисс для слабых устройств.
## Верхняя граница согласована с `PerformancePreset.apply_from_save_manager` (режим SLIPPER, TASK-011).
@export_range(1, 16, 1) var refresh_every_frames: int = 3


func _process(_delta: float) -> void:
	if not enabled:
		return
	if refresh_every_frames > 1 and (Engine.get_process_frames() % refresh_every_frames) != 0:
		return
	var tree := get_tree()
	if tree == null:
		return
	## SLIPPER-эксклюзив: сортируем только то, что вокруг камеры — невидимые слои не влияют на картинку.
	## Экономит все вычисления sort_y и запись z_index для сотен декор-спрайтов далеко на карте.
	var cull_enabled := PerformancePreset.is_slipper_mode(SaveManager)
	var cull_rect := Rect2()
	var has_cull_rect := false
	if cull_enabled:
		var vp := get_viewport()
		if vp != null:
			var cam := vp.get_camera_2d()
			if cam != null and cam.enabled:
				var cc := cam.get_screen_center_position()
				var margin := Vector2(900.0, 700.0)
				cull_rect = Rect2(cc - margin, margin * 2.0)
				has_cull_rect = true
	for node in tree.get_nodes_in_group(SORT_GROUP):
		if node == null or not is_instance_valid(node):
			continue
		if not (node is Node2D):
			continue
		if bool(node.get_meta(META_MANUAL, false)):
			continue
		var n2d := node as Node2D
		if has_cull_rect and not cull_rect.has_point(n2d.global_position):
			continue
		var item := node as CanvasItem
		var sort_y := _get_sort_y(n2d)
		var computed_z := int(round(sort_y * z_scale)) + z_offset
		var new_z := clampi(computed_z, min_z_index, max_z_index)
		## Property-setter'ы в Godot не no-op при равных значениях — пишем только при изменении.
		if item.z_as_relative:
			item.z_as_relative = false
		if item.z_index != new_z:
			item.z_index = new_z


func _get_sort_y(node: Node2D) -> float:
	if node.has_meta(META_BOTTOM_OFFSET):
		return node.global_position.y + float(node.get_meta(META_BOTTOM_OFFSET, 0.0))
	if node.has_method("get_y_sort_bottom_y"):
		var v: Variant = node.call("get_y_sort_bottom_y")
		if v is float or v is int:
			return float(v)
	var anchor_offset := float(node.get_meta(META_ANCHOR_OFFSET, 0.0))
	return node.global_position.y + anchor_offset
