extends DialogueSequence


func ensure_lines_ready() -> void:
	if not lines.is_empty():
		return
	id = "worker_youth_death"
	lines.append(_plain("narrator", "Засада была короткой. Не великий бой — неловкая возня среди камней. Юноша оступился. Повернулся не туда. Удар пришёлся в бок. Он сел, как будто устал."))
	lines.append(_plain("hero", "Нет. Нет-нет-нет. Держись! Дай руку!"))
	lines.append(_plain("young_worker", "Я… не больно. Странно — не больно. Это нормально?"))
	lines.append(_plain("hero", "Нормально. Смотри на меня. Не отводи глаза. Мы сейчас…"))
	if StoryState.has_flag("worker_youth_camp_done"):
		lines.append(_plain("young_worker", "Вы пообещали, что я расскажу. Помните? Я… я хотел рассказать."))
	else:
		lines.append(_plain("young_worker", "Я хотел… Мне было что рассказать. Почти."))
	lines.append(_plain("young_worker", "В кармане… письмо. Для мамы. Я написал его заранее. На всякий случай."))
	lines.append(_plain("young_worker", "Там… всё хорошо. Порт, работа, зарплата. Всё как она хотела."))
	if StoryState.has_flag("youth_letter_2_done"):
		lines.append(_plain("young_worker", "И… ракушку… не нашёл. Соври Нике что-нибудь."))
	elif StoryState.has_flag("youth_letter_1_done"):
		lines.append(_plain("young_worker", "Скажи Нике… что кораблик я сохранил. Он в кармане. Рядом с письмом."))
	lines.append(_plain("young_worker", "Отправь. Пожалуйста. Она не должна знать."))
	lines.append(_plain("narrator", "Тишина. Ветер. Волна, которая не знает имён."))
	lines.append(_plain("narrator", "На базе вас встречает целитель. Он смотрит на ваши руки. Потом — на пустое место рядом. Потом отворачивается."))
	lines.append(_plain("healer", "…"))
	lines.append(_plain("healer", "Я не скажу «я предупреждал». Ты это знаешь. Я это знаю. Мертвец — нет."))
	if StoryState.has_flag("worker_youth_camp_done"):
		lines.append(_plain("hero", "Он говорил про отца. Что хотел, чтобы было что рассказать за столом."))
		lines.append(_plain("healer", "…Теперь ты — тот, кто расскажет. Только его историю, не свою. Это не привилегия. Это долг."))
	lines.append(_plain("narrator", "В кармане юноши — сложенный вчетверо лист. Аккуратный почерк. Ни одной помарки — он переписывал."))
	if StoryState.has_flag("youth_letter_1_done"):
		lines.append(_plain("narrator", "На обратной стороне — кривой рисунок: кораблик с парусом. Подпись: «Нике. От братика с острова». Рисунок он не вложил в конверт. Может, не успел. Может, боялся, что мать поймёт."))
	lines.append(_plain("healer", "Запомни его лицо. Не как урок. Как человека, который хотел встать рядом с тобой и сказать: «Я был здесь». Он был. Недолго. Но был."))
	lines.append(_plain("healer", "…Иди. Отдохни. Завтра легче не станет. Но ты встанешь. Потому что он — не смог."))


func _plain(speaker_id: String, text: String) -> DialogueLine:
	var l := DialogueLine.new()
	l.speaker_id = speaker_id
	l.text = text
	return l
