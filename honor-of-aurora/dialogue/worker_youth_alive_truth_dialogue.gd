extends DialogueSequence

## Юноша подходит к рыцарю после truth_and_choice, если жив и на базе (не в отряде).


func ensure_lines_ready() -> void:
	if not lines.is_empty():
		return
	id = "worker_youth_alive_truth"
	lines.append(_plain("young_worker", "Эй… Я слышал разговор у церкви. Не подслушивал — ветер несёт голоса дальше, чем кажется."))
	lines.append(_plain("young_worker", "Это правда? Стражи — не звери? И указ — не про свободу?"))
	lines.append(_plain("hero", "Ты не должен был это слышать."))
	lines.append(_plain("young_worker", "Может, и не должен. Но я рад."))
	if StoryState.has_flag("worker_youth_works_on_base"):
		lines.append(_plain("young_worker", "Вы оставили меня на базе. Я злился. А теперь… Может, вы спасли мне жизнь. Там, на островах, я бы не разобрался, что к чему. Здесь хотя бы полезен — и жив."))
	else:
		lines.append(_plain("young_worker", "Вы не взяли меня с собой. Я ждал, злился, считал дни. А теперь вижу — вы принимали решения, которые мне не по плечу. Спасибо, что не дали влезть."))
	lines.append(_plain("young_worker", "Что бы вы ни решили дальше — я буду тут. Работать. Это я могу точно."))


func _plain(speaker_id: String, text: String) -> DialogueLine:
	var l := DialogueLine.new()
	l.speaker_id = speaker_id
	l.text = text
	return l
