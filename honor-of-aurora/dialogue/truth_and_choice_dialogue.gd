extends DialogueSequence

## После четвёртого острова: откровение о цели короны и выбор — снять последний узел или отказаться.


func ensure_lines_ready() -> void:
	if not lines.is_empty():
		return
	id = "truth_and_choice"
	lines.append(_plain("healer", "Четвёртый остров взят. Скажу прямо: корона послала тебя не ради «тварей». Ей нужно было снять старых стражей — они держали острова запертыми."))
	lines.append(_plain("healer", "В указе остался один шаг. И твой приказ, и договор ордена с дворцом упираются в последнюю печать. Мелким шрифтом это касается и тех, кто у котла, не с мечом."))
	lines.append(_plain("healer", "В скрытом приложении к договору ордена написано: «довести разжимание цепи до конца». Не охота на зверей — а открыть то, что стражи держали замками."))
	lines.append(_plain("healer", "База не только лагерь. Шахта под ней кормит ту же систему. Кто копает руду, тот помогает пути к последнему острову — даже без меча."))
	lines.append(_plain("hero", "То есть корона использовала меня."))
	lines.append(_plain("healer", "Один и тот же документ закроет и твой указ, и долги ордена перед дворцом. Ты идёшь на последний остров зная цену — или останавливаешься перед последним шагом."))
	lines.append(_choice("healer", "Что ты выбираешь?", [
		{
			"label": "Иду на последний остров. Цену принимаю.",
			"grant_flags": PackedStringArray(["hero_chose_finish_chain"]),
			"continuation": [
				["hero", "Иду с открытыми глазами. Что будет — на мне, не на тебе."],
				["healer", "Спасибо за честность. Иди. Вернёшься — перевяжу."],
			],
		},
		{
			"label": "Отказываюсь: не сниму последнюю печать ради чужого плана.",
			"grant_flags": PackedStringArray(["hero_chose_refuse_chain"]),
			"continuation": [
				["hero", "Я не доведу то, что корона называет «стабилизацией». Мой меч не для чужого сценария."],
				["healer", "Тогда дворец не получит своего акта, а обязательства ордена останутся висеть. Я понимаю. Радости за «спасённый» архипелаг не жди — цена всё равно не в твоих руках."],
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
