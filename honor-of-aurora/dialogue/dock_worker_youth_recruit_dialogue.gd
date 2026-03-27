extends DialogueSequence

func ensure_lines_ready() -> void:
	if not lines.is_empty():
		return
	id = "dock_worker_youth_recruit"
	lines.append(_plain("young_worker", "Вы вернулись! Я видел, как лодка подошла к причалу. Я всё ещё здесь — и всё ещё хочу с вами."))
	lines.append(_choice("young_worker", "Ну что, возьмёте? Я готов — хоть в бой, хоть на склад. Как скажете.", [
		{
			"label": "Беру в отряд. Пойдёшь со мной в поход.",
			"grant_flags": PackedStringArray(["worker_youth_recruited"]),
			"continuation": [
				["hero", "Собирайся. Будешь при мне — и слушай приказ, не геройствуй."],
				["young_worker", "Есть! То есть… да! Я не подведу — ни вас, ни тех, кто тут остаётся. Спасибо!"],
			],
		},
		{
			"label": "Пока нет. Жди на базе.",
			"grant_flags": PackedStringArray([]),
			"continuation": [
				["young_worker", "…Понял. Ладно. Буду ждать и работать. Если передумаете — я никуда не денусь."],
			],
		},
		{
			"label": "В поход не возьму. Работай на базе — руда, лес, стадо.",
			"grant_flags": PackedStringArray(["worker_youth_works_on_base"]),
			"continuation": [
				["hero", "На острове тебе нечего делать. Здесь дел полно — руда, дерево, стада. Это тоже служба."],
				["young_worker", "…Ясно. Хорошо. Значит, буду лучшим рабочим на этой базе. Вы ещё пожалеете, что не взяли."],
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
