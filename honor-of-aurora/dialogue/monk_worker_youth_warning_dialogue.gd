extends DialogueSequence

func ensure_lines_ready() -> void:
	if not lines.is_empty():
		return
	id = "monk_worker_youth_warning"
	lines.append(_plain("healer", "Странник… раз уж ты слышал юношу у причала — скажу прямо, без украшений. Он не случайно к тебе бросился: по той же вести, что и мы, ждал рыцаря — по почте короны и словам связников."))
	lines.append(_plain("healer", "Он наивен. У него в голове не план — мечта. На острове это не «опыт»: там убивают быстро, а наивность не броня."))
	lines.append(_plain("healer", "Если ты возьмёшь его в поход, его убьют — или сломают так, что орден не соберёт. А база потеряет рабочие руки: руда, смены, склад — всё это держится на людях, не на героях."))
	lines.append(_plain("healer", "Ты должен научиться принимать правильные решения — не те, что греют душу в моменте, а те, что оставляют лагерь живым."))
	lines.append(_plain("healer", "Я не говорю это, чтобы смягчить тебя. Я говорю это потому, что цена ошибки здесь — не только твоя."))
	lines.append(_plain("healer", "…И ещё: не корми его надеждой, если не готов нести её цену. В лагере такие ошибки потом считают не героями — сменами."))


func _plain(speaker_id: String, text: String) -> DialogueLine:
	var l := DialogueLine.new()
	l.speaker_id = speaker_id
	l.text = text
	return l
