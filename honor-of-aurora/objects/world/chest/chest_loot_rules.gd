class_name ChestLootRules
extends Object
## Диапазоны лута по ярусу сундука 0..5 (совпадает с ChestVisual.ChestTier).

const _GOLD := [
	Vector2i(8, 26),
	Vector2i(16, 44),
	Vector2i(28, 72),
	Vector2i(42, 98),
	Vector2i(58, 130),
	Vector2i(75, 170),
]
const _WOOD := [
	Vector2i(0, 3),
	Vector2i(1, 5),
	Vector2i(2, 7),
	Vector2i(3, 10),
	Vector2i(4, 12),
	Vector2i(5, 16),
]
const _MEAT := [
	Vector2i(0, 2),
	Vector2i(0, 3),
	Vector2i(1, 4),
	Vector2i(1, 5),
	Vector2i(2, 6),
	Vector2i(2, 8),
]
## Вероятность выпадения руды (самый редкий ресурс).
const _ORE_CHANCE := [0.0, 0.07, 0.14, 0.22, 0.30, 0.38]


static func roll_resources(loot_tier: int) -> Dictionary:
	var t: int = clampi(loot_tier, 0, _GOLD.size() - 1)
	var mult: float = DifficultyConfig.get_gold_reward_mult()

	var g: Vector2i = _GOLD[t]
	var gold: int = _rand_range_scaled(g.x, g.y, mult)

	var w: Vector2i = _WOOD[t]
	var wood: int = randi_range(w.x, w.y)

	var m: Vector2i = _MEAT[t]
	var meat: int = randi_range(m.x, m.y)

	var ore: int = 0
	if randf() < _ORE_CHANCE[t]:
		var ore_max: int = 1 + t / 3
		ore = randi_range(1, maxi(1, ore_max))

	return {
		"gold": maxi(0, gold),
		"wood": maxi(0, wood),
		"meat": maxi(0, meat),
		"ore": maxi(0, ore),
	}


static func _rand_range_scaled(lo: int, hi: int, mult: float) -> int:
	if hi < lo:
		var tmp: int = lo
		lo = hi
		hi = tmp
	var a: float = float(lo) * mult
	var b: float = float(hi) * mult
	var lo2: int = maxi(0, int(floor(minf(a, b))))
	var hi2: int = maxi(0, int(ceil(maxf(a, b))))
	if lo2 > hi2:
		var t: int = lo2
		lo2 = hi2
		hi2 = t
	return randi_range(lo2, hi2)


## Случайная записка из глобального справочника, которой ещё нет в сохранении.
static func roll_bonus_lore_note(chance: float) -> String:
	if randf() >= clampf(chance, 0.0, 1.0):
		return ""
	var ids: PackedStringArray = ChestLoreLibrary.get_all_note_ids()
	if ids.is_empty():
		return ""
	var candidates: Array[String] = []
	for i: int in range(ids.size()):
		var note_id: String = String(ids[i])
		if not SaveManager.has_lore_note(note_id):
			candidates.append(note_id)
	if candidates.is_empty():
		return ""
	return candidates[randi() % candidates.size()]
