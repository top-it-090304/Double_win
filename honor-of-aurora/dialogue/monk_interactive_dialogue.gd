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
	lines.append(_plain("healer", "Первый остров ты взял. Для короны это строчка в отчёте. Для меня…"))
	lines.append(_plain("hero", "Ты побледнел, когда я вернулся. Не от радости. Хочешь рассказать — я слушаю."))
	lines.append(_plain("healer", "Моя жена умерла не от меча. От лихорадки, от нехватки рук. Война забирает не только тех, кто в броне. Я приехал сюда вдовцом. Думал — работа заглушит."))
	lines.append(_plain("healer", "Не заглушила. А потом пришёл слух, что дочь тоже мертва. Лиан. Ей было семь, когда меня отправили. Я хоронил её словом, не телом."))
	lines.append(_plain("healer", "И вот я здесь: привязан к этим скалам контрактом ордена с короной. «До стабилизации узлов». Ни срока, ни даты. Только «потом»."))
	lines.append(_plain("hero", "Ты говоришь это мне, потому что я — тот, кто снимает узлы."))
	lines.append(_plain("healer", "Да. Каждый страж, которого ты убиваешь, приближает конец контракта. И мой отпуск. Я не могу быть объективным, когда речь о твоих походах. Знай это."))
	lines.append(_choice("healer", "Я доверяю тебе то, что не стал бы говорить гонцу короны. Что ты мне скажешь?", [
		{
			"label": "Надежда: ты увидишь конец этого пути. И он будет светлым.",
			"grant_flags": PackedStringArray(["monk_ch2_hope"]),
			"continuation": [
				["hero", "Я буду снимать узлы. Не ради короны — ради того, чтобы люди вроде тебя вернулись домой."],
				["healer", "…Осторожнее с такими словами. Они легче меча — но ранят глубже, если не сбудутся."],
			],
		},
		{
			"label": "Сомнение: ты уверен, что корона тебя отпустит?",
			"grant_flags": PackedStringArray(["monk_ch2_doubt"]),
			"continuation": [
				["hero", "Я видел, как работают королевские указы. «Потом» — это «никогда» на языке дворца."],
				["healer", "Может быть. Но у меня нет другого «потом». Только это. Спасибо за честность — даже если от неё горько."],
			],
		},
		{
			"label": "Долг: ты дал клятву — держи её, пока не сможешь уйти с чистой совестью.",
			"grant_flags": PackedStringArray(["monk_ch2_duty"]),
			"continuation": [
				["hero", "Сломанный целитель не нужен ни ордену, ни дочери. Доведи контракт. Потом — свободен."],
				["healer", "Как устав ордена, только теплее. Я попробую. Ночами будет тяжело — но ты прав: сначала долг, потом дорога."],
			],
		},
	]))


func _build_monk_story_4() -> void:
	lines.append(_plain("hero", "У тебя дрожат руки. Я заметил ещё вчера. Что случилось?"))
	lines.append(_plain("healer", "Письмо пришло. С большой земли, через три каравана и чужие руки. Одна фраза: «Я жива». Подпись — Лиан."))
	lines.append(_plain("healer", "Моя дочь. Которую я похоронил словом пять лет назад. Она жива."))
	lines.append(_plain("healer", "Почерк дрожит, бумага чужая, печать сомнительная… Но имя — её. И в строке, где она спрашивает «жив ли ты» — слово «папа», которое никто другой не написал бы так."))
	lines.append(_plain("hero", "Ты рассказываешь мне это не просто так. Ты хочешь к ней."))
	lines.append(_plain("healer", "Хочу. Больше всего на свете. Но контракт ордена держит меня здесь, пока «цепь не стабилизирована». А цепь стабилизируется, когда ты… когда все стражи будут сняты."))
	lines.append(_choice("healer", "Скажи мне прямо, странник: ты веришь, что это настоящее письмо — или ловушка для моего рассудка?", [
		{
			"label": "Верю. Иначе зачем сердцу столько шума?",
			"grant_flags": PackedStringArray(["monk_ch4_hope"]),
			"continuation": [
				["hero", "Если имя её и почерк дрожит — это живой человек. Люди не подделывают дрожь."],
				["healer", "Спасибо. Я держусь за это, как за канат над обрывом. Тонкий — но пока держит."],
			],
		},
		{
			"label": "Проверяй каждую букву. Корона умеет подделывать надежду.",
			"grant_flags": PackedStringArray(["monk_ch4_doubt"]),
			"continuation": [
				["hero", "Дворец мог послать это, чтобы ты помогал мне охотнее. Чтобы ты не говорил мне правду про стражей."],
				["healer", "…Я думал об этом. Каждую ночь. Но если я перестану верить в это письмо — у меня не останется ничего. А человек без «ничего» — опасен для себя и других."],
			],
		},
		{
			"label": "Неважно, настоящее оно или нет. Пиши ответ. Держи нить.",
			"grant_flags": PackedStringArray(["monk_ch4_duty"]),
			"continuation": [
				["hero", "Связь — это работа. Пиши, отправляй, жди. Правда раскроется, когда доберёшься до неё лично."],
				["healer", "Одно предложение — а я чувствую, что впервые за годы дышу не рывками. Я буду писать. Даже если руки дрожат."],
			],
		},
	]))
	lines.append(_plain("healer", "Я отвечал через караваны и чужие руки. Каждый ответ — как шов: аккуратно, больно. Но нить не рвётся."))


func _build_monk_story_5() -> void:
	lines.append(_plain("hero", "Скоро всё закончится. Остался один страж. Ты думаешь о дороге?"))
	lines.append(_plain("healer", "Каждую минуту. Она пишет, что ждёт. На большой земле, в деревне без названия. Второе письмо пришло: «Не умирай по дороге. Это всё, о чём прошу». И в конце — «Не беспокойся». Она лжёт так же плохо, как я."))
	lines.append(_plain("healer", "Она хранит мой мешочек с травами. Он уже не пахнет. А она помнит, как пах. Я забыл, кто я без клятвы и рукава с заплатками. А она помнит — за нас двоих."))
	lines.append(_plain("healer", "Корона обещает отпуск после «стабилизации». Один акт — и контракт закрыт. Но этот акт подписывается только после последнего стража."))
	lines.append(_plain("hero", "То есть твоя свобода зависит от моего решения."))
	lines.append(_plain("healer", "Да. И я не имею права на тебя давить. Но я и молчать больше не могу. Ты скоро выберешь — идти на последний остров или нет. И от этого зависит не только судьба архипелага."))
	if StoryState.has_flag("worker_youth_dead"):
		lines.append(_plain("healer", "Ты отдал за этот поход жизнь юноши. А я… я потерял того, за кого начал отвечать, как за своего. Не признавался — но ты видел. Как я проверял его, как ворчал, как ждал вечером. Мы оба заплатили тем, что не принадлежало нам."))
	lines.append(_choice("healer", "Я боюсь, странник. Чего — ты скажи мне.", [
		{
			"label": "Не успеть. Каждый день без неё — это день, который не вернуть.",
			"grant_flags": PackedStringArray(["monk_ch5_hope"]),
			"continuation": [
				["hero", "Тогда не думай о страхе. Думай о встрече. Она ближе, чем кажется."],
				["healer", "Спасибо. Я буду повторять себе это — как молитву. Только честную."],
			],
		},
		{
			"label": "Не узнать её. Прошли годы. Вы оба изменились.",
			"grant_flags": PackedStringArray(["monk_ch5_doubt"]),
			"continuation": [
				["hero", "Родные узнают друг друга не по лицу — по тому, как человек молчит. Ты узнаешь."],
				["healer", "Хотел бы верить. Но я начну с малого: голос, привычки, тишина между словами. Если это она — я пойму."],
			],
		},
		{
			"label": "Бросить всё и бежать, не закончив дело.",
			"grant_flags": PackedStringArray(["monk_ch5_duty"]),
			"continuation": [
				["hero", "Ты уже заплатил годами жизни. Доведи контракт — и уйди с чистой совестью. Не беглецом."],
				["healer", "Один страж. Один акт. Один билет. Я дождусь — и закрою список так, чтобы не стыдно было перед ней."],
			],
		},
	]))
	lines.append(_plain("healer", "Мне снится встреча. Она взрослая — а я старый, с руками, которые пахнут отваром и чужой кровью. Я боюсь не смерти. Я боюсь опоздать на одну минуту."))


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
				["hero", "Цепь замкнулась. Если хочешь сказать, что для тебя это — говори. Я не уйду, пока не выслушаю."],
				["healer", "Последний узел пал. Указ выполнен — бумага довольна. А я… я впервые за долгие годы чувствую, что дышу весь — не рывками, а целиком."],
				["healer", "Я соберу котёл, печать ордена и эти письма — в один узелок. И поеду не как солдат, а как отец, которому разрешили надеяться вслух."],
				["healer", "Если боги справедливы, они дадут мне не вечность — а один вечер, где можно говорить тихо и смеяться без счёта."],
				["hero", "…Тогда иди. Не торопясь. Как будто у тебя есть время — потому что ты его наконец отвоевал."],
				["healer", "Спасибо, странник. За меч, пока я держал чужие раны. Я пойду к дочери — с лицом, которое не прячется за долг."],
			]))
		"doubt":
			lines.append_array(_lines_from_pairs([
				["hero", "Цепь замкнулась. Если хочешь сказать, что для тебя это — говори. Я не уйду, пока не выслушаю."],
				["healer", "Последний узел пал. Я смотрю на дорогу — и вижу не праздник. Вижу чужие тени: а вдруг письма были лишь утешением бумаги?"],
				["healer", "Я всё равно поеду. Не потому что уверен — потому что непроверенная правда всё ещё честнее, чем удобная ложь в тишине."],
				["healer", "Если она не узнает меня с первого взгляда — я выдержу. Я уже выдерживал хуже."],
				["hero", "Тогда держи в руке не ожидание — встречу. Она редко приходит в том виде, в каком её рисуют."],
				["healer", "Спасибо. Я пойду — с дрожью в пальцах и трезвостью в голове. Это тоже форма надежды."],
			]))
		"duty":
			lines.append_array(_lines_from_pairs([
				["hero", "Цепь замкнулась. Если хочешь сказать, что для тебя это — говори. Я не уйду, пока не выслушаю."],
				["healer", "Последний узел пал. Указ выполнен. Я закрыл список так, как требовала корона — и теперь могу закрыть его для себя."],
				["healer", "Я поеду к дочери не как герой. Как человек, который сделал работу и больше не хочет быть должным за своё право уйти."],
				["healer", "Печать ордена останется в сумке — не на сердце. Сердце я оставлю для дороги, которую выбрал сам."],
				["hero", "…Идти можно и без флага. Главное — не забыть, зачем шёл."],
				["healer", "Не забуду. Спасибо, странник. Ты держал линию, пока я держал раны. Теперь моя очередь — держать слово до конца пути."],
			]))
		"balanced":
			lines.append_array(_lines_from_pairs([
				["hero", "Цепь замкнулась. Если хочешь сказать, что для тебя это — говори. Я не уйду, пока не выслушаю."],
				["healer", "Последний узел пал. Указ выполнен — бумага довольна. А я… я чувствую и облегчение, и пустоту: будто три дороги сошлись в одной, но ни одна не кричит «только я»."],
				["healer", "Я соберу вещи, письма и печать — и поеду. Не знаю, кого я встречу на берегу: отца, солдата или человека, который просто устал."],
				["healer", "Но я поеду честно: ни слепой верой, ни холодным отчётом — живым вопросом, на который хватит сил ответить глазами."],
				["hero", "…Тогда бери с собой всё, что было: и страх, и надежду. Из этого складывается дорога."],
				["healer", "Спасибо, странник. За то, что держал меч, пока я держал чужие раны. Я пойду — не торопясь и не откладывая. Как должно быть у тех, кто наконец может выбрать сам."],
			]))
