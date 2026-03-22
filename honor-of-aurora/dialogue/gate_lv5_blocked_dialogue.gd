extends DialogueSequence

## Одна реплика при попытке телепорта на последний остров без решения или после отказа.


func ensure_lines_ready() -> void:
	lines.clear()
	id = "gate_lv5_blocked"
	var l := DialogueLine.new()
	l.speaker_id = "healer"
	if StoryState.has_flag("hero_chose_refuse_chain"):
		l.text = "Ты сам отказался от последнего узла. Берег закрыт для тебя по твоей воле — это не трусость, если ты всё ещё спишь с совестью."
	else:
		l.text = "Странник… Сначала зайди в мой круг. Про последний узел нужно поговорить — пока ты не выбрал, я не отпущу тебя на последний берег вслепую."
	lines.append(l)
