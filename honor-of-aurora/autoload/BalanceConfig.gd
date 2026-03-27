extends Node
## Единый баланс экономики, опыта и уровней врагов (награды, статы, штраф урона при заниженном уровне героя).
## Множители сложности — DifficultyConfig (SaveManager.difficulty_id).

## Пять сюжетных островов — пять ступеней героя (см. HeroProgression).
const MAX_HERO_LEVEL := 5

## Найм любого типа юнита в замке (база; на сложности умножается в get_unit_hire_cost).
const UNIT_HIRE_COST := 340
## Базовый шаг апгрейда здания (итог: step * (tier + 1) в building_template).
const BUILDING_UPGRADE_STEP := 300
## Оружейная: разовые бафы перед походом.
const ARMORY_SWORD_BUFF_COST := 155
const ARMORY_SHIELD_BUFF_COST := 155
## Монастырь/стрельбище: «хардкор» сервисы требуют руду.
const MONASTERY_REVIVE_GOLD_COST := 190
const MONASTERY_REVIVE_ORE_COST := 9
const MONASTERY_VITALITY_GOLD_COST := 125
const MONASTERY_VITALITY_ORE_COST := 6
const ARCHERY_VOLLEY_GOLD_COST := 145
const ARCHERY_VOLLEY_ORE_COST := 7
const ARCHERY_GUARD_GOLD_COST := 145
const ARCHERY_GUARD_ORE_COST := 7
## Дерево за шаг улучшения здания (умножается на (tier + 1) как золото).
const BUILDING_UPGRADE_WOOD_STEP := 22

## Множитель награды за босса (к группе BOSS).
const BOSS_GOLD_MULT := 3.05
const BOSS_EXP_MULT := 2.35

## Рост HP/урона врага по enemy_level (остров): заметная ступень между островами.
const ENEMY_STAT_PER_LEVEL := 1.24

## Чем выше разница (уровень врага − уровень героя), тем сильнее режется урон по врагу.
const UNDERLEVEL_DAMAGE_POW := 0.185
const UNDERLEVEL_DAMAGE_FLOOR := 0.035
const UNDERLEVEL_DAMAGE_CAP := 0.42

## Порог опыта до следующего уровня: число «эквивалентных» убийств врага своего уровня (L=L).
## Ориентир ~1 ч игры на уровень при среднем темпе ~1.5–2 убийства/мин в бою (без спидрана).
## Точная длительность зависит от исследования и сложности — калибруйте TARGET_KILLS_PER_LEVEL при плейтестах.
const TARGET_KILLS_PER_LEVEL := 100

## Золото за убийство: линейная часть + степенная (элита/боссы дают заметно больше).
## Значения занижены относительно старых — экономика не должна раздуваться за один заход.
const GOLD_REWARD_LINEAR := 5
const GOLD_REWARD_POW := 1.22
const GOLD_REWARD_SCALE := 3.5

## Опыт за убийство: масштаб от уровня врага и бонус/штраф за разницу с героем.
const EXP_REWARD_BASE := 11
const EXP_PER_ENEMY_LEVEL := 8
## Герой выше врага: XP *= pow(база, H−L). На врагах 1 ур. после 2→3 качаться почти бессмысленно.
const EXP_OVERLEVEL_FARM_BASE := 0.48
const EXP_UNDERLEVEL_BONUS := 1.12
## Враг выше героя: урон по герою *= pow(база, gap) — на чужом острове без уровня «мнут».
const ENEMY_DAMAGE_VS_LOWER_HERO_PER_GAP := 1.2


func _economy_mult() -> float:
	return DifficultyConfig.get_economy_cost_mult()


func get_unit_hire_cost() -> int:
	return maxi(1, int(round(float(UNIT_HIRE_COST) * _economy_mult())))


func get_building_upgrade_step() -> int:
	return maxi(1, int(round(float(BUILDING_UPGRADE_STEP) * _economy_mult())))


func get_building_upgrade_wood_cost(tier_before_upgrade: int) -> int:
	var t: int = clampi(tier_before_upgrade, 0, 10)
	return maxi(0, int(round(float(BUILDING_UPGRADE_WOOD_STEP) * float(t + 1) * _economy_mult())))


func get_armory_sword_buff_cost() -> int:
	return maxi(1, int(round(float(ARMORY_SWORD_BUFF_COST) * _economy_mult())))


func get_armory_shield_buff_cost() -> int:
	return maxi(1, int(round(float(ARMORY_SHIELD_BUFF_COST) * _economy_mult())))


func get_monastery_revive_gold_cost() -> int:
	return maxi(1, int(round(float(MONASTERY_REVIVE_GOLD_COST) * _economy_mult())))


func get_monastery_revive_ore_cost() -> int:
	return maxi(1, int(round(float(MONASTERY_REVIVE_ORE_COST) * _economy_mult())))


func get_monastery_vitality_gold_cost() -> int:
	return maxi(1, int(round(float(MONASTERY_VITALITY_GOLD_COST) * _economy_mult())))


func get_monastery_vitality_ore_cost() -> int:
	return maxi(1, int(round(float(MONASTERY_VITALITY_ORE_COST) * _economy_mult())))


func get_archery_volley_gold_cost() -> int:
	return maxi(1, int(round(float(ARCHERY_VOLLEY_GOLD_COST) * _economy_mult())))


func get_archery_volley_ore_cost() -> int:
	return maxi(1, int(round(float(ARCHERY_VOLLEY_ORE_COST) * _economy_mult())))


func get_archery_guard_gold_cost() -> int:
	return maxi(1, int(round(float(ARCHERY_GUARD_GOLD_COST) * _economy_mult())))


func get_archery_guard_ore_cost() -> int:
	return maxi(1, int(round(float(ARCHERY_GUARD_ORE_COST) * _economy_mult())))


func get_exp_to_next_level(hero_level: int) -> int:
	var L := clampi(hero_level, 1, MAX_HERO_LEVEL)
	if L >= MAX_HERO_LEVEL:
		return 0
	var per_kill := float(get_exp_reward(L, L, false))
	var v := per_kill * float(TARGET_KILLS_PER_LEVEL)
	v *= DifficultyConfig.get_exp_to_next_level_mult()
	return maxi(120, int(round(v)))


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


## Урон врага по герою/союзникам: если враг выше уровнем — заметно больнее (идти на остров без уровня опасно).
func get_enemy_outgoing_damage_vs_hero(enemy_level: int) -> float:
	var hero_lv := clampi(SaveManager.current_level, 1, MAX_HERO_LEVEL)
	var gap := clampi(enemy_level - hero_lv, 0, 12)
	if gap <= 0:
		return 1.0
	return pow(ENEMY_DAMAGE_VS_LOWER_HERO_PER_GAP, float(gap))


func get_gold_reward(enemy_level: int, is_boss: bool) -> int:
	var L := clampi(enemy_level, 1, 99)
	var base := GOLD_REWARD_LINEAR * L
	var curved := int(round(GOLD_REWARD_SCALE * pow(float(L), GOLD_REWARD_POW)))
	var total := base + curved
	if is_boss:
		total = int(round(float(total) * BOSS_GOLD_MULT))
	total = int(round(float(total) * DifficultyConfig.get_gold_reward_mult()))
	return maxi(4, total)


func get_exp_reward(enemy_level: int, hero_level: int, is_boss: bool) -> int:
	var L := clampi(enemy_level, 1, 99)
	var H := clampi(hero_level, 1, MAX_HERO_LEVEL)
	var diff := L - H
	var xp := EXP_REWARD_BASE + EXP_PER_ENEMY_LEVEL * L
	var over_gap := H - L
	if over_gap > 0:
		xp = int(round(float(xp) * pow(EXP_OVERLEVEL_FARM_BASE, float(over_gap))))
	elif diff > 0:
		xp = int(round(float(xp) * (1.0 + EXP_UNDERLEVEL_BONUS * float(mini(diff, 5)) * 0.2)))
	if is_boss:
		xp = int(round(float(xp) * BOSS_EXP_MULT))
	xp = int(round(float(xp) * DifficultyConfig.get_exp_reward_mult()))
	return maxi(1, xp)
