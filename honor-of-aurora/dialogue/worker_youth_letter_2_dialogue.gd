extends DialogueSequence

## Второй обмен: мать услышала про потери. Ника перестала спрашивать. Ракушка.
## Триггер: первое письмо есть + флаг после 1-го босса (`youth_miron_mail_after_boss_1`); сцена с ближайшим караваном (см. youth_worker_companion / GameManager).


func ensure_lines_ready() -> void:
	if not lines.is_empty():
		return
	id = "worker_youth_letter_2"
	lines.append(_plain("young_worker", "…"))
	lines.append(_plain("narrator", "Юноша молча протягивает письмо. Не смотрит в глаза."))
	lines.append(_plain("hero", "Опять мама?"))
	lines.append(_plain("narrator", "Кивает."))
	lines.append(_plain("narrator", "«Сынок. Караванщик сказал, что на островах потери. Я не знаю, что это значит — потери. Я знаю, что значит — не дождаться. Ника перестала спрашивать, когда ты приедешь. Просто рисует кораблики и вешает на стену. Их уже семь. Она просит привезти ракушку — самую большую, какая есть. Пожалуйста. Я не прошу подвигов. Я прошу тебя — живого. Мама.»"))
	lines.append(_plain("young_worker", "«Ника перестала спрашивать». Это хуже, чем если бы кричала."))
	lines.append(_plain("hero", "Что напишешь?"))
	lines.append(_plain("young_worker", "«Мама. Я скучаю по твоей каше — тут варят что-то, от чего чайки отворачиваются. Я изменился. Тут есть люди, ради которых стоит стоять рядом. Я вернусь. Обещаю. Когда вернусь — сядем за стол. Все трое. И я расскажу. Скажи Нике: ракушку ищу. Самую большую. Пока не нашёл — но берег длинный. Целую. Твой сын.»"))
	lines.append(_plain("young_worker", "Она будет злиться. Но хотя бы будет знать, что я думаю о них."))
	lines.append(_plain("young_worker", "Я, кстати, правда ищу ракушку. На каждом острове смотрю. Пока одни обломки."))


func _plain(speaker_id: String, text: String) -> DialogueLine:
	var l := DialogueLine.new()
	l.speaker_id = speaker_id
	l.text = text
	return l
