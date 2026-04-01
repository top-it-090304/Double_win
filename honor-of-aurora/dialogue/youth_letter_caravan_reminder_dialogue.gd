extends DialogueSequence


func ensure_lines_ready() -> void:
	if not lines.is_empty():
		return
	id = "youth_letter_caravan_reminder"

	lines.append(
		_plain(
			"healer",
			"Снова караван у причала. Ника не устала рисовать кораблики — мать пишет. Свёрток в кармане не стал легче от того, что ты ждёшь."
		)
	)
	lines.append(
		_plain(
			"healer",
			"Когда решишь — иди к лодке, пока борт стоит. Или… останься в нерешительности. Только молчание домой тоже бьёт — ты уже знаешь."
		)
	)


func _plain(speaker_id: String, text: String) -> DialogueLine:
	var l := DialogueLine.new()
	l.speaker_id = speaker_id
	l.text = text
	return l
