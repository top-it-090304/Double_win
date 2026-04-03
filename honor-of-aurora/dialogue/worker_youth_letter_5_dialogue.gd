extends DialogueSequence

## Пятый обмен: после четвёртого стража — «ждущий» враг, мать чувствует тяжесть без новостей.
## Триггер: письмо 4 + флаг после босса 4; караван. Следом шестое — со следующим караваном (без нового босса), до похода на пятый остров.


func ensure_lines_ready() -> void:
	if not lines.is_empty():
		return
	id = "worker_youth_letter_5"
	lines.append(_plain("young_worker", "…"))
	lines.append(_plain("narrator", "Он сжимает письмо так, что края ломаются."))
	lines.append(_plain("hero", "Читай. Или я прочту."))
	lines.append(_plain("young_worker", "Нет. Это моё."))
	lines.append(_plain("narrator", "«Сынок. Караванщик молчит больше обычного. Я не требую объяснений — я требую одного: дыши. Ника вчера положила кораблик под подушку мне. Сказала — чтобы сны шли в ту сторону. Я не смеюсь. Я плакать не буду — ты это ненавидишь в письмах. Просто… ответь, когда сможешь. Даже одной строкой. Мама.»"))
	lines.append(_plain("young_worker", "Одна строка — и она уже герой."))
	lines.append(_plain("hero", "Напиши строку."))
	lines.append(_plain("young_worker", "«Мама. Дышу. Сны пусть идут — я ловлю их на берегу. Ракушка ближе, чем кажется. Я помню про подушку. Передай Нике: братик держится. Твой сын.»"))
	lines.append(_plain("young_worker", "Коротко. Как она просила."))


func _plain(speaker_id: String, text: String) -> DialogueLine:
	var l := DialogueLine.new()
	l.speaker_id = speaker_id
	l.text = text
	return l
