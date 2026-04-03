extends DialogueSequence

## Четвёртый обмен: после третьего стража — колокол, «церковные» слухи, мать боится слов больше стали.
## Триггер: письмо 3 + флаг после босса 3; караван.


func ensure_lines_ready() -> void:
	if not lines.is_empty():
		return
	id = "worker_youth_letter_4"
	lines.append(_plain("young_worker", "Милорд… можно?"))
	lines.append(_plain("hero", "Письмо?"))
	lines.append(_plain("young_worker", "Да. И снова от неё."))
	lines.append(_plain("narrator", "«Сынок. Сказали — у вас там звонили так, что даже на материке перекрестились те, кто не верит. Я не знаю, хорошо это или страшно. Знаю одно: когда вокруг слишком громко про Бога — люди забывают про людей. Пожалуйста, не геройствуй там, где просят молчать. Ника нарисовала колокол. Я не спрашивала зачем. Мама.»"))
	lines.append(_plain("hero", "Колокол?"))
	lines.append(_plain("young_worker", "Слышал. Один раз. Достаточно, чтобы не хотеть слышать второй."))
	lines.append(_plain("young_worker", "Напишу ей: «Мама. Я слышал. Я цел. Колокол — не про меня. Я про твою кашу и про Никин рисунок. Ракушка ещё в пути — берег длинный, обещание короче, но я держу слово. Твой сын.»"))
	lines.append(_plain("hero", "Правда — в том, что ты цел?"))
	lines.append(_plain("young_worker", "Пока да. Остальное… пусть останется в письме."))


func _plain(speaker_id: String, text: String) -> DialogueLine:
	var l := DialogueLine.new()
	l.speaker_id = speaker_id
	l.text = text
	return l
