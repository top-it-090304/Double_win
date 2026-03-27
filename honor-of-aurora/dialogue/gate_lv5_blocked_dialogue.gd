extends DialogueSequence

## Одна реплика при попытке телепорта на последний остров без решения или после отказа.


func ensure_lines_ready() -> void:
	lines.clear()
	id = "gate_lv5_blocked"
	var l := DialogueLine.new()
	l.speaker_id = "healer"
	if StoryState.has_flag("hero_chose_refuse_chain"):
		l.text = "Ты сам решил не трогать последнюю печать. Берег закрыт — по твоей воле. Это не трусость. Это выбор."
	else:
		l.text = "Стой. Сначала найди меня у костра. Про последний остров нужно поговорить — я не отпущу тебя туда вслепую."
	lines.append(l)
