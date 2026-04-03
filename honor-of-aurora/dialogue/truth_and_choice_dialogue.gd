extends DialogueSequence

## После четвёртого острова: откровение о цели короны и выбор — снять последний узел или отказаться.


func ensure_lines_ready() -> void:
	if not lines.is_empty():
		return
	id = "truth_and_choice"
	lines.append(_plain("healer", "Сядь. Этот разговор я откладывал с того дня, как ты сошёл на берег."))
	lines.append(_plain("healer", "Корона послала тебя не ради тварей. Ей нужно было снять стражей — живые печати, которые мой орден поставил столетия назад, чтобы Заря под архипелагом не проснулась."))
	lines.append(_plain("healer", "Рудники на материке иссякают. Без сердцевины маяки гаснут, торговые пути рушатся. Королю нужен доступ к жилам под островами — а стражи его не пускали. Вот и весь указ."))
	lines.append(_plain("hero", "Ты знал это с самого начала. Ты видел, как я убиваю стражей одного за другим, и молчал."))
	lines.append(_plain("healer", "Да. И вот моя причина — не оправдание, а причина."))
	lines.append(_plain("healer", "Тот же акт, который закроет «стабилизацию архипелага», подпишет мне отпуск. Навсегда. К дочери. К Лиан. Она жива — ты знаешь из писем. Она ждёт. А я… я привязан к этим скалам, пока цепь не разомкнута."))
	lines.append(_plain("healer", "Каждый остров, который ты зачищал, приближал меня к ней. Я молчал не только из-за клятвы ордена. Я молчал, потому что боялся, что ты остановишься — и я навсегда останусь здесь. Прости, если сможешь."))
	lines.append(_plain("hero", "…Ты использовал меня. Как и корона."))
	lines.append(_plain("healer", "Да. Разница в том, что корона этого не стыдится. А я — стою перед тобой и говорю это вслух."))
	lines.append(_plain("healer", "Остался один страж. Последний замок. Если ты снимешь его — Заря начнёт просыпаться. Никто не знает, что будет: старые тексты расходятся. Но рудники откроются, корона получит сердцевину, а я получу дорогу к дочери."))
	lines.append(_plain("healer", "Если откажешься — замок останется. Заря продолжит спать. Корона не получит руды. А я… не увижу Лиан. Может, никогда."))
	if StoryState.has_flag("worker_youth_dead"):
		lines.append(_plain("healer", "Ты уже заплатил цену на этих островах. Юноша мёртв. Не заставляй его смерть быть напрасной — или, наоборот, останови всё, чтобы других не было. Это твоё право."))
	lines.append(_choice("healer", "Теперь ты знаешь всё. И про корону, и про меня. Что ты выберешь?", [
		{
			"label": "Иду на последний остров. Ты увидишь дочь.",
			"grant_flags": PackedStringArray(["truth_and_choice_done", "hero_chose_finish_chain"]),
			"continuation": [
				["hero", "Я не делаю этого ради короны. И не ради указа. Может, ради тебя. Может, ради того, чтобы довести дело до конца — и наконец посмотреть в глаза тому, что я натворил."],
				["healer", "…Спасибо. Не за меч. За честность. Иди. Вернёшься — я буду у церкви. Как всегда."],
			],
		},
		{
			"label": "Отказываюсь. Не буду будить то, что спит, ради чужой руды.",
			"grant_flags": PackedStringArray(["truth_and_choice_done", "hero_chose_refuse_chain"]),
			"continuation": [
				["hero", "Мне жаль, что ты не увидишь дочь. Правда жаль. Но я не буду тем, кто разбудит неизвестность ради чужого удобства. Мой последний поход научил меня одному: цена спешки — чужие жизни."],
				["healer", "…Я знал, что ты можешь так ответить. Готовился к этому каждую ночь. Не получилось подготовиться. Иди, странник. Я… останусь в церкви. Мне нужно написать письмо."],
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
