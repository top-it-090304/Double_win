extends DialogueSequence

## После четвёртого острова: откровение о цели короны и выбор — снять последний узел или отказаться.


func ensure_lines_ready() -> void:
	if not lines.is_empty():
		return
	id = "truth_and_choice"
	lines.append(_plain("healer", "Странник… Четвёртый узел снят. Скажу прямо: корона гнала тебя по островам не ради тварей — ради снятия старых узлов цепи. Стражи были затвором, не хозяевами хаоса."))
	lines.append(_plain("healer", "На бумаге дворца остался один шаг — и твой указ, и приложения ордена к сделке с короной завязаны на последней печати. Мелким шрифтом это касается и тех, кто держит котёл, не меч."))
	lines.append(_plain("healer", "В приложении к договору ордена, которое не показывают в первый день, чёрным по пергаменту: «разжимание цепи завершить». Не охота на зверьё — а открыть то, что стражи держали замками."))
	lines.append(_plain("healer", "Помни: база не только хранит тебя — она подпитывает цепь снизу. Кто кормит шахту, тот кормит путь к последнему узлу, даже если не несёт меч."))
	lines.append(_plain("hero", "Ты говоришь, корона использовала меня."))
	lines.append(_plain("healer", "Тот же акт, которым корона подпишет: цепь «готова», закроет и твой указ, и обязательства ордена перед дворцом. Ты пойдёшь на последний узел с открытыми глазами — или остановишься перед последним болтом."))
	lines.append(_choice("healer", "Что ты выбираешь?", [
		{
			"label": "Добить цепь: я принимаю цену и иду на последний узел.",
			"grant_flags": PackedStringArray(["hero_chose_finish_chain"]),
			"continuation": [
				["hero", "Тогда я иду с открытыми глазами. Что будет дальше — не свалю на твою совесть."],
				["healer", "Спасибо за честность. Иди. Когда вернёшься — если вернёшься — я всё равно перевяжу."],
			],
		},
		{
			"label": "Отказаться: я не сниму последнюю печать ради чужого плана.",
			"grant_flags": PackedStringArray(["hero_chose_refuse_chain"]),
			"continuation": [
				["hero", "Я не завершу то, что корона называет «стабилизацией». Мой меч не для чужого сценария."],
				["healer", "Тогда акт не подпишется — и мелкие обязательства ордена останутся висеть вместе с цепью. Я понимаю. Не стану умолять иначе. Но не жди от меня радости за «спасённый» архипелаг — если цена всё равно уйдёт мимо твоих рук."],
			],
		},
	]))


func _plain(speaker_id: String, text: String) -> DialogueLine:
	var l := DialogueLine.new()
	l.speaker_id = speaker_id
	l.text = text
	return l


func _choice(speaker_id: String, prompt: String, option_dicts: Array) -> DialogueChoiceLine:
	var cl := DialogueChoiceLine.new()
	cl.speaker_id = speaker_id
	cl.text = prompt
	for d in option_dicts:
		if not d is Dictionary:
			continue
		var opt := DialogueChoiceOption.new()
		opt.label = str(d.get("label", ""))
		var gf: Variant = d.get("grant_flags", [])
		if gf is PackedStringArray:
			opt.grant_flags = gf
		elif gf is Array:
			opt.grant_flags = PackedStringArray(gf)
		var cont_lines: Array[DialogueLine] = []
		var cont: Variant = d.get("continuation", [])
		if cont is Array:
			for row in cont:
				if row is Array and row.size() >= 2:
					cont_lines.append(_plain(str(row[0]), str(row[1])))
		opt.continuation = cont_lines
		cl.options.append(opt)
	return cl
