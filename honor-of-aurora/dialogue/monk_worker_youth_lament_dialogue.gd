extends DialogueSequence

func ensure_lines_ready() -> void:
	if not lines.is_empty():
		return
	id = "monk_worker_youth_lament"
	lines.append(_plain("healer", "…"))
	lines.append(_plain("healer", "Ты взял его. Не спросив меня. Не подождав."))
	lines.append(_plain("healer", "Я мог бы кричать — но у крика нет адресата, когда решение уже принято."))
	lines.append(_plain("hero", "Он сам просился."))
	lines.append(_plain("healer", "А ребёнок сам просится в костёр, потому что красиво. Это не аргумент — это приговор твоему решению."))
	lines.append(_plain("healer", "Теперь слушай: держи его позади. Не давай лезть первым. После каждого боя — ко мне, сразу. Если у него будет рана, которую я не зашью, — это будет на тебе. Не на нём. На тебе."))
	lines.append(_plain("healer", "Я видел, как юноши с горящими глазами превращались в тела с открытыми. Не допусти. Или хотя бы попробуй."))


func _plain(speaker_id: String, text: String) -> DialogueLine:
	var l := DialogueLine.new()
	l.speaker_id = speaker_id
	l.text = text
	return l
