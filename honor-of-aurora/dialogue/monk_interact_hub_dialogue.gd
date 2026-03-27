extends DialogueSequence
class_name MonkInteractHubDialogue

## Корень: сюжет мира, личное о целителе, бантер, уход. Вложенные меню — вопросы с разблокировкой по флагам.
## Флаги: monk_hub_def_story, monk_hub_def_banter


func ensure_lines_ready() -> void:
	if not lines.is_empty():
		return
	id = "monk_interact_hub"
	lines.append(_choice("healer", "Странник… Выбери, о чём речь.", _build_root_options()))


func _build_root_options() -> Array:
	return [
		{
			"label": "Сюжет: что происходит и новости.",
			"grant_flags": PackedStringArray([]),
			"continuation": [_build_story_questions_submenu()],
		},
		{
			"label": "О тебе: судьба, семья, орден.",
			"grant_flags": PackedStringArray([]),
			"continuation": [_build_monk_personal_submenu()],
		},
		{
			"label": "Просто поболтать.",
			"grant_flags": PackedStringArray(["monk_hub_def_banter"]),
			"continuation": [
				["healer", "Хорошо. Только не жди поэзии — котёл отвлекает."],
			],
		},
		{
			"label": "Уйти.",
			"grant_flags": PackedStringArray([]),
			"continuation": [
				["healer", "Иди. Огонь никуда не денется. Я — тоже."],
			],
		},
	]


func _build_story_questions_submenu() -> DialogueChoiceLine:
	return _choice("healer", "О чём напомнить?", _build_story_question_option_dicts())


func _build_story_question_option_dicts() -> Array:
	var opts: Array = []
	opts.append({
		"label": "Зачем корона прислала меня на Аврору?",
		"grant_flags": PackedStringArray([]),
		"continuation": [
			["healer", "По указу — зачистить острова от стражей и открыть рудники с сердцевиной. Маяки на материке гаснут без этой руды, торговые пути слепнут. Официально ты — освободитель. Неофициально… это сложнее."],
		],
	})
	if StoryState.has_flag("intro_base_island_done"):
		opts.append({
			"label": "Что здесь за база и причал?",
			"grant_flags": PackedStringArray([]),
			"continuation": [
				["healer", "Главный остров — лагерь экспедиции Ордена Тихой Зари. С причала ходят лодки к другим островам. Корабль ушёл: мы остались. Шахта под лагерем — часть той же системы, что и острова."],
			],
		})
	if StoryState.has_flag("boss_post_1_done"):
		opts.append({
			"label": "Клеймо на страже — это знак ордена?",
			"grant_flags": PackedStringArray([]),
			"continuation": [
				["healer", "Восьмиконечная звезда. Знак Ордена Тихой Зари. Мой орден. Стражей поставили наши предшественники — столетия назад, чтобы Заря под архипелагом не просыпалась. Корона об этом знает. И всё равно послала тебя."],
			],
		})
	if StoryState.has_flag("boss_post_2_done"):
		opts.append({
			"label": "Почему на карте шахта, которой не оказалось?",
			"grant_flags": PackedStringArray([]),
			"continuation": [
				["healer", "Казначей нарисовал шахту, чтобы указ выглядел экономическим проектом. В реальности руда под островами недоступна, пока стоят стражи. Корона знала это заранее."],
			],
		})
	if StoryState.has_flag("boss_post_3_done"):
		opts.append({
			"label": "Что за Заря? Что спит под архипелагом?",
			"grant_flags": PackedStringArray([]),
			"continuation": [
				["healer", "Не богиня. Не демон. Сила — древнее слов для неё. Старые тексты ордена зовут её «первый свет в волне». Она дала архипелагу имя. Стражи держали её сон. С каждым убитым стражем сон тоньше. Что будет, когда она проснётся, — не знает никто."],
			],
		})
	if StoryState.has_flag("truth_and_choice_done"):
		opts.append({
			"label": "Почему ты признался мне только после четырёх островов?",
			"grant_flags": PackedStringArray([]),
			"continuation": [
				["healer", "Потому что я — трус. Каждый остров приближал мой отпуск к дочери. Я боялся, что ты остановишься, если узнаешь правду раньше. Прости. Или не прощай — это твоё право."],
			],
		})
	if StoryState.has_flag("worker_youth_dead"):
		opts.append({
			"label": "Ты предупреждал про юношу. Я не послушал.",
			"grant_flags": PackedStringArray([]),
			"continuation": [
				["healer", "Я не буду говорить «я был прав». Это слово для тех, кому легче от чужой боли. Мне не легче. Запомни его — не как урок, а как имя. Это всё, что я могу."],
			],
		})
	if StoryState.has_flag("veteran_archer_intro_done"):
		opts.append({
			"label": "Что ты думаешь о старом лучнике у стрельбища?",
			"grant_flags": PackedStringArray([]),
			"continuation": [
				["healer", "Бран? Он был здесь до меня. До базы. До всего. Пятнадцать лет на этих камнях — и ни разу не попросился домой. Потому что некуда. Я уважаю его стойкость. Но не доверяю его выводам."],
				["healer", "Он видел стражей как врагов — потому что они убили его друзей. Я вижу их как замки — потому что читал тексты ордена. Правда — где-то между нами. Ты решай, кому ближе."],
			],
		})
	opts.append({
		"label": "Слушать сюжетные сцены (новости островов).",
		"grant_flags": PackedStringArray(["monk_hub_def_story"]),
		"continuation": [
			["healer", "Хорошо. Слушай — иногда важнее то, что между строк, а не сами слова."],
		],
	})
	return opts


func _build_monk_personal_submenu() -> DialogueChoiceLine:
	return _choice("healer", "Спрашивай. Только помни: не всё, что лечится, любит свет.", _build_monk_personal_option_dicts())


func _build_monk_personal_option_dicts() -> Array:
	var opts: Array = []
	opts.append({
		"label": "Почему ты у огня, а не с мечом на островах?",
		"grant_flags": PackedStringArray([]),
		"continuation": [
			["healer", "Клятва Ордена Тихой Зари: не навреди. Не «победи» — не навреди. Я держу раны, а не головы. Контракт привязывает меня к базе «до стабилизации узлов». Красивые слова без даты."],
		],
	})
	if StoryState.has_flag("intro_base_island_done"):
		opts.append({
			"label": "Кого ты оставил дома?",
			"grant_flags": PackedStringArray([]),
			"continuation": [
				["healer", "Жену — но её уже нет. Дочь — но я думал, что и её нет. Людей, которые ждали меня за порогом, а получили пустой стул и письмо с печатью ордена."],
			],
		})
	if StoryState.has_flag("monk_story_1_done"):
		opts.append({
			"label": "Контракт ордена с короной — что в нём на самом деле?",
			"grant_flags": PackedStringArray([]),
			"continuation": [
				["healer", "«Содействовать экспедиции до стабилизации узлов». Без срока. Раньше это значило — следить, чтобы стражи стояли. Теперь, после нового указа, — помогать их снять. Орден подписал оба текста. И я вместе с ним."],
			],
		})
	if StoryState.has_flag("monk_story_2_done"):
		opts.append({
			"label": "Ты признался, что не можешь быть объективным. Как мне тебе верить?",
			"grant_flags": PackedStringArray([]),
			"continuation": [
				["healer", "Проверяй всё, что я говорю. Записки ордена лежат в сундуках на островах — читай сам. Я дал тебе правду и свою слабость в одном пакете. Разбери — что от чего."],
			],
		})
	if StoryState.has_flag("monk_story_3_done"):
		opts.append({
			"label": "Кто такая Лиан?",
			"grant_flags": PackedStringArray([]),
			"continuation": [
				["healer", "Моя дочь. Ей было семь, когда меня отправили. Пришёл слух — «ребёнка не нашли». Я похоронил её словом. А потом пришло письмо: «Я жива». И мир перевернулся."],
			],
		})
	if StoryState.has_flag("monk_story_4_done"):
		opts.append({
			"label": "Ты уверен, что письма настоящие, а не уловка короны?",
			"grant_flags": PackedStringArray([]),
			"continuation": [
				["healer", "Нет. Не уверен. Но если я перестану верить в них — у меня не останется причины держаться. А целитель без причины — опасен."],
			],
		})
	if StoryState.has_flag("monk_letter_1_read"):
		opts.append({
			"label": "Как ты пережил первое письмо от неё?",
			"grant_flags": PackedStringArray([]),
			"continuation": [
				["healer", "Сначала смеялся — как дурак. Потом плакал так, что стыдно было перед котлом. Каждое слово в том письме — как шов: держит, даже когда кожа натянута до боли."],
			],
		})
	if StoryState.has_flag("monk_story_5_done"):
		opts.append({
			"label": "Твоя свобода зависит от моего решения. Это давит.",
			"grant_flags": PackedStringArray([]),
			"continuation": [
				["healer", "Знаю. И прости. Я не имею права на тебя давить — но я и солгать не могу. Один акт — и я свободен. Или один отказ — и я здесь навсегда. Это не шантаж. Это правда, которая звучит как шантаж."],
			],
		})
	if StoryState.has_flag("monk_letter_2_read"):
		opts.append({
			"label": "Она просит приехать «без маски героя». Что это для тебя?",
			"grant_flags": PackedStringArray([]),
			"continuation": [
				["healer", "Страшнее боя. В бою я знаю правила. Снять латы с лица — это не орден, а человек. Я учусь этому у огня: здесь нет героя — есть только тот, кто держит тепло."],
			],
		})
	if StoryState.has_flag("truth_and_choice_done") and StoryState.has_flag("hero_chose_finish_chain"):
		opts.append({
			"label": "Ты рад, что я согласился идти на последний остров?",
			"grant_flags": PackedStringArray([]),
			"continuation": [
				["healer", "Рад — и стыжусь этой радости. Потому что знаю: ты идёшь не ради меня. Но мой билет домой лежит в том же конверте, что и твой подвиг. Я не выбирал такую связку. И ты — не выбирал."],
			],
		})
	if StoryState.has_flag("hero_chose_refuse_chain") and StoryState.has_flag("truth_and_choice_done"):
		opts.append({
			"label": "Ты злишься на меня за отказ?",
			"grant_flags": PackedStringArray([]),
			"continuation": [
				["healer", "Нет. Клятва «не навреди» — про чужих, которых я не вижу. А про свою кровь режет глубже. Ты выбрал чистые руки. Я остаюсь с надеждой без дороги. Это не злость. Это пустота в разных карманах."],
			],
		})
	if StoryState.has_flag("worker_youth_dead"):
		opts.append({
			"label": "Ты думаешь о юноше?",
			"grant_flags": PackedStringArray([]),
			"continuation": [
				["healer", "Каждый день. Не потому что «я предупреждал». А потому что он был похож на того, кем я был до ордена. Молодой. Горящий. Уверенный, что мир подождёт, пока он набежит. Мир не подождал."],
			],
		})
	if StoryState.has_flag("monk_story_6_done"):
		opts.append({
			"label": "Цепь замкнулась. Что чувствуешь?",
			"grant_flags": PackedStringArray([]),
			"continuation": [
				["healer", "Облегчение и страх. Указ выполнен. А я впервые дышу ровно — и всё равно прислушиваюсь к шагам, которых ещё нет. Дорога к дочери — не награда дворца. Это мой долг к себе."],
			],
		})
	opts.append({
		"label": "Хватит личного.",
		"grant_flags": PackedStringArray([]),
		"continuation": [
			["healer", "Понял. Есть вещи, которые лучше у огня, а не вслух."],
		],
	})
	return opts


func _plain(speaker_id: String, text: String) -> DialogueLine:
	var l := DialogueLine.new()
	l.speaker_id = speaker_id
	l.text = text
	return l


func _choice(speaker_id: String, prompt: String, option_dicts: Array) -> DialogueChoiceLine:
	var cl := DialogueChoiceLine.new()
	cl.speaker_id = speaker_id
	cl.text = prompt
	for d in option_dicts:
		if not d is Dictionary:
			continue
		var opt := DialogueChoiceOption.new()
		opt.label = str(d.get("label", ""))
		var gf: Variant = d.get("grant_flags", [])
		if gf is PackedStringArray:
			opt.grant_flags = gf
		elif gf is Array:
			opt.grant_flags = PackedStringArray(gf)
		var cont_lines: Array[DialogueLine] = []
		var cont: Variant = d.get("continuation", [])
		if cont is Array:
			for row in cont:
				if row is DialogueChoiceLine:
					cont_lines.append(row)
				elif row is Array and row.size() >= 2:
					cont_lines.append(_plain(str(row[0]), str(row[1])))
		opt.continuation = cont_lines
		cl.options.append(opt)
	return cl
