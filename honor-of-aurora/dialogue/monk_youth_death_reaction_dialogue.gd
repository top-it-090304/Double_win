extends DialogueSequence


func ensure_lines_ready() -> void:
	if not lines.is_empty():
		return
	id = "monk_youth_death_reaction"

	var knew_camp: bool = StoryState.has_flag("worker_youth_camp_done")
	var knew_letter1: bool = StoryState.has_flag("youth_letter_1_done")
	var knew_letter2: bool = StoryState.has_flag("youth_letter_2_done")

	lines.append(_plain("narrator", "Целитель смотрит на ваши руки. Потом — на пустое место рядом. Потом отворачивается."))
	lines.append(_plain("healer", "…"))

	if knew_letter2:
		lines.append(_plain("healer", "Я не скажу «я предупреждал». Ты это знаешь. Я это знаю. Мертвец — нет."))
		lines.append(_plain("healer", "Он приходил ко мне вечерами. Спрашивал про травы. Не потому что интересно — потому что ему нужен был кто-то, кто слушает. Мать далеко. Сестра рисует кораблики. А я — рядом."))
		lines.append(_plain("healer", "Я ворчал. Проверял температуру, когда он не болел. Не признавался себе — зачем."))
		lines.append(_plain("healer", "Теперь признаюсь: я играл в отца. Чужого мальчишки. Потому что своя дочь — за морем. И руки делают то, что делал бы отец, даже когда голова запрещает."))
	elif knew_letter1:
		lines.append(_plain("healer", "Я не скажу «я предупреждал». Это было бы слишком просто. И слишком жестоко — даже для меня."))
		lines.append(_plain("healer", "Он показывал мне рисунок. Кораблик. Сестра рисовала. Семь лет — а почерк уже лучше, чем у половины солдат."))
		lines.append(_plain("healer", "Я привязался. Не хотел. Но руки делают своё — проверяют, кормят, ворчат. Как будто свой."))
	elif knew_camp:
		lines.append(_plain("healer", "Я говорил — не бери. Ты взял. Теперь мы оба живём с этим."))
		lines.append(_plain("healer", "Знаешь, что он рассказывал мне? Про отца. Что тот работал в порту и не привёз ни одной истории. А этот — хотел привезти. Не успел."))
		lines.append(_plain("healer", "Я слушал его, как слушал бы собственного ребёнка. Не признавался себе. Теперь поздно — и признаваться, и молчать."))
	else:
		lines.append(_plain("healer", "Ты знал о нём хоть что-нибудь? Имя — да. А дальше?"))
		lines.append(_plain("hero", "…Нет. Не успел."))
		lines.append(_plain("healer", "У него была мать. Сестра — семь лет. Он писал им письма и врал, что всё хорошо. Я проверял ему температуру вечерами — он не болел. Просто приходил посидеть рядом."))
		lines.append(_plain("healer", "Ты не спросил. Я не рассказал. И вот мы оба стоим у пустого места, где он должен был стоять."))

	if knew_camp:
		lines.append(_plain("hero", "Он говорил про отца. Что хотел, чтобы было что рассказать за столом."))
		lines.append(_plain("healer", "…Теперь ты — тот, кто расскажет. Только его историю, не свою. Это не привилегия. Это долг."))

	if knew_letter2:
		lines.append(_plain("healer", "Ракушку он так и не нашёл. На каждом острове смотрел. Показывал мне — обломки, трещины. «Нике нужна целая». Я не сказал ему, что целых не бывает."))
	elif not knew_camp and not knew_letter1:
		lines.append(_plain("healer", "Сходи к его койке. В бараке. Там письма. Может, поймёшь — кого мы потеряли. Не солдата. Мальчишку, который хотел привезти домой ракушку."))

	lines.append(_plain("healer", "Запомни его лицо. Не как урок. Как человека, который хотел встать рядом с тобой и сказать: «Я был здесь». Он был. Недолго. Но был."))
	lines.append(_plain("healer", "…Иди. Отдохни. Завтра легче не станет. Но ты встанешь. Потому что он — не смог."))


func _plain(speaker_id: String, text: String) -> DialogueLine:
	var l := DialogueLine.new()
	l.speaker_id = speaker_id
	l.text = text
	return l
