extends Node
## Единый баланс экономики, опыта и уровней врагов (награды, статы, штраф урона при заниженном уровне героя).
## Множители сложности — DifficultyConfig (SaveManager.difficulty_id).

const MAX_HERO_LEVEL := 60

## Найм любого типа юнита в замке.
const UNIT_HIRE_COST := 220
## Базовый шаг апгрейда здания (итог: step * (tier + 1) в building_template).
const BUILDING_UPGRADE_STEP := 260
## Оружейная: разовые бафы перед походом.
const ARMORY_SWORD_BUFF_COST := 115
const ARMORY_SHIELD_BUFF_COST := 115

## Множитель награды за босса (к группе BOSS).
const BOSS_GOLD_MULT := 2.75
const BOSS_EXP_MULT := 2.35

## Рост HP/урона врага относительно значений в сцене: ~+16% за уровень относительно L1.
const ENEMY_STAT_PER_LEVEL := 1.16

## Чем выше разница (уровень врага − уровень героя), тем сильнее режется урон по врагу.
const UNDERLEVEL_DAMAGE_POW := 0.185
const UNDERLEVEL_DAMAGE_FLOOR := 0.035
const UNDERLEVEL_DAMAGE_CAP := 0.42

## Опыт: база и рост (мягкая экспонента).
const EXP_TO_LEVEL_BASE := 95
const EXP_TO_LEVEL_GROWTH := 1.115

## Золото за убийство: линейная часть + степенная (элита/боссы дают заметно больше).
const GOLD_REWARD_LINEAR := 38
const GOLD_REWARD_POW := 1.28
const GOLD_REWARD_SCALE := 34.0

## Опыт за убийство: масштаб от уровня врага и бонус/штраф за разницу с героем.
const EXP_REWARD_BASE := 12
const EXP_PER_ENEMY_LEVEL := 9
const EXP_OVERLEVEL_GRACE := 0.85
const EXP_UNDERLEVEL_BONUS := 1.12


func _economy_mult() -> float:
	return DifficultyConfig.get_economy_cost_mult()


func get_unit_hire_cost() -> int:
	return maxi(1, int(round(float(UNIT_HIRE_COST) * _economy_mult())))


func get_building_upgrade_step() -> int:
	return maxi(1, int(round(float(BUILDING_UPGRADE_STEP) * _economy_mult())))


func get_armory_sword_buff_cost() -> int:
	return maxi(1, int(round(float(ARMORY_SWORD_BUFF_COST) * _economy_mult())))


func get_armory_shield_buff_cost() -> int:
	return maxi(1, int(round(float(ARMORY_SHIELD_BUFF_COST) * _economy_mult())))


## Порог опыта до следующего уровня героя (текущий уровень = level).
func get_exp_to_next_level(hero_level: int) -> int:
	var L := clampi(hero_level, 1, MAX_HERO_LEVEL)
	var v := float(EXP_TO_LEVEL_BASE) * pow(EXP_TO_LEVEL_GROWTH, float(L - 1))
	v *= DifficultyConfig.get_exp_to_next_level_mult()
	return maxi(50, int(round(v)))


func get_enemy_stat_multiplier(enemy_level: int) -> float:
	var L := clampi(enemy_level, 1, 99)
	return pow(ENEMY_STAT_PER_LEVEL, float(L - 1)) * DifficultyConfig.get_enemy_stat_mult()


## Урон по врагу от героя/союзников: если враг выше уровнем — сильный штраф (считаем уровень героя из сохранения).
func get_incoming_damage_factor_vs_enemy(enemy_level: int) -> float:
	var hero_lv := clampi(SaveManager.current_level, 1, MAX_HERO_LEVEL)
	var gap := clampi(enemy_level - hero_lv, 0, 20)
	if gap <= 0:
		return 1.0
	var f := pow(UNDERLEVEL_DAMAGE_POW, float(gap))
	f *= DifficultyConfig.get_vs_higher_enemy_damage_mult()
	return clampf(f, UNDERLEVEL_DAMAGE_FLOOR, 1.0)


func get_gold_reward(enemy_level: int, is_boss: bool) -> int:
	var L := clampi(enemy_level, 1, 99)
	var base := GOLD_REWARD_LINEAR * L
	var curved := int(round(GOLD_REWARD_SCALE * pow(float(L), GOLD_REWARD_POW)))
	var total := base + curved
	if is_boss:
		total = int(round(float(total) * BOSS_GOLD_MULT))
	total = int(round(float(total) * DifficultyConfig.get_gold_reward_mult()))
	return maxi(8, total)


func get_exp_reward(enemy_level: int, hero_level: int, is_boss: bool) -> int:
	var L := clampi(enemy_level, 1, 99)
	var H := clampi(hero_level, 1, MAX_HERO_LEVEL)
	var diff := L - H
	var xp := EXP_REWARD_BASE + EXP_PER_ENEMY_LEVEL * L
	if diff < 0:
		xp = int(round(float(xp) * EXP_OVERLEVEL_GRACE))
	elif diff > 0:
		xp = int(round(float(xp) * (1.0 + EXP_UNDERLEVEL_BONUS * float(mini(diff, 5)) * 0.2)))
	if is_boss:
		xp = int(round(float(xp) * BOSS_EXP_MULT))
	xp = int(round(float(xp) * DifficultyConfig.get_exp_reward_mult()))
	return maxi(4, xp)
