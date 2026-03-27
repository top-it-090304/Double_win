extends DialogueSequence

func ensure_lines_ready() -> void:
	if not lines.is_empty():
		return
	id = "dock_worker_youth_intro"
	lines.append(_plain("young_worker", "Эй! Стойте! Вы же тот рыцарь, которого ждали? С корабля?"))
	lines.append(_plain("young_worker", "Я — доброволец. Записался сам, когда корона вывесила объявление в порту. Все смеялись, что я мелкий. А я всё равно приплыл."))
	lines.append(_plain("young_worker", "Я не прошу в отряд прямо сейчас — понимаю, что нужно сначала доказать. Пока что я при складе и причале, таскаю ящики, режу мясо для стрелков."))
	lines.append(_plain("young_worker", "Но когда начнётся настоящий поход — позовите. Я не подведу. Честно."))
	lines.append(_plain("young_worker", "Ой, и ещё — связник ждёт вас на холме. У него что-то про сводки и печати. Я побежал!"))
	lines.append(_plain("hero", "Запомню."))


func _plain(speaker_id: String, text: String) -> DialogueLine:
	var l := DialogueLine.new()
	l.speaker_id = speaker_id
	l.text = text
	return l
