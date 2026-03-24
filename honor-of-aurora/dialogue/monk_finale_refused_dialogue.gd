extends DialogueSequence

## Финал линии монаха, если герой отказался снимать последний узел.


func ensure_lines_ready() -> void:
	if not lines.is_empty():
		return
	id = "monk_finale_refused"
	var arr: Array[DialogueLine] = []
	arr.append(_line("healer", "Ты остановился. Цепь не замкнута — корона не получит своего акта. Договор ордена с дворцом остаётся незакрытым."))
	arr.append(_line("healer", "Я не виню тебя. Клятва «не навреди» — про раны на поле. Остальное оставлю при себе."))
	arr.append(_line("hero", "Я не буду пешкой в том, что откроется после последнего замка."))
	arr.append(_line("healer", "Тогда у нас обоих незаконченное дело. У меня — надежда без ясного конца. У тебя — чистые руки, пока дворец не найдёт другого меча."))
	arr.append(_line("healer", "Иди, если зовёт совесть. Останься у огня — если нужен только отвар. Я буду здесь."))
	arr.append(_line("narrator", "Первая часть оборвалась не на триумфе. На архипелаге остался последний страж — и неясно, кто в итоге выиграл."))
	lines = arr


func _line(speaker_id: String, text: String) -> DialogueLine:
	var l := DialogueLine.new()
	l.speaker_id = speaker_id
	l.text = text
	return l
