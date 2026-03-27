extends DialogueSequence

func ensure_lines_ready() -> void:
	if not lines.is_empty():
		return
	id = "dock_worker_youth_ask_again"
	lines.append(_plain("young_worker", "Опять вы! И опять я тут. Ну правда — возьмите меня уже. Я же не мешаю, я полезный!"))
	lines.append(_choice("young_worker", "Ну? В отряд, ждать или только работа? Я на всё согласен. Почти.", [
		{
			"label": "Ладно, беру. Идёшь со мной.",
			"grant_flags": PackedStringArray(["worker_youth_recruited"]),
			"continuation": [
				["hero", "Собирайся быстро. Будешь рядом — и без самодеятельности."],
				["young_worker", "Ура! То есть — есть! Всё сделаю как надо!"],
			],
		},
		{
			"label": "Пока нет. Подожди ещё.",
			"grant_flags": PackedStringArray([]),
			"continuation": [
				["young_worker", "Ладно… Жду. Работаю. Но вы же видите — я тут не зря стою!"],
			],
		},
		{
			"label": "В поход не возьму. Работай на базе.",
			"grant_flags": PackedStringArray(["worker_youth_works_on_base"]),
			"continuation": [
				["hero", "Походы — не для тебя. На базе нужны руки — иди работай."],
				["young_worker", "…Хорошо. Значит, кирка. Я справлюсь. Но я бы мог больше."],
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
