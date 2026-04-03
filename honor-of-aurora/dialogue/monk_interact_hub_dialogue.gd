extends DialogueSequence
class_name MonkInteractHubDialogue

## Корень: сюжет мира, личное о целителе, бантер, уход. Вложенные меню — вопросы с разблокировкой по флагам.
## Флаги: monk_hub_def_story, monk_hub_def_banter


func ensure_lines_ready() -> void:
	if not lines.is_empty():
		return
	## С прошлого сеанса мог остаться флаг (вылет до конца хаба) — не цеплять truth_and_choice без выбора пункта.
	StoryState.clear_flag("monk_hub_queue_truth_choice")
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
	if DialogueRegistry.can_play("truth_and_choice"):
		opts.append({
			"label": "Последний страж. Нужно сказать тебе своё решение.",
			"grant_flags": PackedStringArray(["monk_hub_queue_truth_choice"]),
			"continuation": [
				["healer", "Садись. Я не закончил тот разговор — и ты тоже. Говори, как есть."],
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
	if StoryState.has_flag("worker_youth_intro_done") and not StoryState.has_flag("worker_youth_recruited") and not StoryState.has_flag("worker_youth_dead"):
		opts.append({
			"label": "Юноша хочет в поход. Что думаешь?",
			"grant_flags": PackedStringArray([]),
			"continuation": [
				["healer", "Не бери его. Я это не прошу — я требую."],
				["healer", "Он думает, что поход — это слава и байки на обратном пути. Нет. Поход — это грязь, кровь и крик, который не помещается в горло. Он не обучен, не закалён, не готов."],
				["healer", "На базе он нужнее: руда, склад, смены. Живой и при деле. Лишние руки на острове не бывают. А вот лишние могилы — сколько угодно."],
				["healer", "Ты потерял людей на переправе — сам рассказал. Не повторяй. Этот юноша — не твой шанс на искупление. Он — чужая жизнь."],
			],
		})
	if StoryState.has_flag("worker_youth_recruited") and not StoryState.has_flag("worker_youth_dead"):
		opts.append({
			"label": "Как юноша? Ты за ним присматриваешь?",
			"grant_flags": PackedStringArray([]),
			"continuation": [
				["healer", "Присматриваю? Я делаю больше, чем должен. Сам не знаю зачем."],
				["healer", "Он приходит вечером — спрашивает про травы. Не потому что интересно. Потому что ему нужен кто-то, кто будет слушать. Мать далеко, отец… он сказал, что отец стучал пальцем по столу, когда думал. Я поймал себя на том, что стал делать так же."],
				["healer", "Держи его позади в бою. После каждого похода — ко мне, сразу. Обещай."],
			],
		})
	if StoryState.has_flag("worker_youth_dead"):
		opts.append({
			"label": "Юноша погиб. Я виноват.",
			"grant_flags": PackedStringArray([]),
			"continuation": [
				["healer", "Не говори мне «виноват». Я это слово слышу шестой раз за жизнь — и каждый раз от тех, кто мог выбрать иначе, но не стал."],
				["healer", "Я знал, что это случится. С первого дня, как ты взял его. Я готовил себя. И всё равно — когда ты сказал… Руки перестали слушаться. Я целитель. Руки — это всё, что у меня есть."],
				["healer", "Знаешь, что самое страшное? Я привязался. Я не имел права — но привязался. Он приходил вечером, спрашивал глупости про травы, рассказывал про сестру. Я слушал — и представлял, что Лиан вот так же кому-то рассказывает про меня."],
				["healer", "Запомни его. Не как урок. Как имя."],
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
	if SaveManager.crown_title_index >= 3:
		opts.append({
			"label": "Корона повысила меня. Я теперь Рыцарь Сердцевины.",
			"grant_flags": PackedStringArray([]),
			"continuation": [
				["healer", "Корона повысила тебя. Это должно льстить."],
				["healer", "Но помни — каждый мешок руды, который ты отправил, питает маяки. А маяки стоят на фундаменте, который ты сам разбираешь. Мечом."],
				["healer", "Титул — это просто способ дворца сказать «продолжай». Не путай его с благодарностью."],
			],
		})
	elif SaveManager.crown_title_index >= 1 and SaveManager.crown_title_index < 3:
		opts.append({
			"label": "Корона наградила меня титулом за руду.",
			"grant_flags": PackedStringArray([]),
			"continuation": [
				["healer", "Титулы от короны — как бинты от казначея: тонкие, но пахнут официально."],
				["healer", "Руда нужна маякам. Маяки нужны торговцам. Торговцы нужны казне. Ты — в начале цепи. Корона — в конце. Догадайся, кто из вас заменим."],
			],
		})
	if SaveManager.crown_displeasure >= 2:
		opts.append({
			"label": "Корона урезает снабжение. Что делать?",
			"grant_flags": PackedStringArray([]),
			"continuation": [
				["healer", "Отправь руду. Много. Больше, чем просят. Дворец понимает только один язык — мешки."],
				["healer", "Немилость — не наказание. Это напоминание, что для них мы — часть рудника. Не люди. Шестерёнки."],
			],
		})
	if SaveManager.caravan_pending:
		opts.append({
			"label": "Караван ждёт. Сколько руды отправить?",
			"grant_flags": PackedStringArray([]),
			"continuation": [
				["healer", "Сколько можешь — столько и грузи. Остаток пойдёт на базу. Но помни: корона считает. И корона не забывает."],
				["healer", "Если можешь отправить больше, чем просят — сделай. Немилость снимается щедростью. Циничной, но работающей."],
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
		"label": "Почему ты у церкви, а не с мечом на островах?",
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
				["healer", "Страшнее боя. В бою я знаю правила. Снять латы с лица — это не орден, а человек. Я учусь этому здесь: в церкви нет героя — только тот, кто не отпускает руку, пока другой снова дышит."],
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
	if StoryState.has_flag("worker_youth_recruited") and not StoryState.has_flag("worker_youth_dead"):
		opts.append({
			"label": "Ты привязался к юноше. Я вижу.",
			"grant_flags": PackedStringArray([]),
			"continuation": [
				["healer", "…Нет. Я просто… делаю свою работу."],
				["hero", "Ты три раза за неделю проверял его температуру. Он не болел."],
				["healer", "У меня нет детей рядом. Лиан — за морем. А тут — мальчишка, который стучит пальцем по столу, как делал его отец, и спрашивает, зачем мята в отваре. Я не отец ему. Но руки делают то, что делал бы отец. Я не могу это остановить. И не хочу."],
			],
		})
	if StoryState.has_flag("worker_youth_dead"):
		opts.append({
			"label": "Ты скучаешь по юноше?",
			"grant_flags": PackedStringArray([]),
			"continuation": [
				["healer", "Не произноси «скучаешь». Это слово для тех, кто потерял шляпу."],
				["healer", "Я потерял возможность. Возможность быть тем, кем не был для Лиан. Рядом. Каждый день. Проверять, поел ли. Слушать глупости. Ворчать, что опять не надел куртку."],
				["healer", "Он не был мне сыном. Но он был первым за пять лет, для кого я был не «целитель при экспедиции», а просто — взрослый, который рядом. И теперь этого «рядом» — нет. Для нас обоих."],
				["healer", "Вечером я всё ещё слышу шаги к палатке. Это ветер. Но я оборачиваюсь."],
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
			["healer", "Понял. Есть вещи, которые лучше сказать в тишине храма, чем вслух."],
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
