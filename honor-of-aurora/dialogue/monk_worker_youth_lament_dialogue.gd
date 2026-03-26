extends DialogueSequence

func ensure_lines_ready() -> void:
	if not lines.is_empty():
		return
	id = "monk_worker_youth_lament"
	lines.append(_plain("healer", "Ты уже взял его с собой — без моего слова. Ладно. У каждого своя дорога к ответственности."))
	lines.append(_plain("healer", "Я бы сказал тебе раньше: он слишком молод для этой воды. Но ты решил быстрее, чем успел спросить."))
	lines.append(_plain("healer", "Теперь держи его ближе к огню после боя — если сможешь. И помни: когда корона считает «ресурс», я считаю швы."))


func _plain(speaker_id: String, text: String) -> DialogueLine:
	var l := DialogueLine.new()
	l.speaker_id = speaker_id
	l.text = text
	return l
