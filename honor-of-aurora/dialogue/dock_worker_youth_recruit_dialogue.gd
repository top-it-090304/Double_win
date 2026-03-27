extends DialogueSequence

func ensure_lines_ready() -> void:
	if not lines.is_empty():
		return
	id = "dock_worker_youth_recruit"
	lines.append(_plain("young_worker", "Вы вернулись. Я всё ещё здесь — и всё ещё прошу: возьмите меня с собой. Я готов."))
	lines.append(_choice("young_worker", "Как прикажете: взять меня в отряд в поход, оставить ждать или поставить на работу на базе?", [
		{
			"label": "Беру тебя в отряд — идёшь со мной в поход.",
			"grant_flags": PackedStringArray(["worker_youth_recruited"]),
			"continuation": [
				["hero", "Решение рыцаря: ты в моём отряде. Держись рядом и слушай приказ."],
				["young_worker", "Да, сэр! Я не подведу — ни вас, ни тех, кто остаётся на базе."],
			],
		},
		{
			"label": "Пока нет. Останься на базе и жди.",
			"grant_flags": PackedStringArray([]),
			"continuation": [
				["young_worker", "…Понял. Тогда я буду ждать и работать. Если передумаете — я всё равно здесь."],
			],
		},
		{
			"label": "В поход не возьму. Работай на базе — как остальные.",
			"grant_flags": PackedStringArray(["worker_youth_works_on_base"]),
			"continuation": [
				["hero", "В походе тебе не место. Зато на базе дел полон дом: руда, стада, лес. Слушай приказы, как все рабочие."],
				["young_worker", "Да, милорд. Приступаю — и не буду больше мешать про поход."],
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
