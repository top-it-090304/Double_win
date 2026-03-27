extends DialogueSequence

func ensure_lines_ready() -> void:
	if not lines.is_empty():
		return
	id = "dock_worker_youth_ask_again"
	lines.append(_plain("young_worker", "Милорд… снова прошу: возьмите меня в поход. Я не боюсь. Приказы буду выполнять."))
	lines.append(_choice("young_worker", "Ваш ответ?", [
		{
			"label": "Хорошо. Идёшь со мной в поход.",
			"grant_flags": PackedStringArray(["worker_youth_recruited"]),
			"continuation": [
				["hero", "Решено. В отряде держись рядом."],
				["young_worker", "Есть! Не подведу."],
			],
		},
		{
			"label": "Пока нет. Останься на базе.",
			"grant_flags": PackedStringArray([]),
			"continuation": [
				["young_worker", "Понял. Продолжу работу здесь — и снова буду ждать шанса."],
			],
		},
		{
			"label": "В поход не возьму. Работай на базе — как остальные.",
			"grant_flags": PackedStringArray(["worker_youth_works_on_base"]),
			"continuation": [
				["hero", "По-прежнему без походов. Дел на базе достаточно — слушай приказы, как прочие рабочие."],
				["young_worker", "Слушаюсь, милорд. За работу."],
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
