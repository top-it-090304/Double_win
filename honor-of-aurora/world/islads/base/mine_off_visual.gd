extends TileMapLayer
## Слой «шахта выключена»: виден, пока **никому** из рабочих не назначена добыча руды (один статус на всех, без мигания).

## Режим «На тапке» (TASK-014): `Engine.get_process_frames() % N` с **N = 3** — реже обходить `ally_pawn` и вызывать `is_assigned_to_ore_mining`.
## Экономит CPU на базе; не должно сломаться: только видимость декоративного слоя (задержка обновления до ~3 кадров), назначение рабочих и добыча не затрагиваются.
const _SLIPPER_MINE_OFF_CHECK_EVERY_FRAMES: int = 3

func _process(_delta: float) -> void:
	if PerformancePreset.is_slipper_mode(SaveManager):
		if _SLIPPER_MINE_OFF_CHECK_EVERY_FRAMES > 1 and (Engine.get_process_frames() % _SLIPPER_MINE_OFF_CHECK_EVERY_FRAMES) != 0:
			return
	if Events.current_location != Events.LOCATION.BASE:
		return
	var tree := get_tree()
	if tree == null:
		return
	if tree.get_node_count_in_group(&"ally_pawn") < 1:
		visible = true
		return
	var any_ore_assigned := false
	for n in tree.get_nodes_in_group("ally_pawn"):
		if not n.has_method("is_assigned_to_ore_mining"):
			continue
		if n.is_assigned_to_ore_mining():
			any_ore_assigned = true
			break
	visible = not any_ore_assigned
