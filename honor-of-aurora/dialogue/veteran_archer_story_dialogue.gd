extends DialogueSequence
class_name VeteranArcherStoryDialogue

## 4 главы линии ветерана. Выборы: honor / bitterness / acceptance.
## Финал (ch4) зависит от доминирующего трека.

@export var dialogue_key: String = ""


func ensure_lines_ready() -> void:
	if not lines.is_empty():
		return
	id = dialogue_key
	match dialogue_key:
		"veteran_story_1":
			_build_story_1()
		"veteran_story_2":
			_build_story_2()
		"veteran_story_3":
			_build_story_3()
		"veteran_story_4":
			_build_story_4()
		_:
			push_warning("VeteranArcherStoryDialogue: неизвестный ключ: %s" % dialogue_key)


func _build_story_1() -> void:
	lines.append(_plain("veteran", "Ты вернулся с первого острова. Живой. Это уже лучше, чем у нас."))
	lines.append(_plain("hero", "Ты был на первой экспедиции. Расскажи, что там случилось — по-настоящему."))
	lines.append(_plain("veteran", "По-настоящему? Нас было двадцать. Королевский отряд: десять стрелков, пять мечников, три разведчика, лейтенант и я — старший стрелок. Приказ: разведка архипелага. Звучало как учебный поход."))
	lines.append(_plain("veteran", "Первый остров. Тишина. Красивый берег. Марс — наш лейтенант — приказал выдвигаться вглубь. Мы прошли сто шагов. Потом земля задрожала."))
	lines.append(_plain("veteran", "Страж вышел из скалы. Не «выбежал» — вышел. Медленно. Как будто у него было всё время мира. Марс крикнул «строй» — и через три секунды его не стало. Двое рядом — тоже. Мы стреляли — стрелы отскакивали. Бежали. Семеро не добежали."))
	lines.append(_plain("hero", "…"))
	lines.append(_plain("veteran", "Корона приказала молчать. «Неудачная разведка. Потери в пределах допустимого.» Одиннадцать человек — «допустимые потери». Я остался здесь, потому что кто-то должен помнить их имена."))
	lines.append(_choice("veteran", "Рыцарь. Ты убил стража, которого мы не смогли даже ранить. Скажи мне прямо: как ты это видишь?", [
		{
			"label": "Их жертва не была напрасной. Они проложили путь — я его прошёл.",
			"grant_flags": PackedStringArray(["veteran_ch1_honor"]),
			"continuation": [
				["hero", "Без вашей разведки корона не знала бы, что здесь. Вы заплатили — я продолжил. Это не «напрасно»."],
				["veteran", "…Хотел бы верить. Одиннадцать имён. Если ты прав — они хотя бы не просто строчка в потерях."],
			],
		},
		{
			"label": "Корона использовала вас как пушечное мясо. Это было преступление.",
			"grant_flags": PackedStringArray(["veteran_ch1_bitterness"]),
			"continuation": [
				["hero", "Вас послали без подготовки, без информации, без шанса. Это не разведка — это расход."],
				["veteran", "Ты говоришь то, что я думаю пятнадцать лет. Вслух это звучит… больнее, чем в голове. Но честнее."],
			],
		},
		{
			"label": "Прошлое не исправить. Можно только не повторить.",
			"grant_flags": PackedStringArray(["veteran_ch1_acceptance"]),
			"continuation": [
				["hero", "Я потерял людей на переправе. Знаю, каково это — прокручивать в голове. Но прошлое не принимает правок."],
				["veteran", "Ты повторил мои слова. Значит, понимаешь. Это… не утешение. Но ближе к правде, чем всё остальное."],
			],
		},
	]))


func _build_story_2() -> void:
	lines.append(_plain("hero", "Бран. Расскажи мне про Марса. Каким он был?"))
	lines.append(_plain("veteran", "Ты спросил… Ладно. Марс был лучшим из нас. Не самым сильным — самым ровным. Никогда не кричал. Говорил тихо — и люди слушали. На привалах чинил чужие стрелы, хотя это моя работа."))
	lines.append(_plain("veteran", "Он был единственным, кто перед экспедицией сказал мне: «Бран, если не вернусь — не злись на корону. Злись на то, что не успели выпить в порту»."))
	lines.append(_plain("veteran", "Я злюсь на обе вещи. Каждый день."))
	lines.append(_plain("veteran", "Знаешь, что самое паршивое? Я не помню его лицо. Пятнадцать лет — и лицо стёрлось. Голос помню. Привычку щуриться на солнце — помню. А лицо — нет."))
	lines.append(_plain("hero", "Это нормально. Память хранит то, что важнее лица."))
	lines.append(_choice("veteran", "Рыцарь. Ты воюешь. Терял людей. Что ты делаешь с именами мёртвых?", [
		{
			"label": "Ношу их как знамя. Они — причина идти дальше.",
			"grant_flags": PackedStringArray(["veteran_ch2_honor"]),
			"continuation": [
				["hero", "Каждое имя — не груз, а причина не останавливаться. Марс хотел бы, чтобы ты продолжал."],
				["veteran", "Знамя… Красивое слово для тяжёлой вещи. Но я попробую. Хуже, чем сейчас, уже не будет."],
			],
		},
		{
			"label": "Проклинаю тех, кто их послал на смерть.",
			"grant_flags": PackedStringArray(["veteran_ch2_bitterness"]),
			"continuation": [
				["hero", "Мёртвые не виноваты. Виноваты те, кто подписал приказ, зная, что шансов нет."],
				["veteran", "Ты прав. Но проклятия не греют, рыцарь. Они только делают ночи длиннее."],
			],
		},
		{
			"label": "Отпускаю. Не забываю — но отпускаю.",
			"grant_flags": PackedStringArray(["veteran_ch2_acceptance"]),
			"continuation": [
				["hero", "Держать мёртвых за руку — значит не давать себе жить. Помнить — да. Держать — нет."],
				["veteran", "Легко сказать. Но ты, кажется, говоришь не из книги. Я… попробую. Не обещаю, что получится."],
			],
		},
	]))


func _build_story_3() -> void:
	lines.append(_plain("hero", "Бран. Монах рассказал мне правду. Стражи — не твари. Они были печатями. Орден поставил их, чтобы Заря не проснулась."))
	lines.append(_plain("veteran", "…"))
	lines.append(_plain("veteran", "Повтори."))
	lines.append(_plain("hero", "Стражей создал Орден Тихой Зари. Из осколков самой Зари. Они были замками, а не хищниками. Корона послала меня снять эти замки — не «зачистить территорию»."))
	lines.append(_plain("veteran", "…То есть мои друзья погибли, атакуя замок. Не врага. Замок, который стоял на месте и никого не трогал, пока мы не подошли."))
	lines.append(_plain("hero", "Да."))
	lines.append(_plain("veteran", "…Марс погиб, потому что мы первыми полезли к существу, которое нас не звало. Мы напали. Не оно."))
	lines.append(_plain("veteran", "Пятнадцать лет я считал, что мы были героями, которых предала разведка. А мы были… агрессорами. По приказу. По незнанию. Но всё равно — агрессорами."))
	lines.append(_choice("veteran", "Рыцарь. Ты тоже убивал стражей. Четверых. Зная или не зная — но убивал. Что ты мне скажешь?", [
		{
			"label": "Мы не знали. Незнание — не вина. Вина — на тех, кто знал и молчал.",
			"grant_flags": PackedStringArray(["veteran_ch3_honor"]),
			"continuation": [
				["hero", "Ваша экспедиция не знала про печати. Корона знала — и не сказала. Марс погиб не из-за вашей ошибки, а из-за чужого молчания."],
				["veteran", "Чужого молчания… Да. Корона. Орден. Все знали — и все молчали. А мы платили. Ты прав: вина — не наша. Но боль — наша."],
			],
		},
		{
			"label": "Это меняет всё. Мы были инструментами — и корона, и орден нас использовали.",
			"grant_flags": PackedStringArray(["veteran_ch3_bitterness"]),
			"continuation": [
				["hero", "Тебя использовали пятнадцать лет назад. Меня — сейчас. Разница в том, что я узнал правду. А тебе её не дали."],
				["veteran", "Инструменты. Расходный материал с именами. Марс. Кит. Дара. Ольм. Одиннадцать инструментов, списанных по акту «допустимые потери». Я… мне нужно побыть одному."],
			],
		},
		{
			"label": "Правда не меняет их смерть. Она меняет то, что мы делаем дальше.",
			"grant_flags": PackedStringArray(["veteran_ch3_acceptance"]),
			"continuation": [
				["hero", "Марс мёртв — это факт. Стражи были печатями — это факт. Ни один факт не отменяет другой. Но ты можешь решить, что делать с обоими."],
				["veteran", "…Ты говоришь, как человек, который сам это пережил. Не утешение — но точка опоры. Мне нужна точка опоры. Спасибо."],
			],
		},
	]))


func _build_story_4() -> void:
	var h := _count_track("honor")
	var b := _count_track("bitterness")
	var a := _count_track("acceptance")
	var ending := _pick_ending(h, b, a)
	match ending:
		"honor":
			lines.append_array(_lines_from_pairs([
				["hero", "Бран. Всё кончено. Что ты чувствуешь?"],
				["veteran", "Цепь снята. Или не снята — неважно. Важно, что я наконец понимаю, за что стоял."],
				["veteran", "Мои друзья погибли не напрасно. Не потому что «так было нужно» — а потому что они шли первыми. Без них не было бы ни базы, ни тебя, ни этого разговора."],
				["veteran", "Я останусь на стрельбище. Буду тренировать тех, кто придёт следующим. Не для короны — для памяти. Чтобы следующие знали, во что идут. И шли подготовленными."],
				["veteran", "Марс бы одобрил. Он всегда говорил: «Бран, хватит злиться — учи стрелять». Наконец-то послушаю."],
				["hero", "…Тогда стой здесь, Бран. Стой крепко."],
				["veteran", "Крепче, чем стрела в мишени. Это я умею."],
			]))
		"bitterness":
			lines.append_array(_lines_from_pairs([
				["hero", "Бран. Всё кончено. Что ты чувствуешь?"],
				["veteran", "Злость. Чистую, как первый выстрел."],
				["veteran", "Корона использовала нас. Орден использовал нас. Монах использовал тебя. Все знали правду — и все молчали, потому что так удобнее. А мы — платили."],
				["veteran", "Я не буду больше тренировать для короны. Пусть ищут другого дурака. Эти лучники на стенах — мои. Но следующих я учить не стану. Не за эту корону."],
				["veteran", "Если когда-нибудь найдётся тот, кто скажет: «Мы идём честно, без скрытых приказов» — я встану в строй. А до тех пор — мишени и тишина."],
				["hero", "Ты имеешь право злиться, Бран."],
				["veteran", "Спасибо. Не за разрешение. За то, что не пытаешься утешить. Утешение — для тех, кому есть куда идти."],
			]))
		"acceptance":
			lines.append_array(_lines_from_pairs([
				["hero", "Бран. Всё кончено. Что ты чувствуешь?"],
				["veteran", "Тишину. Впервые за пятнадцать лет — настоящую тишину."],
				["veteran", "Я не простил корону. Не простил орден. Но я перестал ждать, что кто-то попросит прощения. Они не попросят. И я больше не буду стоять с протянутой рукой."],
				["veteran", "Марс мёртв. Стражи были замками. Корона лгала. Всё это — правда. И всё это — уже прошлое. Я не могу жить в прошлом, рыцарь. Хромая нога не даёт бегать назад."],
				["veteran", "Я останусь здесь. Буду тренировать, чинить стрелы, смотреть на море. Не потому что должен — потому что это единственное, что умею. И впервые этого достаточно."],
				["hero", "Тишина — не худший итог, Бран."],
				["veteran", "Не худший. Для солдата, у которого нет дома, — почти лучший."],
			]))
		"balanced":
			lines.append_array(_lines_from_pairs([
				["hero", "Бран. Всё кончено. Что ты чувствуешь?"],
				["veteran", "Всё сразу. Злость, покой и что-то похожее на гордость — всё в одном вдохе."],
				["veteran", "Я не знаю, правильно ли всё это было. Не знаю, стоила ли жизнь Марса того, что ты сделал. Не знаю, проснётся ли Заря и что будет дальше."],
				["veteran", "Но я знаю одно: я стоял на этих камнях пятнадцать лет — и впервые чувствую, что стою не зря. Не потому что кто-то сказал «спасибо». А потому что я решил так сам."],
				["veteran", "Останусь. Буду тренировать. Буду помнить. И буду готов — к чему бы то ни было."],
				["hero", "Стой крепко, Бран."],
				["veteran", "Как стрела в мишени. Единственное, что я знаю наверняка."],
			]))


func _count_track(which: String) -> int:
	var n := 0
	for ch in ["1", "2", "3"]:
		if StoryState.has_flag("veteran_ch%s_%s" % [ch, which]):
			n += 1
	return n


static func grant_ending_flag_after_finale() -> void:
	var h := _static_count("honor")
	var b := _static_count("bitterness")
	var a := _static_count("acceptance")
	var ending := _static_pick(h, b, a)
	StoryState.set_flag("veteran_ending_%s" % ending, true)


static func _static_count(which: String) -> int:
	var n := 0
	for ch in ["1", "2", "3"]:
		if StoryState.has_flag("veteran_ch%s_%s" % [ch, which]):
			n += 1
	return n


static func _static_pick(h: int, b: int, a: int) -> String:
	var mx: int = maxi(h, maxi(b, a))
	var winners: Array[String] = []
	if h == mx:
		winners.append("honor")
	if b == mx:
		winners.append("bitterness")
	if a == mx:
		winners.append("acceptance")
	if winners.size() >= 3:
		return "balanced"
	if winners.size() >= 2:
		if "honor" in winners:
			return "honor"
		if "acceptance" in winners:
			return "acceptance"
		return "bitterness"
	return winners[0]


func _pick_ending(h: int, b: int, a: int) -> String:
	return _static_pick(h, b, a)


func _plain(speaker_id: String, text: String) -> DialogueLine:
	var l := DialogueLine.new()
	l.speaker_id = speaker_id
	l.text = text
	return l


func _lines_from_pairs(pairs: Array) -> Array[DialogueLine]:
	var out: Array[DialogueLine] = []
	for row in pairs:
		if row is Array and row.size() >= 2:
			out.append(_plain(str(row[0]), str(row[1])))
	return out


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
				if row is Array and row.size() >= 2:
					cont_lines.append(_plain(str(row[0]), str(row[1])))
		opt.continuation = cont_lines
		cl.options.append(opt)
	return cl
