extends DialogueSequence

## Привальная сцена: юноша раскрывается как человек перед тем, как может погибнуть.
## Триггер: worker_youth_recruited + первый поход на остров.


func ensure_lines_ready() -> void:
	if not lines.is_empty():
		return
	id = "worker_youth_camp"
	lines.append(_plain("young_worker", "Эй. Не спите ещё? Я… Можно спросить кое-что?"))
	lines.append(_plain("hero", "Спрашивай."))
	lines.append(_plain("young_worker", "Зачем вы сюда пошли? По-настоящему. Не «указ короля». Вы. Лично."))
	lines.append(_plain("hero", "Чтобы доказать, что я не тот, кто потерял людей на переправе."))
	lines.append(_plain("young_worker", "…Вы потеряли людей?"))
	lines.append(_plain("hero", "Из-за спешки. Мой приказ, моя вина. Аврора — шанс на искупление, не награда."))
	lines.append(_plain("young_worker", "Мой отец работал в порту. Всю жизнь. Ящики, верёвки, чужие спины. Однажды вечером сел за стол и сказал маме: «Я прожил жизнь, а рассказать нечего». Через год его не стало."))
	lines.append(_plain("young_worker", "Я записался добровольцем на следующее утро. Не ради славы. Чтобы потом, когда сяду за стол — было что сказать."))
	lines.append(_plain("hero", "…Ты расскажешь. Обещаю."))
	lines.append(_plain("young_worker", "Не обещайте. Просто дайте встать рядом. Остальное — моё."))


func _plain(speaker_id: String, text: String) -> DialogueLine:
	var l := DialogueLine.new()
	l.speaker_id = speaker_id
	l.text = text
	return l
