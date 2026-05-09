extends DialogueSequence
class_name VeteranArcherHubDialogue

## Хаб ветерана-лучника у стрельбища. Корень: Сюжет, О себе, Про монаха, Бантер, Уход.


func ensure_lines_ready() -> void:
	if not lines.is_empty():
		return
	id = "veteran_archer_hub"
	lines.append(_choice("veteran", "Рыцарь. О чём хочешь говорить?", _build_root_options()))


func _build_root_options() -> Array:
	return [
		{
			"label": "Сюжет: острова, стражи, корона.",
			"grant_flags": PackedStringArray([]),
			"continuation": [_build_story_submenu()],
		},
		{
			"label": "О тебе: кто ты и что здесь делаешь.",
			"grant_flags": PackedStringArray([]),
			"continuation": [_build_personal_submenu()],
		},
		{
			"label": "Просто поговорить.",
			"grant_flags": PackedStringArray([]),
			"continuation": [
				["veteran", "Говорить я умею хуже, чем стрелять. Но ладно — спрашивай."],
			],
		},
		{
			"label": "Уйти.",
			"grant_flags": PackedStringArray([]),
			"continuation": [
				["veteran", "Иди. Мишени никуда не денутся — и я тоже."],
			],
		},
	]


func _build_story_submenu() -> DialogueChoiceLine:
	return _choice("veteran", "Что именно?", _build_story_option_dicts())


func _build_story_option_dicts() -> Array:
	var opts: Array = []
	opts.append({
		"label": "Что ты знаешь про указ короля?",
		"grant_flags": PackedStringArray([]),
		"continuation": [
			["veteran", "Указ прост: зачистить острова, открыть глубокие жилы. Маяки на материке гаснут — без Сердцевины кораблям конец. Я не читал мелкий шрифт, но вижу, что происходит: купцы не плывут, хлеб дорожает, люди голодают. Это не философия — это арифметика."],
		],
	})
	if StoryState.has_flag("boss_post_1_done"):
		opts.append({
			"label": "Монах сказал, что на страже было клеймо ордена.",
			"grant_flags": PackedStringArray([]),
			"continuation": [
				["veteran", "Клеймо. Звезда. Видел такое на первом страже пятнадцать лет назад. Мне было всё равно тогда, и всё равно сейчас. Клеймо не делает тварь менее опасной. Если ордену нравится думать, что они создали что-то «священное» — пусть объяснят это вдовам моих солдат."],
			],
		})
	if StoryState.has_flag("boss_post_2_done"):
		opts.append({
			"label": "На карте была шахта, которой нет. Ты знал?",
			"grant_flags": PackedStringArray([]),
			"continuation": [
				["veteran", "Знал. Казначей рисует то, что хочет видеть. Но рудники под островами — настоящие. Проблема в том, что пока стражи стоят, добраться до них нельзя. Карта лжёт в деталях — не в сути."],
			],
		})
	if StoryState.has_flag("boss_post_3_done"):
		opts.append({
			"label": "Монах рассказал про Зарю. Что ты об этом думаешь?",
			"grant_flags": PackedStringArray([]),
			"continuation": [
				["veteran", "«Заря». «Первый свет в волне». Монахи любят красивые слова для вещей, которые убивают. Я видел, что стражи делают с людьми. Если под ними спит что-то ещё хуже — тем более нужно быть готовым, а не молиться."],
				["veteran", "Но я скажу тебе то, чего монах не скажет: может, Заря — не катастрофа. Может, это ресурс. Орден веками сидел на архипелаге и ничего не делал — только «охранял». А люди на материке тем временем жгли последние маяки."],
			],
		})
	if StoryState.has_flag("truth_and_choice_done"):
		opts.append({
			"label": "Ты знаешь, что монах скрывал правду ради дочери?",
			"grant_flags": PackedStringArray([]),
			"continuation": [
				["veteran", "Знаю теперь. И не удивлён. У каждого свой расчёт. Монах молчал ради билета к дочери. Я молчу, потому что некому рассказывать. Разница — только в том, кому от молчания хуже."],
				["veteran", "Но я не виню его. Я бы тоже молчал, если бы у меня было, к кому ехать."],
			],
		})
	if StoryState.has_flag("hero_chose_refuse_chain"):
		opts.append({
			"label": "Я отказался снимать последнюю печать. Что ты об этом думаешь?",
			"grant_flags": PackedStringArray([]),
			"continuation": [
				["veteran", "…Честно? Я зол. Не на тебя — на ситуацию. Мои друзья погибли, чтобы начать это дело. Ты мог его закончить — и решил не заканчивать. Маяки продолжат гаснуть. Люди продолжат тонуть."],
				["veteran", "Но я солдат, а не судья. Ты принял решение. Живи с ним."],
			],
		})
	if StoryState.has_flag("worker_youth_dead"):
		opts.append({
			"label": "Юноша погиб. Ты что-нибудь скажешь?",
			"grant_flags": PackedStringArray([]),
			"continuation": [
				["veteran", "Скажу: его нужно было сначала ко мне. Хотя бы на неделю. Я бы научил его, как не умереть в первой засаде. Ты дал ему меч, но не дал навык. Это не героизм — это халатность."],
				["veteran", "…Но ему было бы всё равно приятно, что ты поверил в него. Мёртвым это уже не поможет. Живым — напоминание."],
			],
		})
	opts.append({
		"label": "Хватит про сюжет.",
		"grant_flags": PackedStringArray([]),
		"continuation": [
			["veteran", "Как скажешь. Мишени ждут."],
		],
	})
	return opts


func _build_personal_submenu() -> DialogueChoiceLine:
	return _choice("veteran", "Обо мне? Короткая история для длинной жизни.", _build_personal_option_dicts())


func _build_personal_option_dicts() -> Array:
	var opts: Array = []
	opts.append({
		"label": "Расскажи про первую экспедицию.",
		"grant_flags": PackedStringArray([]),
		"continuation": [
			["veteran", "Двадцать человек. Королевский приказ: разведка архипелага. Мы не знали про стражей. Первый контакт — потеряли троих за минуту. Лейтенант Марс — разорван пополам. Два стрелка — раздавлены. И тишина. Страж стоял, как будто ничего не случилось."],
			["veteran", "Мы отступили. Потом пробовали ещё раз — и ещё. Потеряли одиннадцать из двадцати. Корона приказала молчать и ждать. Мы ждём до сих пор."],
		],
	})
	if StoryState.has_flag("veteran_archer_intro_done"):
		opts.append({
			"label": "Почему ты не уехал с базы?",
			"grant_flags": PackedStringArray([]),
			"continuation": [
				["veteran", "Куда? Семьи нет — не было и до экспедиции. Армия была семьёй. Половина армии — в земле. Вторая половина — рассеяна по гарнизонам. На материке меня ждёт пенсия и комната, в которой я буду считать дни. Здесь я хотя бы нужен."],
			],
		})
	if StoryState.has_flag("veteran_story_1_done"):
		opts.append({
			"label": "Ты скучаешь по тем, кого потерял?",
			"grant_flags": PackedStringArray([]),
			"continuation": [
				["veteran", "Каждый день. Но скука — неправильное слово. Это не когда «хочется видеть». Это когда поворачиваешь голову, чтобы что-то сказать — а рядом никого. Пятнадцать лет, и я до сих пор поворачиваю голову."],
			],
		})
	if StoryState.has_flag("veteran_story_2_done"):
		opts.append({
			"label": "Ты простил корону за то, что вас бросили?",
			"grant_flags": PackedStringArray([]),
			"continuation": [
				["veteran", "Прощение — слово для тех, кто ждёт ответа. Корона не спрашивала. Она приказала, мы пошли, мы заплатили. Это не вопрос прощения — это контракт. Плохой контракт. Но я подписал его добровольно."],
			],
		})
	if StoryState.has_flag("veteran_story_3_done"):
		opts.append({
			"label": "Если бы мог — вернулся бы на первую экспедицию и поступил иначе?",
			"grant_flags": PackedStringArray([]),
			"continuation": [
				["veteran", "Каждую ночь я перестреливаю тот бой в голове. Другой угол. Другой приказ. Марс остаётся жив. Но утром я открываю глаза — и ничего не изменилось. Прошлое не принимает правок."],
			],
		})
	if StoryState.has_flag("truth_and_choice_done"):
		opts.append({
			"label": "После правды о стражах — ты жалеешь, что остался?",
			"grant_flags": PackedStringArray([]),
			"continuation": [
				["veteran", "Нет. Если бы уехал — не знал бы правды. Не знал бы, что стражи — замки. Не знал бы, что мои друзья погибли ради того, чтобы ты сейчас мог выбирать. Знание — паршивое утешение. Но единственное, которое у меня есть."],
			],
		})
	opts.append({
		"label": "Хватит личного.",
		"grant_flags": PackedStringArray([]),
		"continuation": [
			["veteran", "Хватит так хватит. Стрелы сами себя не точат."],
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
