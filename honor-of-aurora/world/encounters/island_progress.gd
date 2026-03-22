class_name IslandProgress
extends Object

static func zone_save_key(island_key: String, zone_id: String) -> String:
	return "%s:%s" % [island_key, zone_id]
