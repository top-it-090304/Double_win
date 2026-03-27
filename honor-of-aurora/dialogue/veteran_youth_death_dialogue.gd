extends DialogueSequence

## Реакция ветерана на гибель юноши. Вина, злость, горечь.


func ensure_lines_ready() -> void:
	if not lines.is_empty():
		return
	id = "veteran_youth_death"

	lines.append(_plain("veteran", "Рыцарь. Стой."))
	lines.append(_plain("veteran", "Юноша. Он не вернулся, да?"))
	lines.append(_plain("hero", "…Нет."))
	lines.append(_plain("veteran", "Я видел его до отплытия. Глаза горели. Руки дрожали, но он прятал их за спину. Он был горд, что его взяли."))
	lines.append(_plain("veteran", "Он пришёл ко мне утром. Попросил «пару советов». Я дал ему три: не отходить от строя, не смотреть в глаза стражу, стрелять только наверняка. Три совета за десять минут. На нормальную подготовку нужно три месяца."))
	lines.append(_plain("veteran", "Десять минут — и ты забрал его на остров. Понимаешь, что это значит?"))
	lines.append(_plain("hero", "Я думал…"))
	lines.append(_plain("veteran", "Ты не думал. Ты чувствовал. Хотел дать ему шанс. Хотел, чтобы он «показал себя». Знаешь, что? Он показал. Показал, как умирает неподготовленный мальчишка."))
	lines.append(_plain("veteran", "Монах предупреждал. Я — нет, потому что не думал, что ты настолько… Ладно. Неважно."))
	lines.append(_plain("veteran", "Я потерял одиннадцать солдат на этих островах. Обученных, закалённых, с оружием. Они знали, что делают — и всё равно погибли. А ты взял мальчишку, который не умел держать строй."))
	lines.append(_plain("veteran", "…Но злиться на тебя бессмысленно. Ты сам это знаешь. Я вижу по глазам."))
	lines.append(_plain("veteran", "Запомни его. Не как «урок» и не как «ошибку». Как имя. Он заслужил хотя бы это."))


func _plain(speaker_id: String, text: String) -> DialogueLine:
	var l := DialogueLine.new()
	l.speaker_id = speaker_id
	l.text = text
	return l
