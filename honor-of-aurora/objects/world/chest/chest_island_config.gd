class_name ChestIslandConfig
extends Object
## Пулы «уровня награды» сундука по номеру острова (1–5).
## Уровень награды 1..5 = индекс лута loot_tier 0..4 в WorldChest (как в ChestLootRules).
##
## Остров 1 → уровни 1 и 2
## Остров 2 → 1, 2, 3
## Остров 3 → 2, 3, 4
## Остров 4 → 3, 4, 5
## Остров 5 → 4 и 5

## PackedInt32Array(...) не является const-выражением в GDScript — только static var.
static var _POOLS: Array[PackedInt32Array] = [
	PackedInt32Array([0, 1]),
	PackedInt32Array([0, 1, 2]),
	PackedInt32Array([1, 2, 3]),
	PackedInt32Array([2, 3, 4]),
	PackedInt32Array([3, 4]),
]


static func get_loot_tier_pool_for_island(island_1_to_5: int) -> PackedInt32Array:
	var idx: int = clampi(island_1_to_5 - 1, 0, _POOLS.size() - 1)
	return _POOLS[idx]


static func roll_loot_tier_for_island(island_1_to_5: int) -> int:
	var pool: PackedInt32Array = get_loot_tier_pool_for_island(island_1_to_5)
	if pool.is_empty():
		return 0
	return int(pool[randi() % pool.size()])


static func island_from_location(loc: Events.LOCATION) -> int:
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
			return 1
