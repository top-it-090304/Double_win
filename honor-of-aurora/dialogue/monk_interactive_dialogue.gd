extends DialogueSequence
class_name MonkInteractiveDialogue

## Интерактивные главы монаха и финал с концовками по флагам monk_ch*_hope|doubt|duty.

@export var dialogue_key: String = ""


func ensure_lines_ready() -> void:
	if not lines.is_empty():
		return
	id = dialogue_key
	match dialogue_key:
		"monk_story_2":
			_build_monk_story_2()
		"monk_story_4":
			_build_monk_story_4()
		"monk_story_5":
			_build_monk_story_5()
		"monk_story_6":
			_build_monk_story_6()
		_:
			push_warning("MonkInteractiveDialogue: неизвестный ключ: %s" % dialogue_key)


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


func _build_monk_story_2() -> void:
	lines.append(_plain("healer", "Первый остров ты взял — и мир не рухнул. Для короны это отчёт. Для меня это напоминание: конец бывает тихим."))
	lines.append(_plain("healer", "Моя жена умерла не от меча. От лихорадки, от нехватки рук, от того, что война забирает не только тех, кто в броне. Я приехал сюда уже вдовцом — думал, работа заглушит."))
	lines.append(_plain("healer", "Не заглушила. Заглушает только сон. А сон здесь — роскошь."))
	lines.append(_choice("healer", "Странник… если у тебя есть слово — не для утешения, а для правды: что тебе ближе?", [
		{
			"label": "Надежда: боль со временем станет не ножом, а памятью.",
			"grant_flags": PackedStringArray(["monk_ch2_hope"]),
			"continuation": [
				["hero", "Тогда я скажу так: тишина после тьмы — ещё не всё. Иногда это только заря."],
				["healer", "Ты несёшь зарю чужими руками. Береги её — она лёгкая, пока ты не отдаёшь её в чужой карман."],
			],
		},
		{
			"label": "Сомнение: не всякая правда тебя спасёт.",
			"grant_flags": PackedStringArray(["monk_ch2_doubt"]),
			"continuation": [
				["hero", "Правда без милосердия — ещё один камень. Ты не обязан быть камнем."],
				["healer", "Честно. Спасибо. Ты не обязан лечить мою душу — только тело. И то, что ты споришь, уже лекарство."],
			],
		},
		{
			"label": "Долг: клятва не даёт права сломаться.",
			"grant_flags": PackedStringArray(["monk_ch2_duty"]),
			"continuation": [
				["hero", "Орден послал тебя — значит, ты всё ещё нужен живым. Сломанный целитель никому не поможет."],
				["healer", "Ты говоришь, как устав ордена. Но клятва — не клетка. Я постараюсь помнить это, когда ночь сдавливает грудь."],
			],
		},
	]))


func _build_monk_story_4() -> void:
	lines.append(_plain("healer", "Письма начались не с объяснений. С одной фразы: «Я жива». Я читал это, как читают приговор — только наоборот: как отмену смерти."))
	lines.append(_plain("healer", "Почерк дрожит, бумага чужая, печать сомнительная… но имя — её. И слово «мама» в строке, где она спрашивает, жив ли я."))
	lines.append(_choice("healer", "Когда бумага спасает больше отваги, чем меч — во что ты веришь сильнее?", [
		{
			"label": "В то, что это она. Иначе зачем сердцу столько шума?",
			"grant_flags": PackedStringArray(["monk_ch4_hope"]),
			"continuation": [
				["hero", "Если имя её — я выберу веру. Иначе зачем всё это ждать."],
				["healer", "Тогда я отвечаю морю и дорогам так же, как ты отвечаешь мне — коротко и без уловок. Пусть письмо ведёт."],
			],
		},
		{
			"label": "В то, что подделать имя проще, чем совесть.",
			"grant_flags": PackedStringArray(["monk_ch4_doubt"]),
			"continuation": [
				["hero", "Я бы проверял каждую букву. Не из злости — из страха обмануться в последний раз."],
				["healer", "Я тоже боюсь. Но страх заставляет читать медленнее — а медленнее читается правда, если она есть."],
			],
		},
		{
			"label": "В то, что ответ должен быть — даже если правды мало.",
			"grant_flags": PackedStringArray(["monk_ch4_duty"]),
			"continuation": [
				["hero", "Пиши. Отправляй. Держи нить. Это не надежда и не страх — это работа любви."],
				["healer", "Ты описал мою жизнь одним предложением. Я буду держать нить. Даже когда руки дрожат."],
			],
		},
	]))
	lines.append(_plain("healer", "Я отвечал через чужие руки, через караваны, через молчание моря. Каждый ответ был как шов: аккуратно, больно, не иначе."))


func _build_monk_story_5() -> void:
	lines.append(_plain("healer", "Она пишет, что ждёт на большой земле — там, где корона ещё помнит дороги без тумана. Я… я хочу доехать. Не «когда-нибудь». Когда цепь отпустит."))
	lines.append(_plain("healer", "Корона обещает отпуск тем, кто «дочистил архипелаг». Смешно: я дочищаю раны, а не острова — но если это цена билета… я заплатил бы и больше."))
	lines.append(_choice("healer", "Чего ты боишься сильнее — не успеть или не суметь?", [
		{
			"label": "Не успеть — и это уже почти прощание.",
			"grant_flags": PackedStringArray(["monk_ch5_hope"]),
			"continuation": [
				["hero", "Тогда каждый узел, что падает, — не победа дворца. Это минута, которую ты выкупаешь у времени."],
				["healer", "Ты сказал мягче, чем я себе позволяю. Я запомню: не дворец отпускает — время, если ты к нему идёшь честно."],
			],
		},
		{
			"label": "Не узнать её глаза после стольких лет.",
			"grant_flags": PackedStringArray(["monk_ch5_doubt"]),
			"continuation": [
				["hero", "Иногда люди узнают друг друга не лицом — голосом, привычкой держать чашку. Начни с малого."],
				["healer", "…Да. С малого. Иначе я раздавлю всё ожиданием слишком большой сцены."],
			],
		},
		{
			"label": "Сорвать клятву ради своего «хочу».",
			"grant_flags": PackedStringArray(["monk_ch5_duty"]),
			"continuation": [
				["hero", "Ты уже заплатил картой островов. Доведи — и тогда уходи не беглецом, а человеком с закрытым списком."],
				["healer", "Список. Да. Я закрою его так, чтобы не стыдно было смотреть в зеркало — и в письма."],
			],
		},
	]))
	lines.append(_plain("healer", "Иногда мне снится встреча: она взрослая, я — старый. Я боюсь не смерти. Я боюсь опоздать на минуту."))


func _count_track(which: String) -> int:
	var n := 0
	for ch in ["2", "4", "5"]:
		var k := "monk_ch%s_%s" % [ch, which]
		if StoryState.has_flag(k):
			n += 1
	return n


## Вызов после успешного прохождения monk_story_6 — фиксирует концовку в сохранении (не вызывать из ensure_lines_ready).
static func grant_ending_flag_after_finale() -> void:
	var h := _static_count_track("hope")
	var d := _static_count_track("doubt")
	var t := _static_count_track("duty")
	var ending := _static_pick_ending(h, d, t)
	StoryState.set_flag("monk_ending_%s" % ending, true)


static func _static_count_track(which: String) -> int:
	var n := 0
	for ch in ["2", "4", "5"]:
		if StoryState.has_flag("monk_ch%s_%s" % [ch, which]):
			n += 1
	return n


static func _static_pick_ending(hope: int, doubt: int, duty: int) -> String:
	var mx: int = maxi(hope, maxi(doubt, duty))
	var winners: Array[String] = []
	if hope == mx:
		winners.append("hope")
	if doubt == mx:
		winners.append("doubt")
	if duty == mx:
		winners.append("duty")
	if winners.size() >= 3:
		return "balanced"
	if winners.size() >= 2:
		if "hope" in winners:
			return "hope"
		if "duty" in winners:
			return "duty"
		return "doubt"
	return winners[0]


func _pick_ending(hope: int, doubt: int, duty: int) -> String:
	return _static_pick_ending(hope, doubt, duty)


func _build_monk_story_6() -> void:
	var h := _count_track("hope")
	var d := _count_track("doubt")
	var t := _count_track("duty")
	var ending := _pick_ending(h, d, t)
	match ending:
		"hope":
			lines.append_array(_lines_from_pairs([
				["healer", "Последний узел пал. Указ выполнен — бумага довольна. А я… я впервые за долгие годы чувствую, что дышу весь — не рывками, а целиком."],
				["healer", "Я соберу котёл, печать ордена и эти письма — в один узелок. И поеду не как солдат, а как отец, которому разрешили надеяться вслух."],
				["healer", "Если боги справедливы, они дадут мне не вечность — а один вечер, где можно говорить тихо и смеяться без счёта."],
				["hero", "…Тогда иди. Не торопясь. Как будто у тебя есть время — потому что ты его наконец отвоевал."],
				["healer", "Спасибо, странник. За меч, пока я держал чужие раны. Я пойду к дочери — с лицом, которое не прячется за долг."],
			]))
		"doubt":
			lines.append_array(_lines_from_pairs([
				["healer", "Последний узел пал. Я смотрю на дорогу — и вижу не праздник. Вижу чужие тени: а вдруг письма были лишь утешением бумаги?"],
				["healer", "Я всё равно поеду. Не потому что уверен — потому что непроверенная правда всё ещё честнее, чем удобная ложь в тишине."],
				["healer", "Если она не узнает меня с первого взгляда — я выдержу. Я уже выдерживал хуже."],
				["hero", "Тогда держи в руке не ожидание — встречу. Она редко приходит в том виде, в каком её рисуют."],
				["healer", "Спасибо. Я пойду — с дрожью в пальцах и трезвостью в голове. Это тоже форма надежды."],
			]))
		"duty":
			lines.append_array(_lines_from_pairs([
				["healer", "Последний узел пал. Указ выполнен. Я закрыл список так, как требовала корона — и теперь могу закрыть его для себя."],
				["healer", "Я поеду к дочери не как герой. Как человек, который сделал работу и не хочет больше никому должен быть за своё право уйти."],
				["healer", "Печать ордена останется в сумке — не на сердце. Сердце я оставлю для дороги, которую выбрал сам."],
				["hero", "…Идти можно и без флага. Главное — не забыть, зачем шёл."],
				["healer", "Не забуду. Спасибо, странник. Ты держал линию, пока я держал раны. Теперь моя очередь — держать слово до конца пути."],
			]))
		"balanced":
			lines.append_array(_lines_from_pairs([
				["healer", "Последний узел пал. Указ выполнен — бумага довольна. А я… я чувствую и облегчение, и пустоту: будто три дороги сошлись в одной, но ни одна не кричит «только я»."],
				["healer", "Я соберу вещи, письма и печать — и поеду. Не знаю, кого я встречу на берегу: отца, солдата или человека, который просто устал."],
				["healer", "Но я поеду честно: ни слепой верой, ни холодным отчётом — живым вопросом, на который хватит сил ответить глазами."],
				["hero", "…Тогда бери с собой всё, что было: и страх, и надежду. Из этого складывается дорога."],
				["healer", "Спасибо, странник. За то, что держал меч, пока я держал чужие раны. Я пойду — не торопясь и не откладывая. Как должно быть у тех, кто наконец может выбрать сам."],
			]))
