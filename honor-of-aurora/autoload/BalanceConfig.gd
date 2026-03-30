extends Node
## Единый баланс экономики, опыта и уровней врагов (награды, статы, штраф урона при заниженном уровне героя).
## Множители сложности — DifficultyConfig (SaveManager.difficulty_id).

## Полная прогрессия героя (внешность меняется по брейкпоинтам в HeroProgression).
const MAX_HERO_LEVEL := 20

## Найм любого типа юнита в замке (база; на сложности умножается в get_unit_hire_cost).
const UNIT_HIRE_COST := 260
const UNIT_HIRE_ORE_COST := 1
## Базовый шаг апгрейда здания (итог: step * (tier + 1) в building_template).
const BUILDING_UPGRADE_STEP := 220
## Оружейная: разовые бафы перед походом.
const ARMORY_SWORD_BUFF_COST := 155
const ARMORY_SHIELD_BUFF_COST := 155
## Церковь/стрельбище: «хардкор» сервисы требуют руду.
const MONASTERY_REVIVE_GOLD_COST := 190
const MONASTERY_REVIVE_ORE_COST := 9
const MONASTERY_VITALITY_GOLD_COST := 125
const MONASTERY_VITALITY_ORE_COST := 6
const ARCHERY_VOLLEY_GOLD_COST := 145
const ARCHERY_VOLLEY_ORE_COST := 7
const ARCHERY_GUARD_GOLD_COST := 145
const ARCHERY_GUARD_ORE_COST := 7
## Дерево за шаг улучшения здания (умножается на (tier + 1) как золото).
const BUILDING_UPGRADE_WOOD_STEP := 18
const BUILDING_UPGRADE_ORE_STEP := 2

## Множитель награды за босса (к группе BOSS).
const BOSS_GOLD_MULT := 3.05
const BOSS_EXP_MULT := 2.35

## Рост HP/урона врага по enemy_level (остров): заметная ступень между островами.
const ENEMY_STAT_PER_LEVEL := 1.17

## Чем выше разница (уровень врага − уровень героя), тем сильнее режется урон по врагу.
const UNDERLEVEL_DAMAGE_PER_GAP := 0.12
const UNDERLEVEL_DAMAGE_FLOOR := 0.55
const UNDERLEVEL_DAMAGE_BONUS_CAP := 1.15

## Порог опыта до следующего уровня: число «эквивалентных» убийств врага своего уровня (L=L).
## Ориентир ~1 ч игры на уровень при среднем темпе ~1.5–2 убийства/мин в бою (без спидрана).
## Точная длительность зависит от исследования и сложности — калибруйте TARGET_KILLS_PER_LEVEL при плейтестах.
const TARGET_KILLS_PER_LEVEL := 24

## Золото за убийство: линейная часть + степенная (элита/боссы дают заметно больше).
## Значения занижены относительно старых — экономика не должна раздуваться за один заход.
const GOLD_REWARD_LINEAR := 5
const GOLD_REWARD_POW := 1.22
const GOLD_REWARD_SCALE := 3.5

## Опыт за убийство: масштаб от уровня врага и бонус/штраф за разницу с героем.
const EXP_REWARD_BASE := 11
const EXP_PER_ENEMY_LEVEL := 8
## Герой выше врага: XP *= pow(база, H−L). На врагах 1 ур. после 2→3 качаться почти бессмысленно.
const EXP_OVERLEVEL_FARM_BASE := 0.84
const EXP_UNDERLEVEL_BONUS := 0.46
## Враг выше героя: урон по герою *= pow(база, gap) — на чужом острове без уровня «мнут».
const ENEMY_DAMAGE_VS_LOWER_HERO_PER_GAP := 1.10
const ENEMY_DAMAGE_VS_LOWER_HERO_CAP := 1.45

## Руда как универсальная валюта.
const ORE_TO_GOLD_RATE := 42
const ORE_TO_WOOD_RATE := 3

## Premium Ore Packs (для real-money интеграции/SDK и fallback-покупки).
const PREMIUM_ORE_PACKS := [
	{"id": "starter", "title": "Стартовый", "ore": 50, "bonus_ore": 5, "price_label": "99 ₽"},
	{"id": "adventurer", "title": "Путник", "ore": 140, "bonus_ore": 20, "price_label": "299 ₽"},
	{"id": "commander", "title": "Командир", "ore": 320, "bonus_ore": 60, "price_label": "599 ₽"},
	{"id": "warlord", "title": "Полководец", "ore": 700, "bonus_ore": 180, "price_label": "1 199 ₽"},
]

## ─── Шахта: пассивная добыча руды при возврате с похода ───
const MINE_BASE_ORE_PER_RETURN := 2
const MINE_ORE_PER_TIER := 1
const MINE_ORE_PER_PAWN_ON_BASE := 1
const MINE_MAX_PAWN_BONUS := 3

## ─── Провизия: стоимость похода мясом ───
const EXPEDITION_BASE_MEAT_COST := 2
const EXPEDITION_MEAT_PER_WARRIOR := 1

## ─── Привал: хил героя за мясо на острове ───
const REST_HEAL_RATIO := 0.30
const REST_MAX_PER_EXPEDITION := 2
const REST_MEAT_COST := 1

## ─── Караван Короны ───
const CARAVAN_EXPEDITION_INTERVAL := 3
const CARAVAN_SUPPLY_GOLD_BASE := 40
const CARAVAN_SUPPLY_MEAT_BASE := 2

## ─── Приказы Короны (масштабируются по сюжету) ───
const CROWN_ORDERS := [
	{"index": 1, "ore_required": 15, "deadline_expeditions": 4, "letter": "Первая партия. Маяк на Северном мысе гаснет. Казна ждёт."},
	{"index": 2, "ore_required": 25, "deadline_expeditions": 4, "letter": "Совет требует ускорить. Торговцы жалуются на тёмные проливы."},
	{"index": 3, "ore_required": 40, "deadline_expeditions": 5, "letter": "Казначей прислал инспектора. Покажи ему шахту — и результаты."},
	{"index": 4, "ore_required": 60, "deadline_expeditions": 5, "letter": "Король лично ждёт отчёт. Не разочаруй Корону."},
	{"index": 5, "ore_required": 80, "deadline_expeditions": 6, "letter": "Последний маяк. Если он погаснет — виноват будешь ты."},
]

## ─── Титулы Короны (по суммарной руде, отправленной Короне) ───
const CROWN_TITLES := [
	{
		"id": "recruit", "name": "Рекрут Авроры", "ore_threshold": 0,
		"gold_bonus_ratio": 0.0, "mine_ore_bonus": 0, "service_discount": 0.0,
		"flavors": [
			"Указ сослал тебя на цепь островов Аврора. Пока в реестре — строка, не герб: честь здесь начинается с отгрузки, не с печати.",
			"В реестре ты обещание руды: Корона ждёт поставку, зал тебя ещё не зовёт.",
			"На тебя поставлена ставка указа: царство ждёт руду — пока без личного почёта.",
			"Приказ раньше герба: пока ты число в графах, не имя для бала при дворе.",
		],
	},
	{
		"id": "scout", "name": "Разведчик Архипелага", "ore_threshold": 30,
		"gold_bonus_ratio": 0.05, "mine_ore_bonus": 0, "service_discount": 0.0,
		"flavors": [
			"Архипелаг перестал быть в отчёте пустым квадратом: казначей видит партии и имя.",
			"Столица называет твоё имя там, где считают партии — не только потери.",
			"Надежда отчёта сбылась: тебя выделяют среди расхода экспедиции.",
			"Имя в открытой графе: для казны архипелаг перестал быть пустым полем.",
		],
	},
	{
		"id": "guardian", "name": "Страж Маяков", "ore_threshold": 100,
		"gold_bonus_ratio": 0.05, "mine_ore_bonus": 1, "service_discount": 0.0,
		"flavors": [
			"Без Сердцевины с островов маяки на материке гаснут. Страж в списках Короны — звено между жилой и огнём.",
			"От тебя зависит свет чужих маяков: государство держит тебя в живой цепи снабжения.",
			"Ты держишь дыхание торговых путей; без тебя гаснет не только огонь в лагере.",
			"Твоя руда кормит маяки материка — в графах Короны ты уже часть цепи света.",
		],
	},
	{
		"id": "knight", "name": "Рыцарь Сердцевины", "ore_threshold": 240,
		"gold_bonus_ratio": 0.05, "mine_ore_bonus": 1, "service_discount": 0.10,
		"flavors": [
			"В зале — звонко; в гавани то же звание значит отгрузку, о которой двор помнит дольше, чем тост.",
			"Двор слышит звание; казна доверяет отгрузку уже тебе, не анониму.",
			"Государство связывает с тобой честь и казну — одно имя на двух языках.",
			"«Рыцарь Сердцевины» звучит при дворе; его проверяют мешки, от которых живут маяки.",
		],
	},
	{
		"id": "keeper", "name": "Хранитель Авроры", "ore_threshold": 500,
		"gold_bonus_ratio": 0.08, "mine_ore_bonus": 2, "service_discount": 0.10,
		"flavors": [
			"Аврора в книгах одна; хранитель в этом имени — не придворная должность, а привязка к этой воде и этой жиле.",
			"При советах шепчут твоё имя рядом с Авророй — как об опоре моря царства.",
			"Редкий статус: тебя знают как того, у кого «ключ» к Сердцевине цепи Авроры.",
			"Имя прибито к архипелагу: в столице его не спутают с сотней придворных гербов.",
		],
	},
	{
		"id": "hero", "name": "Герой Короны", "ore_threshold": 1000,
		"gold_bonus_ratio": 0.10, "mine_ore_bonus": 2, "service_discount": 0.15,
		"flavors": [
			"Корона возвела тебя в герои перед материком: летопись и совет, печать на почёте — в реестре экспедиции равных нет.",
			"Летопись и совет: материк произносит твоё имя с почтением; выше этой ступени в реестре никого.",
			"Имя уходит за пределы базы: надежда короны стала летописью, тебя помнят при дворе.",
			"Печать на грамоте, речь при советах: ты не подрядчик на день — память царства на века.",
		],
	},
]

## ─── Немилость Короны (дебафы за невыполнение приказов) ───
const DISPLEASURE_GOLD_PENALTY := 0.15
const DISPLEASURE_BUILDING_COST_PENALTY := 0.20
const DISPLEASURE_MAX_LEVEL := 3

## ─── Одобрение Короны (бонусы за стабильное выполнение приказов) ───
const CROWN_FAVOR_MAX_LEVEL := 3

## ─── Модификаторы снабжения: влияние немилости/одобрения на геймплей ───
## Немилость: штрафы к исцелению, привалу, стоимости услуг, урону лучников.
const SUPPLY_HEAL_PENALTY_PER_DISPLEASURE := 0.12
const SUPPLY_REST_PENALTY_PER_DISPLEASURE := 0.10
const SUPPLY_SERVICE_COST_PER_DISPLEASURE := 0.15
const SUPPLY_ARCHER_DAMAGE_PER_DISPLEASURE := 0.06
## Одобрение: бонусы (зеркальные, но слабее — награда мягче кнута).
const SUPPLY_HEAL_BONUS_PER_FAVOR := 0.08
const SUPPLY_REST_BONUS_PER_FAVOR := 0.08
const SUPPLY_SERVICE_DISCOUNT_PER_FAVOR := 0.05
const SUPPLY_ARCHER_DAMAGE_PER_FAVOR := 0.05

## ─── Износ снаряжения (броня) ───
const ARMOR_MAX_DURABILITY := 100
const ARMOR_WEAR_PER_EXPEDITION := 15
## Потеря прочности за каждое попадание по герою (1 ед. при макс. 100 ≈ 1% полоски).
const ARMOR_WEAR_PER_HIT_TAKEN := 1
const ARMOR_REPAIR_GOLD_COST := 80
const ARMOR_REPAIR_ORE_COST := 2
## Пороги: ниже — хуже блок щитом.
const ARMOR_WORN_THRESHOLD := 50
const ARMOR_CRITICAL_THRESHOLD := 25
## Штраф к блоку: добавляется к shield_damage_factor (больше урона проходит в блоке).
const ARMOR_WORN_BLOCK_PENALTY := 0.06
const ARMOR_CRITICAL_BLOCK_PENALTY := 0.14
## Немилость/одобрение влияют на стоимость ремонта.
const ARMOR_REPAIR_COST_PER_DISPLEASURE := 0.35
const ARMOR_REPAIR_DISCOUNT_PER_FAVOR := 0.10

## ─── Ресурсный cap за один поход (анти-фарм) ───
const MAX_ORE_PER_EXPEDITION := 6
const MAX_WOOD_PER_EXPEDITION := 18
const MAX_MEAT_PER_EXPEDITION := 5


## Сколько осколков сердцевины появляется после победы над стражем острова.
## Линейно по номеру острова: 1→20, 2→30, 3→40, 4→50, 5→60.
func get_boss_defeat_ore_spark_count(story_island_index: int) -> int:
	var s := clampi(story_island_index, 0, 5)
	if s < 1:
		return 0
	return 10 + s * 10


## Сколько осколков сердцевины (как у босса, с притяжением) за очистку сильной зоны у руин / сундуков: доля от боссовского спауна.
func get_encounter_clear_boss_style_ore_spark_count(island_tier: int) -> int:
	var boss_n := get_boss_defeat_ore_spark_count(island_tier)
	if boss_n <= 0:
		return 0
	return maxi(1, int(round(float(boss_n) * 0.2)))


## ─── Неигровые бонусы за донат (пороги суммарной купленной руды) ───
const PATRON_TIERS := [
	{"id": "supporter",   "ore_threshold": 50,   "reward": "thank_letter",  "label": "Письмо благодарности в кодексе"},
	{"id": "patron",      "ore_threshold": 200,  "reward": "title_frame",   "label": "Рамка титула в HUD"},
	{"id": "chronicler",  "ore_threshold": 500,  "reward": "chronicle_name","label": "Имя в Хронике благодарности"},
	{"id": "legend",      "ore_threshold": 1000, "reward": "chest_note",    "label": "Персональная записка из сундука"},
]

## Дополнительная строка под титулом в замке при покупке премиум-Сердцевины (диегетика: лагерь, хроника, казна).
const PATRON_TITLE_GRATITUDE_LINES := [
	"В хронике лагеря — особая строка. Есть те, чья щедрость хранит этот берег не хуже стен замка.",
	"Летописцы внесли запись: не только меч и кирка держат лагерь. Есть незримая опора — и она бесценна.",
	"На вкладыше к реестру — помета казначея: «благодарность без приказа». Редкая строка в казённых книгах.",
	"Имя занесено в хронику благодарности — рядом с теми, кто продлил поход не силой, а верой.",
	"Маяки горят, караван ходит, лагерь дышит — за этим стоит больше, чем один указ Короны.",
	"Есть вклад, который не измеришь в рудных ведомостях. Лагерь стоит крепче благодаря ему — и это помнят.",
	"В списках снабжения — строка, которую не выписывала канцелярия. За неё благодарят тихо, но искренне.",
	"Доверие у причала рождается, когда кто-то вкладывает в берег больше, чем обязан. Хроника помнит таких.",
]


func _economy_mult() -> float:
	return DifficultyConfig.get_economy_cost_mult()


func get_unit_hire_cost() -> int:
	return maxi(1, int(round(float(UNIT_HIRE_COST) * _economy_mult())))


func get_unit_hire_ore_cost() -> int:
	return maxi(0, int(round(float(UNIT_HIRE_ORE_COST) * _economy_mult())))


func get_building_upgrade_step() -> int:
	return maxi(1, int(round(float(BUILDING_UPGRADE_STEP) * _economy_mult())))


func get_building_upgrade_wood_cost(tier_before_upgrade: int) -> int:
	var t: int = clampi(tier_before_upgrade, 0, 10)
	return maxi(0, int(round(float(BUILDING_UPGRADE_WOOD_STEP) * float(t + 1) * _economy_mult())))


func get_building_upgrade_ore_cost(tier_before_upgrade: int) -> int:
	var t: int = clampi(tier_before_upgrade, 0, 10)
	return maxi(0, int(round(float(BUILDING_UPGRADE_ORE_STEP) * float(t + 1) * _economy_mult())))


func _crown_service_mult() -> float:
	return get_supply_service_cost_mult(SaveManager.crown_displeasure, SaveManager.crown_favor)


func get_armory_sword_buff_cost() -> int:
	return maxi(1, int(round(float(ARMORY_SWORD_BUFF_COST) * _economy_mult() * _crown_service_mult())))


func get_armory_shield_buff_cost() -> int:
	return maxi(1, int(round(float(ARMORY_SHIELD_BUFF_COST) * _economy_mult() * _crown_service_mult())))


func get_monastery_revive_gold_cost() -> int:
	return maxi(1, int(round(float(MONASTERY_REVIVE_GOLD_COST) * _economy_mult() * _crown_service_mult())))


func get_monastery_revive_ore_cost() -> int:
	return maxi(1, int(round(float(MONASTERY_REVIVE_ORE_COST) * _economy_mult())))


func get_monastery_vitality_gold_cost() -> int:
	return maxi(1, int(round(float(MONASTERY_VITALITY_GOLD_COST) * _economy_mult() * _crown_service_mult())))


func get_monastery_vitality_ore_cost() -> int:
	return maxi(1, int(round(float(MONASTERY_VITALITY_ORE_COST) * _economy_mult())))


func get_archery_volley_gold_cost() -> int:
	return maxi(1, int(round(float(ARCHERY_VOLLEY_GOLD_COST) * _economy_mult() * _crown_service_mult())))


func get_archery_volley_ore_cost() -> int:
	return maxi(1, int(round(float(ARCHERY_VOLLEY_ORE_COST) * _economy_mult())))


func get_archery_guard_gold_cost() -> int:
	return maxi(1, int(round(float(ARCHERY_GUARD_GOLD_COST) * _economy_mult() * _crown_service_mult())))


func get_archery_guard_ore_cost() -> int:
	return maxi(1, int(round(float(ARCHERY_GUARD_ORE_COST) * _economy_mult())))


func get_exp_to_next_level(hero_level: int) -> int:
	var L := clampi(hero_level, 1, MAX_HERO_LEVEL)
	if L >= MAX_HERO_LEVEL:
		return 0
	var v := 120.0 + 35.0 * float(L) + 12.0 * float(L * L)
	v *= DifficultyConfig.get_exp_to_next_level_mult()
	return maxi(120, int(round(v)))


func get_enemy_stat_multiplier(enemy_level: int) -> float:
	var L := clampi(enemy_level, 1, 99)
	return pow(ENEMY_STAT_PER_LEVEL, float(L - 1)) * DifficultyConfig.get_enemy_stat_mult()


## Урон по врагу от героя/союзников: если враг выше уровнем — сильный штраф (считаем уровень героя из сохранения).
func get_incoming_damage_factor_vs_enemy(enemy_level: int) -> float:
	var hero_lv := clampi(SaveManager.current_level, 1, MAX_HERO_LEVEL)
	var gap := enemy_level - hero_lv
	var f := 1.0 - UNDERLEVEL_DAMAGE_PER_GAP * float(gap)
	f *= DifficultyConfig.get_vs_higher_enemy_damage_mult()
	return clampf(f, UNDERLEVEL_DAMAGE_FLOOR, UNDERLEVEL_DAMAGE_BONUS_CAP)


## Урон врага по герою/союзникам: если враг выше уровнем — заметно больнее (идти на остров без уровня опасно).
func get_enemy_outgoing_damage_vs_hero(enemy_level: int) -> float:
	var hero_lv := clampi(SaveManager.current_level, 1, MAX_HERO_LEVEL)
	var gap := clampi(enemy_level - hero_lv, 0, 12)
	if gap <= 0:
		return 1.0
	return minf(ENEMY_DAMAGE_VS_LOWER_HERO_CAP, pow(ENEMY_DAMAGE_VS_LOWER_HERO_PER_GAP, float(gap)))


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


func get_ore_needed_for_gold(gold_shortage: int) -> int:
	if gold_shortage <= 0:
		return 0
	return int(ceil(float(gold_shortage) / float(ORE_TO_GOLD_RATE)))


func get_ore_needed_for_wood(wood_shortage: int) -> int:
	if wood_shortage <= 0:
		return 0
	return int(ceil(float(wood_shortage) / float(ORE_TO_WOOD_RATE)))


func get_premium_ore_pack_ids() -> Array[String]:
	var out: Array[String] = []
	for p in PREMIUM_ORE_PACKS:
		if p is Dictionary and p.has("id"):
			out.append(String(p["id"]))
	return out


func get_premium_ore_pack(pack_id: String) -> Dictionary:
	for p in PREMIUM_ORE_PACKS:
		if p is Dictionary and String(p.get("id", "")) == pack_id:
			return (p as Dictionary).duplicate()
	return {}


## ─── Шахта ───

func get_mine_ore_per_return(mine_tier: int, pawns_on_base: int, title_mine_bonus: int) -> int:
	var from_tier := MINE_BASE_ORE_PER_RETURN + MINE_ORE_PER_TIER * clampi(mine_tier, 0, 4)
	var from_pawns := MINE_ORE_PER_PAWN_ON_BASE * clampi(pawns_on_base, 0, MINE_MAX_PAWN_BONUS)
	return maxi(1, from_tier + from_pawns + maxi(0, title_mine_bonus))


## ─── Провизия ───

func get_expedition_meat_cost(warrior_count: int) -> int:
	return maxi(1, int(round(float(EXPEDITION_BASE_MEAT_COST + EXPEDITION_MEAT_PER_WARRIOR * maxi(0, warrior_count)) * _economy_mult())))


func get_rest_heal_amount(max_health: int) -> int:
	return maxi(1, int(round(float(max_health) * REST_HEAL_RATIO)))


## ─── Караван ───

func get_caravan_supply_gold() -> int:
	return maxi(1, int(round(float(CARAVAN_SUPPLY_GOLD_BASE) * _economy_mult())))


func get_caravan_supply_meat() -> int:
	return CARAVAN_SUPPLY_MEAT_BASE


func get_crown_order(order_index: int) -> Dictionary:
	for o in CROWN_ORDERS:
		if o is Dictionary and int(o.get("index", -1)) == order_index:
			return (o as Dictionary).duplicate()
	return {}


## ─── Титулы ───

func get_crown_title_for_ore_sent(ore_sent_total: int) -> Dictionary:
	for i in range(CROWN_TITLES.size() - 1, -1, -1):
		var t: Dictionary = CROWN_TITLES[i]
		if ore_sent_total >= int(t.get("ore_threshold", 0)):
			return t.duplicate()
	return (CROWN_TITLES[0] as Dictionary).duplicate()


func get_crown_title_index_for_ore_sent(ore_sent_total: int) -> int:
	for i in range(CROWN_TITLES.size() - 1, -1, -1):
		if ore_sent_total >= int(CROWN_TITLES[i].get("ore_threshold", 0)):
			return i
	return 0


## Случайная подпись из пула `flavors`; иначе одиночное поле `flavor` (устар.).
func pick_crown_title_flavor(title: Dictionary) -> String:
	var fl = title.get("flavors", null)
	if fl is Array and fl.size() > 0:
		var opts: PackedStringArray = []
		for x in fl:
			var t := str(x).strip_edges()
			if not t.is_empty():
				opts.append(t)
		if opts.size() > 0:
			return opts[randi() % opts.size()]
	var legacy := str(title.get("flavor", "")).strip_edges()
	if not legacy.is_empty():
		return legacy
	return "Служба Короне на архипелаге."


func get_crown_gold_bonus_ratio(ore_sent_total: int) -> float:
	return float(get_crown_title_for_ore_sent(ore_sent_total).get("gold_bonus_ratio", 0.0))


func get_crown_service_discount(ore_sent_total: int) -> float:
	return float(get_crown_title_for_ore_sent(ore_sent_total).get("service_discount", 0.0))


func get_crown_mine_ore_bonus(ore_sent_total: int) -> int:
	return int(get_crown_title_for_ore_sent(ore_sent_total).get("mine_ore_bonus", 0))


## ─── Немилость ───

func get_displeasure_gold_mult(displeasure_level: int) -> float:
	if displeasure_level <= 0:
		return 1.0
	return maxf(0.5, 1.0 - DISPLEASURE_GOLD_PENALTY * float(clampi(displeasure_level, 0, DISPLEASURE_MAX_LEVEL)))


func get_displeasure_building_cost_mult(displeasure_level: int) -> float:
	if displeasure_level <= 0:
		return 1.0
	return 1.0 + DISPLEASURE_BUILDING_COST_PENALTY * float(clampi(displeasure_level, 0, DISPLEASURE_MAX_LEVEL))


## ─── Patron (донат) ───

func get_patron_tier_for_purchased(ore_purchased_total: int) -> Dictionary:
	var best: Dictionary = {}
	for t in PATRON_TIERS:
		if t is Dictionary and ore_purchased_total >= int(t.get("ore_threshold", 0)):
			best = t
	return best.duplicate() if not best.is_empty() else {}


func get_patron_tier_index(ore_purchased_total: int) -> int:
	var idx := -1
	for i in range(PATRON_TIERS.size()):
		if ore_purchased_total >= int(PATRON_TIERS[i].get("ore_threshold", 0)):
			idx = i
	return idx


func get_patron_title_gratitude_epithet(ore_purchased_total: int) -> String:
	if ore_purchased_total <= 0:
		return ""
	var n := PATRON_TITLE_GRATITUDE_LINES.size()
	if n == 0:
		return ""
	var i := int(ore_purchased_total) % n
	return str(PATRON_TITLE_GRATITUDE_LINES[i])


## ─── Модификаторы снабжения Короны ───


func get_supply_heal_mult(displeasure: int, favor: int) -> float:
	var m := 1.0
	if displeasure > 0:
		m -= SUPPLY_HEAL_PENALTY_PER_DISPLEASURE * float(clampi(displeasure, 0, DISPLEASURE_MAX_LEVEL))
	elif favor > 0:
		m += SUPPLY_HEAL_BONUS_PER_FAVOR * float(clampi(favor, 0, CROWN_FAVOR_MAX_LEVEL))
	return clampf(m, 0.4, 1.5)


func get_supply_rest_mult(displeasure: int, favor: int) -> float:
	var m := 1.0
	if displeasure > 0:
		m -= SUPPLY_REST_PENALTY_PER_DISPLEASURE * float(clampi(displeasure, 0, DISPLEASURE_MAX_LEVEL))
	elif favor > 0:
		m += SUPPLY_REST_BONUS_PER_FAVOR * float(clampi(favor, 0, CROWN_FAVOR_MAX_LEVEL))
	return clampf(m, 0.4, 1.5)


func get_supply_service_cost_mult(displeasure: int, favor: int) -> float:
	var m := 1.0
	if displeasure > 0:
		m += SUPPLY_SERVICE_COST_PER_DISPLEASURE * float(clampi(displeasure, 0, DISPLEASURE_MAX_LEVEL))
	elif favor > 0:
		m -= SUPPLY_SERVICE_DISCOUNT_PER_FAVOR * float(clampi(favor, 0, CROWN_FAVOR_MAX_LEVEL))
	return maxf(0.7, m)


func get_supply_archer_damage_mult(displeasure: int, favor: int) -> float:
	var m := 1.0
	if displeasure > 0:
		m -= SUPPLY_ARCHER_DAMAGE_PER_DISPLEASURE * float(clampi(displeasure, 0, DISPLEASURE_MAX_LEVEL))
	elif favor > 0:
		m += SUPPLY_ARCHER_DAMAGE_PER_FAVOR * float(clampi(favor, 0, CROWN_FAVOR_MAX_LEVEL))
	return clampf(m, 0.7, 1.3)


## ─── Износ снаряжения ───


func get_armor_block_penalty(durability: int) -> float:
	var d := clampi(durability, 0, ARMOR_MAX_DURABILITY)
	if d <= ARMOR_CRITICAL_THRESHOLD:
		return ARMOR_CRITICAL_BLOCK_PENALTY
	if d <= ARMOR_WORN_THRESHOLD:
		return ARMOR_WORN_BLOCK_PENALTY
	return 0.0


func get_armor_repair_gold_cost(displeasure: int, favor: int) -> int:
	var m := 1.0
	if displeasure > 0:
		m += ARMOR_REPAIR_COST_PER_DISPLEASURE * float(clampi(displeasure, 0, DISPLEASURE_MAX_LEVEL))
	elif favor > 0:
		m -= ARMOR_REPAIR_DISCOUNT_PER_FAVOR * float(clampi(favor, 0, CROWN_FAVOR_MAX_LEVEL))
	return maxi(1, int(round(float(ARMOR_REPAIR_GOLD_COST) * maxf(0.5, m) * _economy_mult())))


func get_armor_repair_ore_cost(displeasure: int, favor: int) -> int:
	var m := 1.0
	if displeasure > 0:
		m += ARMOR_REPAIR_COST_PER_DISPLEASURE * float(clampi(displeasure, 0, DISPLEASURE_MAX_LEVEL)) * 0.5
	elif favor > 0:
		m -= ARMOR_REPAIR_DISCOUNT_PER_FAVOR * float(clampi(favor, 0, CROWN_FAVOR_MAX_LEVEL)) * 0.5
	return maxi(0, int(round(float(ARMOR_REPAIR_ORE_COST) * maxf(0.5, m) * _economy_mult())))
