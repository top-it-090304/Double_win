extends DialogueSequence

## Финал линии монаха, если герой отказался снимать последний узел.


func ensure_lines_ready() -> void:
	if not lines.is_empty():
		return
	id = "monk_finale_refused"
	var arr: Array[DialogueLine] = []
	arr.append(_line("healer", "Ты остановился. Цепь не закрыта — и корона не получит своего акта. Договор ордена с дворцом остаётся открытым: что было «после последней печати» — не случится в срок, который обещали на бумаге."))
	arr.append(_line("healer", "Я не виню тебя. Клятва «не навреди» — про чужих на поле боя. Остальное… держу при себе. Личное не для публичного суда."))
	arr.append(_line("hero", "Я не могу быть пешкой в том, что проснётся после последнего замка."))
	arr.append(_line("healer", "Тогда мы оба останемся с пустотой в разных карманах. Я — с надеждой без дороги. Ты — с чистыми руками, пока дворец не найдёт другого меча."))
	arr.append(_line("healer", "Иди, если зовёт совесть. Останься у огня — если нужен только отвар. Я буду здесь."))
	arr.append(_line("narrator", "Часть первая оборвалась не на триумфе. Архипелаг остался с одним неснятым узлом — и с вопросом, чья это победа."))
	lines = arr


func _line(speaker_id: String, text: String) -> DialogueLine:
	var l := DialogueLine.new()
	l.speaker_id = speaker_id
	l.text = text
	return l
