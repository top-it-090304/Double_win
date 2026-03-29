class_name IslandProgress
extends Object

static func zone_save_key(island_key: String, zone_id: String) -> String:
	return "%s:%s" % [island_key, zone_id]


static func story_island_index_from_location(loc: Events.LOCATION) -> int:
	match loc:
		Events.LOCATION.LVL1:
			return 1
		Events.LOCATION.LVL2:
			return 2
		Events.LOCATION.LVL3:
			return 3
		Events.LOCATION.LVL4:
			return 4
		Events.LOCATION.LVL5:
			return 5
		_:
			return 0


## После возврата на базу с острова: если страж этого острова ещё жив — сбросить сохранённые зачистки зон,
## чтобы следующий визит снова запускал волны «как прописано». После победы над боссом записи не трогаем.
static func reset_zone_save_for_island_if_boss_alive(island_index: int) -> void:
	if island_index < 1 or island_index > 5:
		return
	if StoryState.has_flag("story_island_%d_cleared" % island_index):
		return
	var prefix := "lvl%d:" % island_index
	var to_erase: Array[String] = []
	for k in SaveManager.island_zone_state.keys():
		var ks := str(k)
		if ks.begins_with(prefix):
			to_erase.append(ks)
	for e in to_erase:
		SaveManager.island_zone_state.erase(e)
