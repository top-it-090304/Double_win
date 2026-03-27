extends DialogueSequence

func ensure_lines_ready() -> void:
	if not lines.is_empty():
		return
	id = "dock_worker_youth_intro"
	lines.append(_plain("young_worker", "Милорд! Я вышел к вам не затем, чтобы сейчас выпрашивать место в отряде."))
	lines.append(_plain("young_worker", "Я доброволец: хочу идти с вами, когда корона отправит людей на острова. До тех пор я не лезу в первые ряды — просто сообщаю, что готов."))
	lines.append(_plain("young_worker", "Сейчас у меня свои хлопоты по складу и причалу: мне пора. Но как только у лагеря начнётся подготовка к походу, я хочу стать полноправным членом вашего отряда — не грузом, а бойцом."))
	lines.append(_plain("young_worker", "И ещё: связник ждёт вас на холме — у него, говорят, сводки и служебные слова. Я не задерживаю."))
	lines.append(_plain("hero", "Запомню."))


func _plain(speaker_id: String, text: String) -> DialogueLine:
	var l := DialogueLine.new()
	l.speaker_id = speaker_id
	l.text = text
	return l
