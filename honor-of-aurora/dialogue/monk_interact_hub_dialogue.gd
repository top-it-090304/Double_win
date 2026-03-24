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
				["healer", "Как скажешь. Только не жди, что я скажу то, что хочет услышать дворец."],
			],
		},
		{
			"label": "Уйти.",
			"grant_flags": PackedStringArray([]),
			"continuation": [
				["healer", "Тогда тишина и вода. Огонь никуда не денется."],
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
			["healer", "По указу — острова, руда, «сердцевина». В слухах — награда и сердце цепи. Но архипелаг старше указов: здесь говорили о узлах и о том, чего не стоит будить. Имя Авроры не от короны — в море его произнесли так же, как зовут зарю: свет в воде до неба."],
		],
	})
	if StoryState.has_flag("intro_base_island_done"):
		opts.append({
			"label": "Что здесь за база и причал?",
			"grant_flags": PackedStringArray([]),
			"continuation": [
				["healer", "Главный остров — лагерь экспедиции. С причала ходят лодки к берегам других островов — это твой путь, если бумага и ветер позволяют. Корабль экспедиции отчалил: впереди туман, острова и то, кто держит узлы."],
			],
		})
	if StoryState.has_flag("boss_post_1_done"):
		opts.append({
			"label": "Что ты сказал после первого острова — про стражей?",
			"grant_flags": PackedStringArray([]),
			"continuation": [
				["healer", "Ты сам заметил: твари были слишком ровные. На костях старых стражей видели клеймо… похожее на корону. Не спеши с выводом — но и не закрывай глаза."],
			],
		})
	if StoryState.has_flag("boss_post_2_done"):
		opts.append({
			"label": "Почему на карте была шахты, которой не оказалось?",
			"grant_flags": PackedStringArray([]),
			"continuation": [
				["healer", "Кое-кто рисует руду задним числом. Аврора помнит старые договоры — не про добычу, а про тишину. Карта лжёт, когда удобно дворцу."],
			],
		})
	if StoryState.has_flag("boss_post_3_done"):
		opts.append({
			"label": "Что с колоколом на Тихой Отмели?",
			"grant_flags": PackedStringArray([]),
			"continuation": [
				["healer", "Третий колокол молчал, пока ты был на острове — и отозвался, когда ты ушёл. Архипелаг нервничает: цепь слышит, что ты делаешь."],
			],
		})
	if StoryState.has_flag("truth_and_choice_done"):
		opts.append({
			"label": "Что ты имел в виду про последний узел и корону?",
			"grant_flags": PackedStringArray([]),
			"continuation": [
				["healer", "На бумаге короны остался один шаг — и разжимание цепи, не «охота на зверьё». Стражи были замками. Снять последний болт — значит принять цену, которую дворец не напишет вслух."],
			],
		})
	opts.append({
		"label": "Слушать сюжетные сцены (новости островов).",
		"grant_flags": PackedStringArray(["monk_hub_def_story"]),
		"continuation": [
			["healer", "Хорошо. Слушай внимательно — иногда важнее то, что между строк."],
		],
	})
	return opts


func _build_monk_personal_submenu() -> DialogueChoiceLine:
	return _choice("healer", "Спрашивай. Только помни: не всё, что лечится, любит свет.", _build_monk_personal_option_dicts())


func _build_monk_personal_option_dicts() -> Array:
	var opts: Array = []
	# Всегда — кто он здесь и почему не в «походе» с мечом
	opts.append({
		"label": "Почему ты у огня и бинтах, а не с мечом на островах?",
		"grant_flags": PackedStringArray([]),
		"continuation": [
			["healer", "Орден учил: не навреди. Не «победи» — не навреди. Я держу раны, а не головы. На бумаге меня оставили «до стабилизации узлов» — красивые слова. Я остаюсь потому, что клятва не отменяется желанием сменить поле боя."],
		],
	})
	if StoryState.has_flag("intro_base_island_done"):
		opts.append({
			"label": "Кого ты оставил дома, когда тебя отправили сюда?",
			"grant_flags": PackedStringArray([]),
			"continuation": [
				["healer", "Не только постель. Людей. Это не жалоба — факт: факты не лечат, но держат ровным, когда хочется кричать. Ночами я считаю волны — не как моряк, а как тот, кто ждёт, когда можно перестать считать."],
			],
		})
	if StoryState.has_flag("monk_story_1_done"):
		opts.append({
			"label": "Ты веришь, что орден когда-нибудь отпустит тебя по этому контракту?",
			"grant_flags": PackedStringArray([]),
			"continuation": [
				["healer", "«Стабилизация узлов» — в документе нет срока. Я перестал ждать даты и начал ждать… события. Глупо? Наверное. Но у клятвы нет календаря — есть только то, что ты делаешь завтра."],
			],
		})
	if StoryState.has_flag("monk_story_2_done"):
		opts.append({
			"label": "Ты говорил о жене. Как ты пережил это и не сломался в броне?",
			"grant_flags": PackedStringArray([]),
			"continuation": [
				["healer", "Она умерла не от меча — от лихорадки, от нехватки рук. Война забирает не только бронированных. Я приехал сюда вдовцом и думал: работа заглушит. Не заглушила. Заглушает только сон. А сон здесь — роскошь."],
			],
		})
	if StoryState.has_flag("monk_story_3_done"):
		opts.append({
			"label": "Кто такая Лиан — и что ты носишь в себе после вести «ребёнка не нашли»?",
			"grant_flags": PackedStringArray([]),
			"continuation": [
				["healer", "Дочь. Я прочитал слух как «погибла» — так проще, пока не знаешь, что проще не значит правда. Я хоронил её дважды: словом и тишиной. Тишина тяжелее камня."],
			],
		})
	if StoryState.has_flag("monk_story_4_done"):
		opts.append({
			"label": "Письма «я жива» — для тебя это надежда или пытка?",
			"grant_flags": PackedStringArray([]),
			"continuation": [
				["healer", "И то, и другое. Почерк дрожит — а имя её. Я читаю медленнее: медленнее читается правда, если она есть. И я боюсь обмануться в последний раз — как боюсь не успеть."],
			],
		})
	if StoryState.has_flag("monk_letter_1_read"):
		opts.append({
			"label": "Как ты пережил первое письмо от неё — после стольких лет молчания?",
			"grant_flags": PackedStringArray([]),
			"continuation": [
				["healer", "Сначала смеялся вслух — как дурак. Потом плакал так, что стыдно было перед котлом. Каждое слово — как шов: держит, даже когда кожа натянута до боли."],
			],
		})
	if StoryState.has_flag("monk_story_5_done"):
		opts.append({
			"label": "Корона обещает тебе отъезд к дочери — во что ты веришь сильнее: в указ или в дорогу?",
			"grant_flags": PackedStringArray([]),
			"continuation": [
				["healer", "В дорогу. Указ — пергамент. Я уже заплатил картой островов: хочу закрыть список так, чтобы не стыдно было смотреть в письма. И боюсь опоздать не на год — на минуту."],
			],
		})
	if StoryState.has_flag("monk_letter_2_read"):
		opts.append({
			"label": "Она просит приехать «без маски героя» — тебе это страшнее боя?",
			"grant_flags": PackedStringArray([]),
			"continuation": [
				["healer", "Страшнее. В бою я знаю правила. А снять латы с лица — это уже не орден, а человек. Я учусь этому у огня: здесь нет героя — есть только кто держит тепло."],
			],
		})
	if StoryState.has_flag("truth_and_choice_done"):
		opts.append({
			"label": "Почему мой выбор на последнем узле касается и твоего пути к ней?",
			"grant_flags": PackedStringArray([]),
			"continuation": [
				["healer", "Потому что корона подпишет одним актом и цепь «готова», и мой билет домой. Ты снимаешь болт — и бумага для дворца совпадает с бумагой для меня. Откажешься — и мой отпуск останется отложкой в чужом сейфе. Я не виню тебя за честность… но кровь помнит оба конца."],
			],
		})
	if StoryState.has_flag("hero_chose_refuse_chain") and StoryState.has_flag("truth_and_choice_done"):
		opts.append({
			"label": "Ты держишь злость, что я отказался снять последний узел?",
			"grant_flags": PackedStringArray([]),
			"continuation": [
				["healer", "Нет. Клятва «не навреди» про чужих, кого я не вижу — а про свою кровь режет глубже. Ты выбрал свои чистые руки. Я остаюсь с надеждой без дороги. Это не про злость — про пустоту в разных карманах."],
			],
		})
	if StoryState.has_flag("monk_story_6_done"):
		opts.append({
			"label": "Цепь замкнулась. Что ты чувствуешь — облегчение или страх перед встречей?",
			"grant_flags": PackedStringArray([]),
			"continuation": [
				["healer", "И то, и другое. Указ выполнен — бумага довольна. А я впервые дышу ровно… и всё равно ловлю себя на том, что прислушиваюсь к шагам, которых ещё нет. Дорога к дочери — не награда дворца. Это мой долг к себе."],
			],
		})
	opts.append({
		"label": "Хватит личного.",
		"grant_flags": PackedStringArray([]),
		"continuation": [
			["healer", "Как скажешь. Огонь не обижается на короткий разговор."],
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
