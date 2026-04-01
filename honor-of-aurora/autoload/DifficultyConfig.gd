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
## Сколько привалов на острове за поход (мясо + лимит использований).
const KEY_REST_MAX_PER_EXPEDITION := "rest_max_per_expedition"
## Множитель износа брони за поход и за удар.
const KEY_ARMOR_WEAR_MULT := "armor_wear_mult"
## Услуги базы (монастырь, оружейная, стрельбище, ремонт брони) — на базе экономики пресета.
const KEY_SERVICE_COST_MULT := "service_cost_mult"
## Руда в приказах Короны (ore_required).
const KEY_CROWN_ORE_REQUIRED_MULT := "crown_ore_required_mult"
## Итоговый урон врагов по герою/союзникам (и при gap=0).
const KEY_ENEMY_DAMAGE_TO_PLAYER_MULT := "enemy_damage_to_player_mult"
## Доля HP за один привал (остров).
const KEY_REST_HEAL_RATIO_MULT := "rest_heal_ratio_mult"
## Добыча шахты при возврате с похода.
const KEY_MINE_YIELD_MULT := "mine_yield_mult"
## Лимиты руды/дерева/мяса с одного острова.
const KEY_EXPEDITION_CARRY_CAP_MULT := "expedition_carry_cap_mult"
## Модификаторы привала/лечения от немилости/одобрения Короны (ещё слой сложности).
const KEY_SUPPLY_EFFECT_MULT := "supply_effect_mult"
## Насколько сильнее немилость бьёт по золоту, найму, зданиям и услугам (1.0 = норма).
const KEY_CROWN_WALLET_PENALTY_STRENGTH := "crown_wallet_penalty_strength"
## Насколько сильнее одобрение снижает цены и поднимает жалованье (1.0 = норма).
const KEY_CROWN_WALLET_FAVOR_STRENGTH := "crown_wallet_favor_strength"
## Урон лучников от снабжения Короны (см. CrownSystem.get_archer_damage_modifier).
const KEY_ARCHER_DAMAGE_MULT := "archer_damage_mult"
## Дополнительный множитель макс. HP всех врагов (после базы сцены и get_enemy_stat_multiplier).
const KEY_ENEMY_HP_GLOBAL_MULT := "enemy_hp_global_mult"

const _PRESETS: Array[Dictionary] = [
	{
		KEY_ID: Id.EASY,
		KEY_KEY: "easy",
		KEY_DISPLAY_NAME: "Лёгкий",
		KEY_DESCRIPTION: "Враги слабее и бьют мягче; больше привалов и лечения на отдыхе; дешевле услуги, мягче приказы Короны; броня дольше держится; шахта и лимиты добычи щедрее. Немилость Короны слабее давит на кошелёк, одобрение заметнее помогает.",
		KEY_ENEMY_STAT_MULT: 0.86,
		KEY_GOLD_REWARD_MULT: 1.12,
		KEY_EXP_REWARD_MULT: 1.1,
		KEY_EXP_TO_NEXT_LEVEL_MULT: 0.78,
		KEY_ECONOMY_COST_MULT: 0.9,
		KEY_VS_HIGHER_ENEMY_DAMAGE_MULT: 1.38,
		KEY_REST_MAX_PER_EXPEDITION: 4,
		KEY_ARMOR_WEAR_MULT: 0.78,
		KEY_SERVICE_COST_MULT: 0.88,
		KEY_CROWN_ORE_REQUIRED_MULT: 0.85,
		KEY_ENEMY_DAMAGE_TO_PLAYER_MULT: 0.85,
		KEY_REST_HEAL_RATIO_MULT: 1.12,
		KEY_MINE_YIELD_MULT: 1.06,
		KEY_EXPEDITION_CARRY_CAP_MULT: 1.08,
		KEY_SUPPLY_EFFECT_MULT: 1.06,
		KEY_CROWN_WALLET_PENALTY_STRENGTH: 0.74,
		KEY_CROWN_WALLET_FAVOR_STRENGTH: 1.22,
		KEY_ARCHER_DAMAGE_MULT: 1.05,
		KEY_ENEMY_HP_GLOBAL_MULT: 1.06,
	},
	{
		KEY_ID: Id.NORMAL,
		KEY_KEY: "normal",
		KEY_DISPLAY_NAME: "Нормальный",
		KEY_DESCRIPTION: "Базовый баланс: 3 привала за поход, нормальный износ брони, услуги по прайсу экономики, приказы Короны как в таблице, урон врагов и отдых без доп. модификаторов. Влияние немилости и одобрения на цены и жалованье — эталонное.",
		KEY_ENEMY_STAT_MULT: 1.0,
		KEY_GOLD_REWARD_MULT: 0.95,
		KEY_EXP_REWARD_MULT: 0.95,
		KEY_EXP_TO_NEXT_LEVEL_MULT: 1.08,
		KEY_ECONOMY_COST_MULT: 1.0,
		KEY_VS_HIGHER_ENEMY_DAMAGE_MULT: 1.0,
		KEY_REST_MAX_PER_EXPEDITION: 3,
		KEY_ARMOR_WEAR_MULT: 1.0,
		KEY_SERVICE_COST_MULT: 1.0,
		KEY_CROWN_ORE_REQUIRED_MULT: 1.0,
		KEY_ENEMY_DAMAGE_TO_PLAYER_MULT: 1.0,
		KEY_REST_HEAL_RATIO_MULT: 1.0,
		KEY_MINE_YIELD_MULT: 1.0,
		KEY_EXPEDITION_CARRY_CAP_MULT: 1.0,
		KEY_SUPPLY_EFFECT_MULT: 1.0,
		KEY_CROWN_WALLET_PENALTY_STRENGTH: 1.0,
		KEY_CROWN_WALLET_FAVOR_STRENGTH: 1.0,
		KEY_ARCHER_DAMAGE_MULT: 1.0,
		KEY_ENEMY_HP_GLOBAL_MULT: 1.2,
	},
	{
		KEY_ID: Id.HARD,
		KEY_KEY: "hard",
		KEY_DISPLAY_NAME: "Сложный",
		KEY_DESCRIPTION: "Враги сильнее и больнее; 2 привала за поход; броня стирается быстрее; услуги и приказы Короны жёстче; меньше хила за отдых; шахта и лимиты добычи суровее; снабжение Короны слабее. Немилость сильнее бьёт по золоту и ценам; бонус одобрения чуть скромнее.",
		KEY_ENEMY_STAT_MULT: 1.16,
		KEY_GOLD_REWARD_MULT: 0.76,
		KEY_EXP_REWARD_MULT: 0.84,
		KEY_EXP_TO_NEXT_LEVEL_MULT: 1.18,
		KEY_ECONOMY_COST_MULT: 1.12,
		KEY_VS_HIGHER_ENEMY_DAMAGE_MULT: 0.74,
		KEY_REST_MAX_PER_EXPEDITION: 2,
		KEY_ARMOR_WEAR_MULT: 1.28,
		KEY_SERVICE_COST_MULT: 1.12,
		KEY_CROWN_ORE_REQUIRED_MULT: 1.15,
		KEY_ENEMY_DAMAGE_TO_PLAYER_MULT: 1.12,
		KEY_REST_HEAL_RATIO_MULT: 0.85,
		KEY_MINE_YIELD_MULT: 0.92,
		KEY_EXPEDITION_CARRY_CAP_MULT: 0.88,
		KEY_SUPPLY_EFFECT_MULT: 0.88,
		KEY_CROWN_WALLET_PENALTY_STRENGTH: 1.34,
		KEY_CROWN_WALLET_FAVOR_STRENGTH: 0.86,
		KEY_ARCHER_DAMAGE_MULT: 0.92,
		KEY_ENEMY_HP_GLOBAL_MULT: 1.34,
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


func _int(preset: Dictionary, key: StringName, fallback: int) -> int:
	if preset.has(key):
		var v = preset[key]
		if v is int:
			return int(v)
		if v is float:
			return int(round(v))
	return fallback


func get_rest_max_per_expedition() -> int:
	return clampi(_int(get_active_preset(), KEY_REST_MAX_PER_EXPEDITION, 3), 1, 6)


func get_armor_wear_mult() -> float:
	return _float(get_active_preset(), KEY_ARMOR_WEAR_MULT, 1.0)


func get_service_cost_mult() -> float:
	return _float(get_active_preset(), KEY_SERVICE_COST_MULT, 1.0)


func get_crown_ore_required_mult() -> float:
	return _float(get_active_preset(), KEY_CROWN_ORE_REQUIRED_MULT, 1.0)


func get_enemy_damage_to_player_mult() -> float:
	return _float(get_active_preset(), KEY_ENEMY_DAMAGE_TO_PLAYER_MULT, 1.0)


func get_rest_heal_ratio_mult() -> float:
	return _float(get_active_preset(), KEY_REST_HEAL_RATIO_MULT, 1.0)


func get_mine_yield_mult() -> float:
	return _float(get_active_preset(), KEY_MINE_YIELD_MULT, 1.0)


func get_expedition_carry_cap_mult() -> float:
	return _float(get_active_preset(), KEY_EXPEDITION_CARRY_CAP_MULT, 1.0)


func get_supply_effect_mult() -> float:
	return _float(get_active_preset(), KEY_SUPPLY_EFFECT_MULT, 1.0)


func get_crown_wallet_penalty_strength() -> float:
	return maxf(0.35, _float(get_active_preset(), KEY_CROWN_WALLET_PENALTY_STRENGTH, 1.0))


func get_crown_wallet_favor_strength() -> float:
	return maxf(0.35, _float(get_active_preset(), KEY_CROWN_WALLET_FAVOR_STRENGTH, 1.0))


func get_archer_damage_mult() -> float:
	return _float(get_active_preset(), KEY_ARCHER_DAMAGE_MULT, 1.0)


func get_enemy_hp_global_mult() -> float:
	return _float(get_active_preset(), KEY_ENEMY_HP_GLOBAL_MULT, 1.2)
