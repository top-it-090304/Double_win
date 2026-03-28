extends DialogueSequence


func ensure_lines_ready() -> void:
	if not lines.is_empty():
		return
	id = "worker_youth_death"

	var knew_camp: bool = StoryState.has_flag("worker_youth_camp_done")
	var knew_letter1: bool = StoryState.has_flag("youth_letter_1_done")
	var knew_letter2: bool = StoryState.has_flag("youth_letter_2_done")

	lines.append(_plain("narrator", "Засада была короткой. Не великий бой — неловкая возня среди камней. Юноша оступился. Повернулся не туда. Удар пришёлся в бок. Он сел, как будто устал."))
	lines.append(_plain("hero", "Нет. Нет-нет-нет. Держись! Дай руку!"))
	lines.append(_plain("young_worker", "Я… не больно. Странно — не больно. Это нормально?"))

	if knew_camp:
		lines.append(_plain("hero", "Нормально. Смотри на меня. Не отводи глаза. Ты ещё расскажешь. Помнишь? Ты обещал."))
		lines.append(_plain("young_worker", "Вы пообещали, что я расскажу. Помните? Я… я хотел рассказать. За столом. Как папа не смог."))
		lines.append(_plain("young_worker", "Только стол теперь — камни. И каша тут паршивая."))
	else:
		lines.append(_plain("hero", "Нормально. Смотри на меня. Не отводи глаза. Мы сейчас…"))
		lines.append(_plain("young_worker", "Я хотел… Мне было что рассказать. Почти. Вы даже не знаете — о чём."))

	lines.append(_plain("young_worker", "В кармане… письмо. Для мамы. Я написал его заранее. На всякий случай."))
	lines.append(_plain("young_worker", "Там… всё хорошо. Порт, работа, зарплата. Всё как она хотела."))

	if knew_letter2:
		lines.append(_plain("young_worker", "И… ракушку… не нашёл. Я на каждом острове смотрел. Одни обломки."))
		lines.append(_plain("young_worker", "Соври Нике что-нибудь. Скажи — большая. Самая большая на всём берегу. Она поверит."))
		lines.append(_plain("hero", "Найду. Настоящую. Обещаю."))
		lines.append(_plain("young_worker", "…Не обещай. Просто соври. Красиво. Как я врал маме."))
	elif knew_letter1:
		lines.append(_plain("young_worker", "Скажи Нике… что кораблик я сохранил. Он в кармане. Рядом с письмом. Она рисовала… для меня."))
		lines.append(_plain("hero", "Скажу. Всё скажу."))
		lines.append(_plain("young_worker", "Нет. Не всё. Про это — не говори. Пусть думает, что порт. Что чистая работа и хорошая зарплата."))
	else:
		lines.append(_plain("young_worker", "У меня… сестра. Ника. Семь лет. Она думает, что я уехал за сокровищами."))
		lines.append(_plain("young_worker", "Не говори ей. Пусть думает, что нашёл."))
		lines.append(_plain("hero", "У тебя есть семья?"))
		lines.append(_plain("young_worker", "Мама. Сестра. Они ждут. Я… я писал им. Они не знают, где я на самом деле."))

	lines.append(_plain("young_worker", "Отправь. Пожалуйста. Она не должна знать."))

	if knew_camp and knew_letter1:
		lines.append(_plain("narrator", "Он закрывает глаза. Не от боли — от усталости. Той, что не лечится сном."))
	elif knew_camp:
		lines.append(_plain("narrator", "Он замолкает. Рука, которая держала вашу, разжимается."))
	else:
		lines.append(_plain("narrator", "Вы не знали, что у него есть сестра. Вы не знали, что он писал домой. Теперь знаете. Поздно."))

	lines.append(_plain("narrator", "Тишина. Ветер. Волна, которая не знает имён."))
	lines.append(_plain("narrator", "В кармане юноши — сложенный вчетверо лист. Аккуратный почерк. Ни одной помарки — он переписывал."))

	if knew_letter1:
		lines.append(_plain("narrator", "На обратной стороне — кривой рисунок: кораблик с парусом. Подпись: «Нике. От братика с острова». Рисунок он не вложил в конверт. Может, не успел. Может, боялся, что мать поймёт."))
	lines.append(_plain("narrator", "Ты забираешь письмо. Он просил — ты обещал."))


func _plain(speaker_id: String, text: String) -> DialogueLine:
	var l := DialogueLine.new()
	l.speaker_id = speaker_id
	l.text = text
	return l
