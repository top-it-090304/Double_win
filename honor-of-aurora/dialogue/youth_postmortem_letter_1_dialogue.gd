extends DialogueSequence


func ensure_lines_ready() -> void:
	if not lines.is_empty():
		return
	id = "youth_postmortem_letter_1"

	var knew_letter1: bool = StoryState.has_flag("youth_letter_1_done")
	var knew_letter2: bool = StoryState.has_flag("youth_letter_2_done")

	lines.append(
		_plain(
			"narrator",
			"Письмо сошло с казённого борта вместе с мешками: целитель забрал конверт у причала и пошёл искать тебя по лагерю — не у воды ждать, пока случай сам подскажет. Нашёл. В руках всё ещё тот же конверт."
		)
	)
	lines.append(_plain("healer", "Пришло по почте. На его имя."))

	if not knew_letter1:
		lines.append(_plain("hero", "Ему писали?"))
		lines.append(_plain("healer", "Мать. Он получал письма. Отвечал. Ты не знал."))
		lines.append(_plain("narrator", "Монах разворачивает лист. Торопливый почерк, чернила размазаны."))
		lines.append(_plain("healer", "«Сынок. Мне сказала жена лодочника, куда ты уехал. Я не спала три ночи. Ника спрашивает каждое утро: когда он приедет? Я не знаю, что ей отвечать.»"))
		lines.append(_plain("healer", "«Вернись. В порту есть работа. Отец тоже работал в порту — и каждый вечер приходил домой. Этого достаточно. Мама.»"))
		lines.append(_plain("narrator", "Тишина. Ветер треплет край бумаги."))
		lines.append(_plain("healer", "Она не знает. Ждёт ответа."))
		lines.append(_plain("hero", "А он?"))
		lines.append(_plain("healer", "Он отвечал. Черновики на койке — зачёркнутые строки, подобранные слова. Он врал ей аккуратно. Как любил."))
	elif not knew_letter2:
		lines.append(_plain("hero", "Ещё одно."))
		lines.append(_plain("healer", "Она не знает."))
		lines.append(_plain("narrator", "Монах протягивает письмо. Не открывает — ждёт."))
		lines.append(_plain("narrator", "Ты разворачиваешь. Почерк тот же — торопливый, с нажимом."))
		lines.append(_plain("narrator", "«Сынок. Караванщик сказал, что на островах потери. Я не знаю, что это значит — потери. Я знаю, что значит — не дождаться.»"))
		lines.append(_plain("narrator", "«Ника перестала спрашивать, когда ты приедешь. Просто рисует кораблики и вешает на стену. Их уже семь.»"))
		lines.append(_plain("narrator", "«Она просит привезти ракушку — самую большую, какая есть. Пожалуйста. Я не прошу подвигов. Я прошу тебя — живого. Мама.»"))
		lines.append(_plain("narrator", "Ты складываешь письмо. Ракушка — на его койке. Обломанная."))
		lines.append(_plain("healer", "Она просит его — живого. А мы держим в руках его прощание."))
	else:
		lines.append(_plain("healer", "Третье. Она всё ещё пишет."))
		lines.append(_plain("narrator", "Монах не открывает. Кладёт на стол, лицом вниз. Потом переворачивает."))
		lines.append(_plain("narrator", "«Сынок. Писем нет. Караванщик говорит — задержка. Я верю ему, потому что не могу не верить.»"))
		lines.append(_plain("narrator", "«Ника повесила десятый кораблик на стену. Когда я спрашиваю — для кого, она говорит: для братика. Он обещал вернуться с ракушкой.»"))
		lines.append(_plain("narrator", "«Монеты кончаются. Но это неважно. Важно — ты. Одно слово. Любое. Мама.»"))
		lines.append(_plain("narrator", "Одно слово. Она просит одно слово. А ты не можешь написать даже ложь — потому что его ложь была лучше твоей правды."))

	lines.append(_plain("healer", "Его прощальное письмо… нужно отправить. Чем дольше тянем — тем больше она ждёт."))

	if StoryState.has_flag("youth_belongings_found"):
		lines.append(_plain("hero", "У меня. Вместе с ракушкой и рисунком."))
	else:
		lines.append(_plain("hero", "Оно в бараке. На его койке."))
		lines.append(_plain("healer", "Забери. Там его вещи — письма, рисунок. Всё, что он не успел отправить."))

	lines.append(_plain("healer", "Когда будет оказия — караванщик, лодка — отправим. Она получит его «хорошие новости». И перестанет ждать писем. Как он и хотел."))
	lines.append(_plain("narrator", "Монах уходит. Не оборачивается. Походка — тяжелее, чем обычно."))


func _plain(speaker_id: String, text: String) -> DialogueLine:
	var l := DialogueLine.new()
	l.speaker_id = speaker_id
	l.text = text
	return l
