extends DialogueSequence

func ensure_lines_ready() -> void:
	if not lines.is_empty():
		return
	id = "dock_worker_youth_intro"
	lines.append(_plain("young_worker", "Сэр… Простите. Я не хотел мешать. Я только что видел, как вы сошли на берег — как в сказке про орден."))
	lines.append(_plain("hero", "Ты кто?"))
	lines.append(_plain("young_worker", "Я здесь на смене — у лодок, у склада. Руки грубые, а сердце… оно всё ещё верит в честь и доблесть. Я знаю, это звучит по-детски."))
	lines.append(_plain("young_worker", "Мне не нужны медали. Мне нужен опыт. Я хочу однажды стать рыцарем — по-настоящему, не по бумаге. И если вы пойдёте на острова… возьмите меня. Я буду держать оборону рядом с вами."))
	lines.append(_plain("hero", "Поход — не учебный двор."))
	lines.append(_plain("young_worker", "Понимаю. Но я не глупый — просто молодой. Я искренне верю, что могу научиться. Пусть сначала маленькими шагами. Только… дайте шанс."))


func _plain(speaker_id: String, text: String) -> DialogueLine:
	var l := DialogueLine.new()
	l.speaker_id = speaker_id
	l.text = text
	return l
