extends DialogueSequence


func ensure_lines_ready() -> void:
	if not lines.is_empty():
		return
	id = "youth_letter_healer_prompt"

	lines.append(
		_plain(
			"healer",
			"Свёрток всё ещё с тобой — прощальное письмо. Казённый борт заберёт его только у причала, когда рейс на месте. Ты отдашь его сам у лодки… или тебе нужно время?"
		)
	)
	lines.append(
		_choice("healer", "Реши.", [
			{
				"label": "Схожу к лодке, когда караван придёт — отдам сам.",
				"grant_flags": PackedStringArray(["youth_letter_healer_prompt_done"]),
				"continuation": [
					["healer", "Тогда не медли зря — мать не читает наши сомнения. У причала решай окончательно: отдать или нет."],
				],
			},
			{
				"label": "Мне нужно время. Подумаю, что с этим делать.",
				"grant_flags": PackedStringArray(["youth_letter_healer_prompt_done", "youth_letter_send_deferred"]),
				"continuation": [
					[
						"healer",
						"Хорошо. Только помни: Ника всё ещё вешает кораблики на стену. С каждым рейсом их больше. Когда снова придёт караван — я напомню.",
					],
				],
			},
		])
	)


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
