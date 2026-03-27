extends DialogueSequence


func ensure_lines_ready() -> void:
	if not lines.is_empty():
		return
	id = "worker_youth_death"
	lines.append(_plain("narrator", "Юноша не поднялся. Не от героического удара — от глупой, нелепой засады. Он оступился. Не увидел. Был слишком медленный."))
	lines.append(_plain("hero", "Нет… Нет. Вставай. Вставай!"))
	lines.append(_plain("narrator", "Тишина. Ветер. Волна, которая не знает имён."))
	lines.append(_plain("narrator", "На базе вас встречает целитель. Он смотрит на ваши руки. Потом — на пустое место рядом. Потом отворачивается."))
	lines.append(_plain("healer", "…"))
	lines.append(_plain("healer", "Не говори «я не хотел». Это слово для тех, кто стоял в стороне. Ты был рядом. Ты командовал. Ты взял его, зная, что я сказал."))
	lines.append(_plain("hero", "Ты предупреждал."))
	lines.append(_plain("healer", "Да. И это не утешение — ни тебе, ни мне. «Я предупреждал» — самая бесполезная фраза для мертвеца."))
	lines.append(_plain("healer", "Я не буду тебя винить вслух. Ты сделаешь это сам — ночами, когда тихо и некуда бежать."))
	lines.append(_plain("healer", "Запомни его лицо. Не как урок — как долг. Ты теперь носишь чужую жизнь на плечах. Это не снимается. Ни указом, ни молитвой."))
	lines.append(_plain("healer", "…Иди. Отдохни. Завтра мир не станет легче — но хотя бы солнце встанет."))


func _plain(speaker_id: String, text: String) -> DialogueLine:
	var l := DialogueLine.new()
	l.speaker_id = speaker_id
	l.text = text
	return l
