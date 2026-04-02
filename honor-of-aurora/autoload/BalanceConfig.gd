extends Node
## Единый баланс экономики, опыта и уровней врагов (награды, статы, штраф урона при заниженном уровне героя).
## Множители сложности — DifficultyConfig (SaveManager.difficulty_id).

## Полная прогрессия героя (внешность меняется по брейкпоинтам в HeroProgression).
const MAX_HERO_LEVEL := 20

## Найм любого типа юнита в замке (база; на сложности умножается в get_unit_hire_cost).
const UNIT_HIRE_COST := 260
const UNIT_HIRE_ORE_COST := 1
## Лучники + копейщики + рудокопы + сюжетный юноша (если в лагере/отряде), не считая героя.
const MAX_SQUAD_MEMBERS := 10
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
const BOSS_EXP_MULT := 2.05

## Рост HP/урона врага по enemy_level (остров): заметная ступень между островами.
const ENEMY_STAT_PER_LEVEL := 1.185

## Чем выше разница (уровень врага − уровень героя), тем сильнее режется урон по врагу.
const UNDERLEVEL_DAMAGE_PER_GAP := 0.13
const UNDERLEVEL_DAMAGE_FLOOR := 0.50
const UNDERLEVEL_DAMAGE_BONUS_CAP := 1.15

## Порог опыта до следующего уровня: `get_exp_to_next_level` = (EXP_REWARD_BASE + EXP_PER_ENEMY_LEVEL × L) × TARGET_KILLS × множитель сложности.
## То есть при убийстве врага своего уровня нужно ~TARGET_KILLS таких убийств (без боссов и бонусов за андерлевел).
## Плейтест: в debug-сборке при аппе печатается `[Balance] Level up | kills since last level: N`.
const TARGET_KILLS_PER_LEVEL := 24

## Золото за убийство: линейная часть + степенная (элита/боссы дают заметно больше).
## Значения занижены относительно старых — экономика не должна раздуваться за один заход.
const GOLD_REWARD_LINEAR := 5
const GOLD_REWARD_POW := 1.22
const GOLD_REWARD_SCALE := 3.5

## Опыт за убийство: масштаб от уровня врага и бонус/штраф за разницу с героем.
const EXP_REWARD_BASE := 9
const EXP_PER_ENEMY_LEVEL := 7
## Герой выше врага: XP *= pow(база, H−L). На врагах 1 ур. после 2→3 качаться почти бессмысленно.
const EXP_OVERLEVEL_FARM_BASE := 0.84
const EXP_UNDERLEVEL_BONUS := 0.46
## Враг выше героя: урон по герою *= pow(база, gap) — на чужом острове без уровня «мнут».
const ENEMY_DAMAGE_VS_LOWER_HERO_PER_GAP := 1.115
const ENEMY_DAMAGE_VS_LOWER_HERO_CAP := 1.52

## Руда как универсальная валюта.
const ORE_TO_GOLD_RATE := 42
const ORE_TO_WOOD_RATE := 3

## Premium Ore Packs (для real-money интеграции/SDK и fallback-покупки).
const PREMIUM_ORE_PACKS := [
	{"id": "starter", "title": "Стартовый", "ore": 50, "bonus_ore": 5, "price_label": "99 ₽", "payment_sku": "dev_starter_pack_small"},
	{"id": "adventurer", "title": "Путник", "ore": 140, "bonus_ore": 20, "price_label": "299 ₽", "payment_sku": "premium_ore_adventurer"},
	{"id": "commander", "title": "Командир", "ore": 320, "bonus_ore": 60, "price_label": "599 ₽", "payment_sku": "premium_ore_commander"},
	{"id": "warlord", "title": "Полководец", "ore": 700, "bonus_ore": 180, "price_label": "1 199 ₽", "payment_sku": "premium_ore_warlord"},
]

## ─── Шахта: пассивная добыча руды при возврате с похода ───
const MINE_BASE_ORE_PER_RETURN := 2
const MINE_ORE_PER_TIER := 1
const MINE_ORE_PER_PAWN_ON_BASE := 1
const MINE_MAX_PAWN_BONUS := 3

## ─── Провизия: стоимость похода мясом ───
const EXPEDITION_BASE_MEAT_COST := 2
const EXPEDITION_MEAT_PER_WARRIOR := 1

## ─── Привал: за раз восстанавливается не больше REST_HEAL_RATIO×max HP (×модификатор Короны в CrownSystem).
## До полного HP за один привал — только если этот объём покрывает недостающее HP.
const REST_HEAL_RATIO := 0.30
## Базовое значение для ориентира; фактический лимит — `get_rest_max_per_expedition()` (DifficultyConfig).
const REST_MAX_PER_EXPEDITION := 3
## Длительность анимации восстановления (сек.); модификатор снабжения ускоряет.
const REST_REGEN_DURATION_SEC := 4.0

## ─── Караван Короны ───
## Шаг графика: караван прибывает, когда оставшийся срок приказа (единый счётчик) кратен этому числу, включая 0.
const CARAVAN_EXPEDITION_INTERVAL := 3
## Fallback для `deadline_expeditions` в данных приказа; кратен CARAVAN_EXPEDITION_INTERVAL (один счётчик с рейсом).
const DEFAULT_CROWN_ORDER_DEADLINE_EXPEDITIONS := CARAVAN_EXPEDITION_INTERVAL
const CARAVAN_SUPPLY_GOLD_BASE := 40
const CARAVAN_SUPPLY_MEAT_BASE := 2

## ─── Приказы Короны (масштабируются по сюжету) ───
## `deadline_expeditions` — длина того же счётчика, что `SaveManager.crown_returns_remaining` (в игре — дни в лагере), кратна CARAVAN_EXPEDITION_INTERVAL.
const CROWN_ORDERS := [
	{"index": 1, "ore_required": 15, "deadline_expeditions": 3, "letter": "Первая партия. Маяк на Северном мысе гаснет. Казна ждёт."},
	{"index": 2, "ore_required": 25, "deadline_expeditions": 6, "letter": "Совет требует ускорить. Торговцы жалуются на тёмные проливы."},
	{"index": 3, "ore_required": 40, "deadline_expeditions": 6, "letter": "Казначей прислал инспектора. Покажи ему шахту — и результаты."},
	{"index": 4, "ore_required": 60, "deadline_expeditions": 9, "letter": "Король лично ждёт отчёт. Не разочаруй Корону."},
	{"index": 5, "ore_required": 80, "deadline_expeditions": 9, "letter": "Последний маяк. Если он погаснет — виноват будешь ты."},
]

## ─── Титулы Короны (по суммарной руде, отправленной Короне) ───
const CROWN_TITLES := [
	{
		"id": "recruit", "name": "Рекрут Авроры", "ore_threshold": 0,
		"gold_bonus_ratio": 0.0, "expedition_ore_carry_bonus": 0, "service_discount": 0.0,
		"combat_hp_bonus": 0,
		"combat_incoming_damage_mult": 1.0,
		"combat_hero_damage_mult": 1.0,
		"combat_speed_bonus": 0.0,
		"exp_bonus_ratio": 0.0,
		"combat_vs_higher_enemy_mult": 1.0,
		"flavors": [
			"Указ сослал тебя на цепь островов Аврора. Пока в реестре — строка, не герб: честь здесь начинается с отгрузки, не с печати.",
			"В реестре ты обещание руды: Корона ждёт поставку, зал тебя ещё не зовёт.",
			"На тебя поставлена ставка указа: царство ждёт руду — пока без личного почёта.",
			"Приказ раньше герба: пока ты число в графах, не имя для бала при дворе.",
		],
	},
	{
		"id": "scout", "name": "Разведчик Архипелага", "ore_threshold": 30,
		"gold_bonus_ratio": 0.12, "expedition_ore_carry_bonus": 1, "service_discount": 0.0,
		"combat_hp_bonus": 12,
		"combat_incoming_damage_mult": 0.988,
		"combat_hero_damage_mult": 1.028,
		"combat_speed_bonus": 5.0,
		"exp_bonus_ratio": 0.05,
		"combat_vs_higher_enemy_mult": 1.035,
		"flavors": [
			"Архипелаг перестал быть в отчёте пустым квадратом: казначей видит партии и имя.",
			"Столица называет твоё имя там, где считают партии — не только потери.",
			"Надежда отчёта сбылась: тебя выделяют среди расхода экспедиции.",
			"Имя в открытой графе: для казны архипелаг перестал быть пустым полем.",
		],
		"patent_lines": [
			"Во имя Короны. Настоящей грамотой канцелярия удостоверяет: вы возведены в звание «Разведчик Архипелага» — за то, что Сердцевина с ваших рейсов стала делом учёта, а не слухом.",
			"Жалованье каравана с сего дня исчисляется по повышенной норме: казна не щедрит напрасно — она платит за имя, которое уже значит что-то в открытых графах.",
			"Со склада королевской сбруи выдан комплект по списку доверенных лиц: клинок и доспех с печатью мастерской Короны. По ним ведётся ваша карточка: крепче тело, вернее шаг, удар метче, рана от чужого железа — на долю легче, чем у рядового в ведомости.",
			"Прилагается распоряжение на дополнительную единицу Сердцевины к вывозу за поход — не привилегия, а первая грамота доверия к вашим мешкам.",
			"Назначены уставные занятия: опыт с поля боя заносится в реестр полнее. Против врага, чей ранг в их списках выше вашего, устав разведчика дозволяет держать удар без лишних оков — ибо разведка не терпит церемоний, когда цена ошибки — маяк на материке.",
		],
		"patent_hero_line": "Бумага с печатью… и сбруя по списку. Значит, Корона больше не шепчет обо мне — она считает вслух.",
	},
	{
		"id": "guardian", "name": "Страж Маяков", "ore_threshold": 100,
		"gold_bonus_ratio": 0.16, "expedition_ore_carry_bonus": 2, "service_discount": 0.0,
		"combat_hp_bonus": 24,
		"combat_incoming_damage_mult": 0.975,
		"combat_hero_damage_mult": 1.045,
		"combat_speed_bonus": 8.0,
		"exp_bonus_ratio": 0.075,
		"combat_vs_higher_enemy_mult": 1.065,
		"flavors": [
			"Без Сердцевины с островов маяки на материке гаснут. Страж в списках Короны — звено между жилой и огнём.",
			"От тебя зависит свет чужих маяков: государство держит тебя в живой цепи снабжения.",
			"Ты держишь дыхание торговых путей; без тебя гаснет не только огонь в лагере.",
			"Твоя руда кормит маяки материка — в графах Короны ты уже часть цепи света.",
		],
		"patent_lines": [
			"Во имя Короны. Канцелярия возводит вас в звание «Страж Маяков»: цепь Сердцевины с Авроры держит огни большой земли — и двор впервые пишет ваше имя рядом с этой обязанностью, не в примечании.",
			"Жалованье каравана увеличено вновь: казна платит за то, что маяки не гаснут в ваших отчётах.",
			"С казённой кузницы — второй ступенью усиленный комплект: пластины плотнее, клинок тяжелее, шаг увереннее, удар глубже, раны чужие — слабее на весах интенданта. Таков дар не чести, а должности: стражу положено пережить дорогу домой.",
			"Грамота на вывоз: к лимиту Сердцевины за поход прибавлено две единицы — двор доверяет не только мечу, но и мешкам.",
			"Инструкторы короны продлевают уставные уроки: опыт с побед заносится щедрее. Против старшего по рангу врага удар ваш законен сильнее — ибо страж маяков не обязан биться как наёмник; он обязан победить.",
		],
		"patent_hero_line": "Маяки на материке не знают моего лица — зато знают мою руду. Теперь об этом сказано и в столице.",
	},
	{
		"id": "knight", "name": "Рыцарь Сердцевины", "ore_threshold": 240,
		"gold_bonus_ratio": 0.22, "expedition_ore_carry_bonus": 3, "service_discount": 0.20,
		"combat_hp_bonus": 38,
		"combat_incoming_damage_mult": 0.96,
		"combat_hero_damage_mult": 1.062,
		"combat_speed_bonus": 11.0,
		"exp_bonus_ratio": 0.10,
		"combat_vs_higher_enemy_mult": 1.095,
		"flavors": [
			"В зале — звонко; в гавани то же звание значит отгрузку, о которой двор помнит дольше, чем тост.",
			"Двор слышит звание; казна доверяет отгрузку уже тебе, не анониму.",
			"Государство связывает с тобой честь и казну — одно имя на двух языках.",
			"«Рыцарь Сердцевины» звучит при дворе; его проверяют мешки, от которых живут маяки.",
		],
		"patent_lines": [
			"Во имя Короны. Сей грамота возводит вас в звание «Рыцарь Сердцевины»: не бал для зала — обязанность перед жилой, от которой живёт материк.",
			"Жалованье каравана повышено по новой статье; к тому же канцелярия дарует тариф на укрепление лагеря: доля золота и руды на улучшения зданий снижена — как вассалу, на котором держится цепь поставок.",
			"С королевской мастерской — полный рыцарский комплект: доспех и оружие, по которым двор не стыдится назвать вас при дворе и на поле. Отсюда прибавка к живучести, к удару, к шагу; входящий урон в учёте слабее; опыт с побед полнее; против врага выше ранга — удар не режут уставом, ибо рыцарь Сердцевины служит не частному контракту, а короне.",
			"К лимиту вывоза Сердцевины за поход прибавлено три единицы: казна доверяет мешки так же, как меч.",
		],
		"patent_hero_line": "Рыцарь в грамоте — и рыцарь в сбруе. Теперь слова из столицы совпадают с тем, что на мне висит.",
	},
	{
		"id": "keeper", "name": "Хранитель Авроры", "ore_threshold": 500,
		"gold_bonus_ratio": 0.30, "expedition_ore_carry_bonus": 4, "service_discount": 0.26,
		"combat_hp_bonus": 55,
		"combat_incoming_damage_mult": 0.942,
		"combat_hero_damage_mult": 1.082,
		"combat_speed_bonus": 14.0,
		"exp_bonus_ratio": 0.125,
		"combat_vs_higher_enemy_mult": 1.125,
		"flavors": [
			"Аврора в книгах одна; хранитель в этом имени — не придворная должность, а привязка к этой воде и этой жиле.",
			"При советах шепчут твоё имя рядом с Авророй — как об опоре моря царства.",
			"Редкий статус: тебя знают как того, у кого «ключ» к Сердцевине цепи Авроры.",
			"Имя прибито к архипелагу: в столице его не спутают с сотней придворных гербов.",
		],
		"patent_lines": [
			"Во имя Короны. Канцелярия и совет единогласно возводят вас в звание «Хранитель Авроры»: имя, которое в летописях стоит рядом с цепью островов, а не в приложении к ней.",
			"Жалованье каравана — по высшей статье для архипелага; тариф на укрепление лагеря ещё смягчён: двор не жалеет камня и золота на того, кто держит Аврору в живых графах.",
			"С сокровенного склада — комплект хранителя: клинок и латы, которым завидуют придворные капитаны. Живучесть, шаг, удар и стойкость перед чужим железом приведены к норме «опора цепи»; опыт с поля боя в реестре ценится выше; удар по врагу, чей ранг выше, не режут — хранитель не спорит с врагом о чести, он закрывает воду царства.",
			"Четыре дополнительные единицы Сердцевины к вывозу за поход: не награда — признание того, что без ваших мешков архипелаг перестаёт быть стратегией и становится воспоминанием.",
		],
		"patent_hero_line": "Хранитель — это уже не должность из приказа. Это то, как меня назовут, когда Аврора останется на карте.",
	},
	{
		"id": "hero", "name": "Герой Короны", "ore_threshold": 1000,
		"gold_bonus_ratio": 0.42, "expedition_ore_carry_bonus": 5, "service_discount": 0.34,
		"combat_hp_bonus": 75,
		"combat_incoming_damage_mult": 0.92,
		"combat_hero_damage_mult": 1.105,
		"combat_speed_bonus": 18.0,
		"exp_bonus_ratio": 0.15,
		"combat_vs_higher_enemy_mult": 1.155,
		"flavors": [
			"Корона возвела тебя в герои перед материком: летопись и совет, печать на почёте — в реестре экспедиции равных нет.",
			"Летопись и совет: материк произносит твоё имя с почтением; выше этой ступени в реестре никого.",
			"Имя уходит за пределы базы: надежда короны стала летописью, тебя помнят при дворе.",
			"Печать на грамоте, речь при советах: ты не подрядчик на день — память царства на века.",
		],
		"patent_lines": [
			"Во имя Короны. Сей патент — венец гражданской и военной хроники: вы наречены «Героем Короны». Выше звания в реестре экспедиций на Аврору нет; ниже — только память о тех, кто не дожил до этой строки.",
			"Жалованье каравана исчисляется по норме, какую двор устанавливает для имени, которое произносят при советах без префикса «некто». Тариф на укрепление лагеря — самый мягкий из дозволенных законом: царство не считает затрат на ваш берег расточительством.",
			"С тайного арсенала — комплект, о котором мастера расписываются в придворных книгах: то, что носит только тот, чья смерть стоила бы дороже, чем цена металла. Живучесть, шаг, удар, стойкость перед вражьим железом и доля опыта с побед доведены до потолка устава; удар по врагу выше ранга — по праву героя, а не по снисхождению интенданта.",
			"Пять единиц Сердцевины сверх прежнего лимита на поход: казна говорит прямо — без ваших мешков о стратегии можно не беседовать.",
			"Сохраните сию грамоту. Печать, подпись канцелярии и помета летописца — одно и то же для будущих читателей.",
		],
		"patent_hero_line": "Герой Короны… Слова, которые раньше были в чужих песнях. Теперь они в моём свёртке — и на моих плечах.",
	},
]

## ─── Немилость Короны (дебафы за невыполнение приказов) ───
const DISPLEASURE_MAX_LEVEL := 3
## Жалованье каравана (без титула): шаг за уровень немилости, × `DifficultyConfig.crown_wallet_penalty_strength`.
const CROWN_CARAVAN_GOLD_MOOD_MIN := 0.30
const CROWN_CARAVAN_GOLD_MOOD_MAX := 1.42
const DISPLEASURE_GOLD_PER_LEVEL := 0.26
## Одобрение к жалованью (при отсутствии немилости).
const FAVOR_GOLD_PER_LEVEL := 0.10
## Здания: надбавка к золоту/дереву/руде за уровень немилости; скидка за одобрение.
const DISPLEASURE_BUILDING_COST_PER_LEVEL := 0.16
const FAVOR_BUILDING_DISCOUNT_PER_LEVEL := 0.078
const CROWN_BUILDING_COST_MULT_MIN := 0.76
## Найм: дороже при немилости, дешевле при одобрении.
const DISPLEASURE_HIRE_SURCHARGE_PER_LEVEL := 0.15
const FAVOR_HIRE_DISCOUNT_PER_LEVEL := 0.062
const CROWN_HIRE_MULT_MIN := 0.78

## ─── Одобрение Короны (бонусы за стабильное выполнение приказов) ───
const CROWN_FAVOR_MAX_LEVEL := 3
## Пол для комбинированного «урон по герою» (титул × одобрение).
const CROWN_COMBAT_INCOMING_MULT_MIN := 0.78
## Доп. смягчение урона по герою за уровень одобрения (при отсутствии немилости в бою не проверяем — множитель всё равно нейтрален при favor 0).
const CROWN_FAVOR_INCOMING_REDUCTION_PER_LEVEL := 0.012

## ─── Модификаторы снабжения: влияние немилости/одобрения на геймплей ───
## Немилость: штрафы к исцелению, привалу, стоимости услуг, урону лучников (× сила сложности).
const SUPPLY_HEAL_PENALTY_PER_DISPLEASURE := 0.14
const SUPPLY_REST_PENALTY_PER_DISPLEASURE := 0.12
const SUPPLY_SERVICE_COST_PER_DISPLEASURE := 0.28
const SUPPLY_ARCHER_DAMAGE_PER_DISPLEASURE := 0.07
## Одобрение: бонусы (зеркальные, но слабее — награда мягче кнута).
const SUPPLY_HEAL_BONUS_PER_FAVOR := 0.09
const SUPPLY_REST_BONUS_PER_FAVOR := 0.09
const SUPPLY_SERVICE_DISCOUNT_PER_FAVOR := 0.15
const SUPPLY_ARCHER_DAMAGE_PER_FAVOR := 0.06

## ─── Износ снаряжения (броня): только попадания по герою, см. CrownSystem.apply_armor_wear_on_hit_taken ───
const ARMOR_MAX_DURABILITY := 100
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
## При прочности 0 входящий урон от врагов к герою (после базовой формулы врага) умножается на это значение.
const ARMOR_BROKEN_INCOMING_DAMAGE_MULT := 2.0
## Немилость/одобрение влияют на стоимость ремонта.
const ARMOR_REPAIR_COST_PER_DISPLEASURE := 0.48
const ARMOR_REPAIR_DISCOUNT_PER_FAVOR := 0.13

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


func _crown_wallet_penalty_w() -> float:
	return DifficultyConfig.get_crown_wallet_penalty_strength()


func _crown_wallet_favor_w() -> float:
	return DifficultyConfig.get_crown_wallet_favor_strength()


## Множитель к золоту каравана от немилости/одобрения (без бонуса титула).
func get_crown_caravan_gold_mult(displeasure: int, favor: int) -> float:
	var d := clampi(displeasure, 0, DISPLEASURE_MAX_LEVEL)
	var f := clampi(favor, 0, CROWN_FAVOR_MAX_LEVEL)
	if d > 0:
		var cut := DISPLEASURE_GOLD_PER_LEVEL * float(d) * _crown_wallet_penalty_w()
		return maxf(CROWN_CARAVAN_GOLD_MOOD_MIN, 1.0 - cut)
	if f > 0:
		var add := FAVOR_GOLD_PER_LEVEL * float(f) * _crown_wallet_favor_w()
		return minf(CROWN_CARAVAN_GOLD_MOOD_MAX, 1.0 + add)
	return 1.0


## Золото, дерево и руда за шаг улучшения здания.
func get_crown_building_cost_mult(displeasure: int, favor: int) -> float:
	var d := clampi(displeasure, 0, DISPLEASURE_MAX_LEVEL)
	var f := clampi(favor, 0, CROWN_FAVOR_MAX_LEVEL)
	if d > 0:
		return 1.0 + DISPLEASURE_BUILDING_COST_PER_LEVEL * float(d) * _crown_wallet_penalty_w()
	if f > 0:
		var disc := FAVOR_BUILDING_DISCOUNT_PER_LEVEL * float(f) * _crown_wallet_favor_w()
		return maxf(CROWN_BUILDING_COST_MULT_MIN, 1.0 - disc)
	return 1.0


## Найм юнита: золото и руда.
func get_crown_hire_cost_mult(displeasure: int, favor: int) -> float:
	var d := clampi(displeasure, 0, DISPLEASURE_MAX_LEVEL)
	var f := clampi(favor, 0, CROWN_FAVOR_MAX_LEVEL)
	if d > 0:
		return 1.0 + DISPLEASURE_HIRE_SURCHARGE_PER_LEVEL * float(d) * _crown_wallet_penalty_w()
	if f > 0:
		var disc := FAVOR_HIRE_DISCOUNT_PER_LEVEL * float(f) * _crown_wallet_favor_w()
		return maxf(CROWN_HIRE_MULT_MIN, 1.0 - disc)
	return 1.0


## Найм, здания, провизия похода — только экономика. Услуги базы — см. `_service_price_mult()`.
func _service_price_mult() -> float:
	return _economy_mult() * DifficultyConfig.get_service_cost_mult()


func get_rest_max_per_expedition() -> int:
	return DifficultyConfig.get_rest_max_per_expedition()


func get_unit_hire_cost() -> int:
	var crown := get_crown_hire_cost_mult(SaveManager.crown_displeasure, SaveManager.crown_favor)
	return maxi(1, int(round(float(UNIT_HIRE_COST) * _economy_mult() * crown)))


func get_unit_hire_ore_cost() -> int:
	var crown := get_crown_hire_cost_mult(SaveManager.crown_displeasure, SaveManager.crown_favor)
	return maxi(0, int(round(float(UNIT_HIRE_ORE_COST) * _economy_mult() * crown)))


func get_building_upgrade_step() -> int:
	## Титул (скидка) + немилость/одобрение — см. CrownSystem.get_building_cost_crown_mult().
	return maxi(1, int(round(float(BUILDING_UPGRADE_STEP) * _economy_mult() * CrownSystem.get_building_cost_crown_mult())))


func get_building_upgrade_wood_cost(tier_before_upgrade: int) -> int:
	var t: int = clampi(tier_before_upgrade, 0, 10)
	return maxi(0, int(round(float(BUILDING_UPGRADE_WOOD_STEP) * float(t + 1) * _economy_mult() * CrownSystem.get_building_cost_crown_mult())))


func get_building_upgrade_ore_cost(tier_before_upgrade: int) -> int:
	var t: int = clampi(tier_before_upgrade, 0, 10)
	return maxi(0, int(round(float(BUILDING_UPGRADE_ORE_STEP) * float(t + 1) * _economy_mult() * CrownSystem.get_building_cost_crown_mult())))


func _crown_service_mult() -> float:
	return get_supply_service_cost_mult(SaveManager.crown_displeasure, SaveManager.crown_favor)


func get_armory_sword_buff_cost() -> int:
	return maxi(1, int(round(float(ARMORY_SWORD_BUFF_COST) * _service_price_mult() * _crown_service_mult())))


func get_armory_shield_buff_cost() -> int:
	return maxi(1, int(round(float(ARMORY_SHIELD_BUFF_COST) * _service_price_mult() * _crown_service_mult())))


func get_monastery_revive_gold_cost() -> int:
	return maxi(1, int(round(float(MONASTERY_REVIVE_GOLD_COST) * _service_price_mult() * _crown_service_mult())))


func get_monastery_revive_ore_cost() -> int:
	return maxi(1, int(round(float(MONASTERY_REVIVE_ORE_COST) * _service_price_mult())))


func get_monastery_vitality_gold_cost() -> int:
	return maxi(1, int(round(float(MONASTERY_VITALITY_GOLD_COST) * _service_price_mult() * _crown_service_mult())))


func get_monastery_vitality_ore_cost() -> int:
	return maxi(1, int(round(float(MONASTERY_VITALITY_ORE_COST) * _service_price_mult())))


func get_archery_volley_gold_cost() -> int:
	return maxi(1, int(round(float(ARCHERY_VOLLEY_GOLD_COST) * _service_price_mult() * _crown_service_mult())))


func get_archery_volley_ore_cost() -> int:
	return maxi(1, int(round(float(ARCHERY_VOLLEY_ORE_COST) * _service_price_mult())))


func get_archery_guard_gold_cost() -> int:
	return maxi(1, int(round(float(ARCHERY_GUARD_GOLD_COST) * _service_price_mult() * _crown_service_mult())))


func get_archery_guard_ore_cost() -> int:
	return maxi(1, int(round(float(ARCHERY_GUARD_ORE_COST) * _service_price_mult())))


func get_exp_to_next_level(hero_level: int) -> int:
	var L := clampi(hero_level, 1, MAX_HERO_LEVEL)
	if L >= MAX_HERO_LEVEL:
		return 0
	var base_xp_same_level := float(EXP_REWARD_BASE + EXP_PER_ENEMY_LEVEL * L)
	var v := base_xp_same_level * float(TARGET_KILLS_PER_LEVEL)
	v *= DifficultyConfig.get_exp_to_next_level_mult()
	return maxi(1, int(round(v)))


func get_enemy_stat_multiplier(enemy_level: int) -> float:
	var L := clampi(enemy_level, 1, 99)
	return pow(ENEMY_STAT_PER_LEVEL, float(L - 1)) * DifficultyConfig.get_enemy_stat_mult()


## Множитель макс. HP всех врагов (после базы сцены и get_enemy_stat_multiplier); задаётся пресетом сложности.
func get_enemy_hp_global_mult() -> float:
	return DifficultyConfig.get_enemy_hp_global_mult()


## Урон по врагу от героя/союзников: если враг выше уровнем — сильный штраф (считаем уровень героя из сохранения).
func get_incoming_damage_factor_vs_enemy(enemy_level: int) -> float:
	var hero_lv := clampi(SaveManager.current_level, 1, MAX_HERO_LEVEL)
	var gap := enemy_level - hero_lv
	var f := 1.0 - UNDERLEVEL_DAMAGE_PER_GAP * float(gap)
	f *= DifficultyConfig.get_vs_higher_enemy_damage_mult()
	f *= get_crown_vs_higher_enemy_damage_mult(SaveManager.ore_sent_to_crown_total)
	return clampf(f, UNDERLEVEL_DAMAGE_FLOOR, UNDERLEVEL_DAMAGE_BONUS_CAP)


## Урон врага по герою/союзникам: если враг выше уровнем — заметно больнее (идти на остров без уровня опасно).
## Множитель сложности `enemy_damage_to_player_mult` применяется и при gap=0.
func get_enemy_outgoing_damage_vs_hero(enemy_level: int) -> float:
	var hero_lv := clampi(SaveManager.current_level, 1, MAX_HERO_LEVEL)
	var gap := clampi(enemy_level - hero_lv, 0, 12)
	var base := 1.0
	if gap > 0:
		base = minf(ENEMY_DAMAGE_VS_LOWER_HERO_CAP, pow(ENEMY_DAMAGE_VS_LOWER_HERO_PER_GAP, float(gap)))
	return (
		base
		* DifficultyConfig.get_enemy_damage_to_player_mult()
		* get_crown_combat_incoming_damage_taken_mult()
	)


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
	xp = int(round(float(xp) * (1.0 + get_crown_exp_bonus_ratio(SaveManager.ore_sent_to_crown_total))))
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

func get_mine_ore_per_return(mine_tier: int, pawns_on_base: int) -> int:
	var from_tier := MINE_BASE_ORE_PER_RETURN + MINE_ORE_PER_TIER * clampi(mine_tier, 0, 4)
	var from_pawns := MINE_ORE_PER_PAWN_ON_BASE * clampi(pawns_on_base, 0, MINE_MAX_PAWN_BONUS)
	var raw := from_tier + from_pawns
	var v := int(round(float(raw) * DifficultyConfig.get_mine_yield_mult()))
	return maxi(1, v)


## ─── Провизия ───

func get_expedition_meat_cost(warrior_count: int) -> int:
	return maxi(1, int(round(float(EXPEDITION_BASE_MEAT_COST + EXPEDITION_MEAT_PER_WARRIOR * maxi(0, warrior_count)) * _economy_mult())))


func get_rest_heal_amount(max_health: int) -> int:
	var r := float(max_health) * REST_HEAL_RATIO * DifficultyConfig.get_rest_heal_ratio_mult()
	return maxi(1, int(round(r)))


## ─── Караван ───

func get_caravan_supply_gold() -> int:
	return maxi(1, int(round(float(CARAVAN_SUPPLY_GOLD_BASE) * _economy_mult())))


func get_caravan_supply_meat() -> int:
	return CARAVAN_SUPPLY_MEAT_BASE


func get_crown_order(order_index: int) -> Dictionary:
	for o in CROWN_ORDERS:
		if o is Dictionary and int(o.get("index", -1)) == order_index:
			var d := (o as Dictionary).duplicate()
			var base_ore := int(d.get("ore_required", 0))
			d["ore_required"] = maxi(1, int(round(float(base_ore) * DifficultyConfig.get_crown_ore_required_mult())))
			return d
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


func crown_title_tier_has_patent(tier: int) -> bool:
	if tier < 1 or tier >= CROWN_TITLES.size():
		return false
	var raw: Variant = CROWN_TITLES[tier].get("patent_lines", null)
	return raw is Array and not (raw as Array).is_empty()


## Текст грамоты для кодекса «Предметы» (совпадает по содержанию с окном грамоты).
func build_crown_patent_letter_plain_text(tier: int) -> String:
	if not crown_title_tier_has_patent(tier):
		return ""
	var t: Dictionary = CROWN_TITLES[tier]
	var parts: PackedStringArray = []
	var raw: Variant = t.get("patent_lines", null)
	if raw is Array:
		for p in raw as Array:
			var s := str(p).strip_edges()
			if not s.is_empty():
				parts.append(s)
	var hero := str(t.get("patent_hero_line", "")).strip_edges()
	var body := "\n\n".join(parts)
	var out := (
		"Милорд, вот что канцелярия заверила под печатью. Читайте без спешки — сургуч не любит суеты.\n\n"
		+ "───────────────\n\n"
		+ body
	)
	if not hero.is_empty():
		out += "\n\n— %s" % hero
	var bonus_lines := crown_title_bonus_summary_lines(t)
	if not bonus_lines.is_empty():
		out += "\n\n───────────────\n\nУставные льготы по титулу:\n"
		for bl in bonus_lines:
			out += "\n• %s" % bl
	return out


## Краткий перечень игровых бонусов титула (замок, грамота, кодекс).
func crown_title_bonus_summary_lines(title: Dictionary) -> PackedStringArray:
	var lines: PackedStringArray = []
	var gold_r := float(title.get("gold_bonus_ratio", 0.0))
	var ore_cap := int(title.get("expedition_ore_carry_bonus", 0))
	var disc := float(title.get("service_discount", 0.0))
	var chp := int(title.get("combat_hp_bonus", 0))
	var cin := float(title.get("combat_incoming_damage_mult", 1.0))
	var cdmg := float(title.get("combat_hero_damage_mult", 1.0))
	var cspd := float(title.get("combat_speed_bonus", 0.0))
	var xpr := float(title.get("exp_bonus_ratio", 0.0))
	var cvh := float(title.get("combat_vs_higher_enemy_mult", 1.0))
	if gold_r > 0.001:
		lines.append("+%d%% к золоту в жалованье каравана" % int(round(gold_r * 100.0)))
	if disc > 0.001:
		lines.append("Скидка на улучшения зданий: %d%%" % int(round(disc * 100.0)))
	if ore_cap > 0:
		lines.append("Лимит Сердцевины с одного похода на остров: +%d (грамота Короны на вывоз)" % ore_cap)
	if chp > 0:
		lines.append("Бой: +%d к макс. здоровью героя" % chp)
	if cin < 0.999:
		var pct := int(round((1.0 - cin) * 100.0))
		lines.append("Бой: на %d%% меньше урона от врагов (ещё чуть меньше при одобрении Короны)" % pct)
	if cdmg > 1.001:
		lines.append("Бой: +%d%% к урону героя в ближнем бою" % int(round((cdmg - 1.0) * 100.0)))
	if cspd > 0.5:
		lines.append("Бой: +%d к скорости передвижения" % int(round(cspd)))
	if xpr > 0.001:
		lines.append("+%d%% к опыту за убийства" % int(round(xpr * 100.0)))
	if cvh > 1.001:
		lines.append("Бой: сильнее удар по врагам выше вашего уровня (+%d%% к множителю)" % int(round((cvh - 1.0) * 100.0)))
	if lines.is_empty():
		lines.append("Нет бонусов к жалованью, лимиту вывоза и скидкам — появятся на следующих ступенях.")
	return lines


func get_crown_gold_bonus_ratio(ore_sent_total: int) -> float:
	return float(get_crown_title_for_ore_sent(ore_sent_total).get("gold_bonus_ratio", 0.0))


func get_crown_service_discount(ore_sent_total: int) -> float:
	return float(get_crown_title_for_ore_sent(ore_sent_total).get("service_discount", 0.0))


## Сколько ещё Сердцевины можно унесть с острова за один поход (сверх капа сложности).
func get_crown_expedition_ore_carry_bonus(ore_sent_total: int) -> int:
	return maxi(0, int(get_crown_title_for_ore_sent(ore_sent_total).get("expedition_ore_carry_bonus", 0)))


## ─── Титул: упрощение боя (герой) ───

func get_crown_combat_hp_bonus(ore_sent_total: int) -> int:
	return maxi(0, int(get_crown_title_for_ore_sent(ore_sent_total).get("combat_hp_bonus", 0)))


func get_crown_title_incoming_damage_base_mult(ore_sent_total: int) -> float:
	return clampf(
		float(get_crown_title_for_ore_sent(ore_sent_total).get("combat_incoming_damage_mult", 1.0)),
		CROWN_COMBAT_INCOMING_MULT_MIN,
		1.0
	)


## Итоговый множитель урона по герою от атак врагов: титул + лёгкий бонус одобрения.
func get_crown_combat_incoming_damage_taken_mult() -> float:
	var base := get_crown_title_incoming_damage_base_mult(SaveManager.ore_sent_to_crown_total)
	var fav := clampi(SaveManager.crown_favor, 0, CROWN_FAVOR_MAX_LEVEL)
	var from_favor := 1.0 - CROWN_FAVOR_INCOMING_REDUCTION_PER_LEVEL * float(fav)
	return maxf(CROWN_COMBAT_INCOMING_MULT_MIN, base * from_favor)


func get_crown_combat_hero_damage_mult(ore_sent_total: int) -> float:
	return clampf(float(get_crown_title_for_ore_sent(ore_sent_total).get("combat_hero_damage_mult", 1.0)), 1.0, 1.3)


func get_crown_combat_speed_bonus(ore_sent_total: int) -> float:
	return maxf(0.0, float(get_crown_title_for_ore_sent(ore_sent_total).get("combat_speed_bonus", 0.0)))


func get_crown_exp_bonus_ratio(ore_sent_total: int) -> float:
	return maxf(0.0, float(get_crown_title_for_ore_sent(ore_sent_total).get("exp_bonus_ratio", 0.0)))


## Урон героя по врагу выше уровнем (множитель к фактору из get_incoming_damage_factor_vs_enemy).
func get_crown_vs_higher_enemy_damage_mult(ore_sent_total: int) -> float:
	return clampf(float(get_crown_title_for_ore_sent(ore_sent_total).get("combat_vs_higher_enemy_mult", 1.0)), 1.0, 1.22)


## ─── Немилость (совместимость UI: только штраф, без одобрения) ───

func get_displeasure_gold_mult(displeasure_level: int) -> float:
	return get_crown_caravan_gold_mult(displeasure_level, 0)


func get_displeasure_building_cost_mult(displeasure_level: int) -> float:
	return get_crown_building_cost_mult(displeasure_level, 0)


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
	var d := clampi(displeasure, 0, DISPLEASURE_MAX_LEVEL)
	var f := clampi(favor, 0, CROWN_FAVOR_MAX_LEVEL)
	if d > 0:
		m -= SUPPLY_HEAL_PENALTY_PER_DISPLEASURE * float(d) * _crown_wallet_penalty_w()
	elif f > 0:
		m += SUPPLY_HEAL_BONUS_PER_FAVOR * float(f) * _crown_wallet_favor_w()
	return clampf(m, 0.32, 1.58)


func get_supply_rest_mult(displeasure: int, favor: int) -> float:
	var m := 1.0
	var d := clampi(displeasure, 0, DISPLEASURE_MAX_LEVEL)
	var f := clampi(favor, 0, CROWN_FAVOR_MAX_LEVEL)
	if d > 0:
		m -= SUPPLY_REST_PENALTY_PER_DISPLEASURE * float(d) * _crown_wallet_penalty_w()
	elif f > 0:
		m += SUPPLY_REST_BONUS_PER_FAVOR * float(f) * _crown_wallet_favor_w()
	return clampf(m, 0.32, 1.58)


func get_supply_service_cost_mult(displeasure: int, favor: int) -> float:
	var m := 1.0
	var d := clampi(displeasure, 0, DISPLEASURE_MAX_LEVEL)
	var f := clampi(favor, 0, CROWN_FAVOR_MAX_LEVEL)
	if d > 0:
		m += SUPPLY_SERVICE_COST_PER_DISPLEASURE * float(d) * _crown_wallet_penalty_w()
	elif f > 0:
		m -= SUPPLY_SERVICE_DISCOUNT_PER_FAVOR * float(f) * _crown_wallet_favor_w()
	return maxf(0.55, m)


func get_supply_archer_damage_mult(displeasure: int, favor: int) -> float:
	var m := 1.0
	var d := clampi(displeasure, 0, DISPLEASURE_MAX_LEVEL)
	var f := clampi(favor, 0, CROWN_FAVOR_MAX_LEVEL)
	if d > 0:
		m -= SUPPLY_ARCHER_DAMAGE_PER_DISPLEASURE * float(d) * _crown_wallet_penalty_w()
	elif f > 0:
		m += SUPPLY_ARCHER_DAMAGE_PER_FAVOR * float(f) * _crown_wallet_favor_w()
	return clampf(m, 0.65, 1.35)


## ─── Износ снаряжения ───


func get_armor_block_penalty(durability: int) -> float:
	var d := clampi(durability, 0, ARMOR_MAX_DURABILITY)
	if d <= ARMOR_CRITICAL_THRESHOLD:
		return ARMOR_CRITICAL_BLOCK_PENALTY
	if d <= ARMOR_WORN_THRESHOLD:
		return ARMOR_WORN_BLOCK_PENALTY
	return 0.0


func get_armor_broken_incoming_damage_mult(durability: int) -> float:
	if clampi(durability, 0, ARMOR_MAX_DURABILITY) <= 0:
		return ARMOR_BROKEN_INCOMING_DAMAGE_MULT
	return 1.0


func get_armor_repair_gold_cost(displeasure: int, favor: int) -> int:
	var m := 1.0
	var d := clampi(displeasure, 0, DISPLEASURE_MAX_LEVEL)
	var f := clampi(favor, 0, CROWN_FAVOR_MAX_LEVEL)
	if d > 0:
		m += ARMOR_REPAIR_COST_PER_DISPLEASURE * float(d) * _crown_wallet_penalty_w()
	elif f > 0:
		m -= ARMOR_REPAIR_DISCOUNT_PER_FAVOR * float(f) * _crown_wallet_favor_w()
	return maxi(1, int(round(float(ARMOR_REPAIR_GOLD_COST) * maxf(0.45, m) * _service_price_mult())))


func get_armor_repair_ore_cost(displeasure: int, favor: int) -> int:
	var m := 1.0
	var d := clampi(displeasure, 0, DISPLEASURE_MAX_LEVEL)
	var f := clampi(favor, 0, CROWN_FAVOR_MAX_LEVEL)
	if d > 0:
		m += ARMOR_REPAIR_COST_PER_DISPLEASURE * float(d) * _crown_wallet_penalty_w() * 0.5
	elif f > 0:
		m -= ARMOR_REPAIR_DISCOUNT_PER_FAVOR * float(f) * _crown_wallet_favor_w() * 0.5
	return maxi(0, int(round(float(ARMOR_REPAIR_ORE_COST) * maxf(0.45, m) * _service_price_mult())))


func get_max_ore_per_expedition() -> int:
	var base := maxi(1, int(round(float(MAX_ORE_PER_EXPEDITION) * DifficultyConfig.get_expedition_carry_cap_mult())))
	return base + get_crown_expedition_ore_carry_bonus(SaveManager.ore_sent_to_crown_total)


func get_max_wood_per_expedition() -> int:
	return maxi(1, int(round(float(MAX_WOOD_PER_EXPEDITION) * DifficultyConfig.get_expedition_carry_cap_mult())))


func get_max_meat_per_expedition() -> int:
	return maxi(1, int(round(float(MAX_MEAT_PER_EXPEDITION) * DifficultyConfig.get_expedition_carry_cap_mult())))
