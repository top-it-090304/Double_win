extends DialogueSequence

## Третий обмен: после второго стража — слухи о карте и шахте, мать цепляется за «правду с бумаги».
## Триггер: письмо 2 прочитано + флаг после босса 2; сцена с ближайшим караваном (см. youth_worker_companion / GameManager).


func ensure_lines_ready() -> void:
	if not lines.is_empty():
		return
	id = "worker_youth_letter_3"
	lines.append(_plain("young_worker", "…Опять. Караванщик не смотрит — просто вручает."))
	lines.append(_plain("narrator", "Конверт мят, как будто его уже открывали и заклеивали."))
	lines.append(_plain("hero", "Плохие вести?"))
	lines.append(_plain("young_worker", "Не знаю. Мама пишет так, будто боится сказать вслух."))
	lines.append(_plain("narrator", "«Сынок. В порту шепчутся: на ваших островах карту рисовали не для людей в лодках. Я не понимаю половину слов — но понимаю «ложь». Если ты рядом с тем, кто держит меч — не будь бумажкой в чужом кармане. Вернись целым. Ника спрашивает, нашёл ли ты ракушку. Я сказала — ищет. Она поверила. Мама.»"))
	lines.append(_plain("young_worker", "Она всегда так: половину — из газет, половину — из сердца."))
	lines.append(_plain("hero", "Ответишь?"))
	lines.append(_plain("young_worker", "«Мама. Я не бумажка. Я стою на ногах — иногда грязных, но своих. Ракушку ищу. Про карту: тут многое не сходится — но я с теми, кто не прячется за чужой почерк. Обнимаю Нике мысленно. Твой сын.»"))
	lines.append(_plain("young_worker", "Пусть думает, что я умнее, чем есть. Так ей легче спать."))


func _plain(speaker_id: String, text: String) -> DialogueLine:
	var l := DialogueLine.new()
	l.speaker_id = speaker_id
	l.text = text
	return l
