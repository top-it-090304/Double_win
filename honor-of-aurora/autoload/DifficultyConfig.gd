extends Node
## Три пресета сложности. Активный id хранится в SaveManager.difficulty_id (0–2).
## Подключите выбор в меню: DifficultyConfig.set_active_id() или SaveManager.difficulty_id + save_game().

enum Id {
	EASY = 0,
	NORMAL = 1,
	HARD = 2,
}

## Ключи словаря пресета (для UI и баланса).
const KEY_ID := "id"
const KEY_KEY := "key"
const KEY_DISPLAY_NAME := "display_name"
const KEY_DESCRIPTION := "description"
const KEY_ENEMY_STAT_MULT := "enemy_stat_mult"
const KEY_GOLD_REWARD_MULT := "gold_reward_mult"
const KEY_EXP_REWARD_MULT := "exp_reward_mult"
const KEY_EXP_TO_NEXT_LEVEL_MULT := "exp_to_next_level_mult"
const KEY_ECONOMY_COST_MULT := "economy_cost_mult"
## Множитель к фактору урона по врагу выше уровня героя (>1 — легче пробивать «красных»).
const KEY_VS_HIGHER_ENEMY_DAMAGE_MULT := "vs_higher_enemy_damage_mult"

const _PRESETS: Array[Dictionary] = [
	{
		KEY_ID: Id.EASY,
		KEY_KEY: "easy",
		KEY_DISPLAY_NAME: "Лёгкий",
		KEY_DESCRIPTION: "Слабее враги, больше золота и опыта, дешевле развитие базы, проще бить врагов выше уровня.",
		KEY_ENEMY_STAT_MULT: 0.88,
		KEY_GOLD_REWARD_MULT: 1.14,
		KEY_EXP_REWARD_MULT: 1.12,
		KEY_EXP_TO_NEXT_LEVEL_MULT: 0.88,
		KEY_ECONOMY_COST_MULT: 0.92,
		KEY_VS_HIGHER_ENEMY_DAMAGE_MULT: 1.42,
	},
	{
		KEY_ID: Id.NORMAL,
		KEY_KEY: "normal",
		KEY_DISPLAY_NAME: "Нормальный",
		KEY_DESCRIPTION: "Базовый баланс проекта.",
		KEY_ENEMY_STAT_MULT: 1.0,
		KEY_GOLD_REWARD_MULT: 1.0,
		KEY_EXP_REWARD_MULT: 1.0,
		KEY_EXP_TO_NEXT_LEVEL_MULT: 1.0,
		KEY_ECONOMY_COST_MULT: 1.0,
		KEY_VS_HIGHER_ENEMY_DAMAGE_MULT: 1.0,
	},
	{
		KEY_ID: Id.HARD,
		KEY_KEY: "hard",
		KEY_DISPLAY_NAME: "Сложный",
		KEY_DESCRIPTION: "Сильнее враги, меньше наград, дороже база, суровее штраф за врагов выше уровня.",
		KEY_ENEMY_STAT_MULT: 1.14,
		KEY_GOLD_REWARD_MULT: 0.88,
		KEY_EXP_REWARD_MULT: 0.9,
		KEY_EXP_TO_NEXT_LEVEL_MULT: 1.1,
		KEY_ECONOMY_COST_MULT: 1.08,
		KEY_VS_HIGHER_ENEMY_DAMAGE_MULT: 0.78,
	},
]


func get_preset_count() -> int:
	return _PRESETS.size()


func get_preset_by_index(index: int) -> Dictionary:
	var i := clampi(index, 0, _PRESETS.size() - 1)
	return _PRESETS[i].duplicate()


func get_preset_by_id(id: Id) -> Dictionary:
	return get_preset_by_index(int(id))


func get_active_id() -> Id:
	return clampi(SaveManager.difficulty_id, 0, 2) as Id


func get_active_preset() -> Dictionary:
	return get_preset_by_index(int(get_active_id()))


## Установка сложности из меню (0 = EASY … 2 = HARD).
func set_active_id(id: int) -> void:
	SaveManager.difficulty_id = clampi(id, 0, 2)
	SaveManager.save_game()


func get_all_presets() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for p in _PRESETS:
		out.append((p as Dictionary).duplicate())
	return out


func _float(preset: Dictionary, key: StringName, fallback: float) -> float:
	if preset.has(key):
		return float(preset[key])
	return fallback


func get_enemy_stat_mult() -> float:
	return _float(get_active_preset(), KEY_ENEMY_STAT_MULT, 1.0)


func get_gold_reward_mult() -> float:
	return _float(get_active_preset(), KEY_GOLD_REWARD_MULT, 1.0)


func get_exp_reward_mult() -> float:
	return _float(get_active_preset(), KEY_EXP_REWARD_MULT, 1.0)


func get_exp_to_next_level_mult() -> float:
	return _float(get_active_preset(), KEY_EXP_TO_NEXT_LEVEL_MULT, 1.0)


func get_economy_cost_mult() -> float:
	return _float(get_active_preset(), KEY_ECONOMY_COST_MULT, 1.0)


func get_vs_higher_enemy_damage_mult() -> float:
	return _float(get_active_preset(), KEY_VS_HIGHER_ENEMY_DAMAGE_MULT, 1.0)
