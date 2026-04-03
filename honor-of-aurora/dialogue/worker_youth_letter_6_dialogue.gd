extends DialogueSequence

## Шестой обмен: второй караван подряд после письма 5 (четвёртый страж уже позади) — слухи о последнем острове, тишина Никы.
## Триггер: письмо 5 прочитано + `youth_miron_letter6_pending_next_caravan` (ставится в конце письма 5); следующий караван. До босса 5.


func ensure_lines_ready() -> void:
	if not lines.is_empty():
		return
	id = "worker_youth_letter_6"
	lines.append(_plain("young_worker", "Милорд… последнее с материка. Пока что."))
	lines.append(_plain("hero", "Пока что — хорошо."))
	lines.append(_plain("narrator", "«Сынок. В порту шепчутся про пятый остров — как будто после него мир перестанет быть прежним. Я не знаю, правда это или страх лодочников. Знаю другое: если ты сейчас читаешь — ты ещё можешь прислать строку. Ника сегодня не рисовала корабли. Сидела у окна. Это хуже рисунков. Не оставляй её в тишине. И меня тоже. Мама.»"))
	lines.append(_plain("young_worker", "Она чувствует. Даже там."))
	lines.append(_plain("hero", "Что ответишь?"))
	lines.append(_plain("young_worker", "«Мама. Я читаю — значит, дышу. Про пятый остров — услышал. Я не один здесь. Нике скажи: корабли снова будут. Я обещал ракушку — обещание не снято. Мы ещё увидимся за столом. Верю. Твой сын.»"))
	lines.append(_plain("young_worker", "…Теперь пусть верит она."))


func _plain(speaker_id: String, text: String) -> DialogueLine:
	var l := DialogueLine.new()
	l.speaker_id = speaker_id
	l.text = text
	return l
