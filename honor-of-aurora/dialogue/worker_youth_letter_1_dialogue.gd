extends DialogueSequence

## Первый обмен письмами: мать узнала, где он. Ника нарисовала кораблик.
## Триггер: worker_youth_recruited/works_on_base + min 2 похода.


func ensure_lines_ready() -> void:
	if not lines.is_empty():
		return
	id = "worker_youth_letter_1"
	lines.append(_plain("young_worker", "Эй. Можно на минуту? Тут… пришло кое-что. Через караван — месяц шло."))
	lines.append(_plain("hero", "Хорошие новости?"))
	lines.append(_plain("young_worker", "Не совсем. Мама написала. И Ника вложила… вот."))
	lines.append(_plain("narrator", "Юноша протягивает мятый рисунок. Кораблик с кривым парусом. Подпись детским почерком: «Братику на остраф»."))
	lines.append(_plain("young_worker", "Через «а». Ей семь — она старается."))
	lines.append(_plain("young_worker", "Мама пишет: «Сынок. Мне сказала жена лодочника, куда ты уехал. Я не спала три ночи. Ника спрашивает каждое утро: когда он приедет? Я не знаю, что ей отвечать. Вернись. В порту есть работа. Отец тоже работал в порту — и каждый вечер приходил домой. Этого достаточно. Мама.»"))
	lines.append(_plain("hero", "Что ответишь?"))
	lines.append(_plain("young_worker", "Уже ответил. Хотите?"))
	lines.append(_plain("young_worker", "«Мама. Я жив, здоров, кормят нормально. Тут есть рыцарь — настоящий. Он берёт меня с собой. Не волнуйся. Скажи Нике, что кораблик повесил на стену. Вру — стены тут нет. Но я его храню в кармане. Я не хочу, чтобы мой стол был таким же пустым, как у папы. Я вернусь с историей. Твой сын.»"))
	lines.append(_plain("hero", "Ника — это сестра?"))
	lines.append(_plain("young_worker", "Младшая. Семь лет. Она думает, что я уехал на море за сокровищами. Я не стал поправлять."))


func _plain(speaker_id: String, text: String) -> DialogueLine:
	var l := DialogueLine.new()
	l.speaker_id = speaker_id
	l.text = text
	return l
