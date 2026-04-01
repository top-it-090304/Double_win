extends DialogueSequence


func ensure_lines_ready() -> void:
	if not lines.is_empty():
		return
	id = "youth_letter_sent"

	var knew_camp: bool = StoryState.has_flag("worker_youth_camp_done")
	var knew_letter1: bool = StoryState.has_flag("youth_letter_1_done")
	var knew_letter2: bool = StoryState.has_flag("youth_letter_2_done")
	var has_belongings: bool = StoryState.has_flag("youth_belongings_found")

	lines.append(
		_plain(
			"narrator",
			"Ты у причала — там же, где сходишь на берег после островов. Казённый борт стоит у пирса; целитель молча ждёт сбоку — не вмешиваться, а свидетельствовать."
		)
	)
	lines.append(_plain("healer", "Караванщик отплывает на рассвете. На материк. Мимо порта, где живёт его мать."))
	lines.append(_plain("healer", "Если хочешь отправить — сейчас."))

	if has_belongings and knew_letter2:
		lines.append(_plain("narrator", "Ты достаёшь свёрток: прощальное письмо, ракушку, жестянку с монетами. Всё, что он оставил."))
		lines.append(_plain("hero", "Ракушку тоже?"))
		lines.append(_plain("healer", "Он обещал ей — самую большую. Эта — не та. Но она не знает разницы. Для неё это будет ракушка от брата. С острова. Как он обещал."))
		lines.append(_plain("narrator", "Ты заворачиваешь ракушку в его последнее письмо. Обломок рядом с ложью. Одно другое не портит."))
	elif has_belongings and knew_letter1:
		lines.append(_plain("narrator", "Ты достаёшь его вещи: прощальное письмо, ракушку, рисунок Ники."))
		lines.append(_plain("hero", "Рисунок вложить?"))
		lines.append(_plain("healer", "Нет. Он его не вложил — значит, не хотел. Может, боялся, что мать поймёт. Ракушку — да. Монеты — да. Письмо — обязательно."))
	elif has_belongings:
		lines.append(_plain("narrator", "Ты достаёшь его вещи. Письмо, монеты, ракушку. Ты не знал его толком. Но обещал."))
		lines.append(_plain("healer", "Отправь всё. Пусть мать получит то, что он для неё собрал. Она не знает, откуда это. Ей и не нужно знать."))
	else:
		lines.append(_plain("narrator", "Ты держишь в руках прощальное письмо. Сложенное вчетверо. Ни одной помарки — он переписывал."))

	lines.append(_plain("narrator", "Караванщик ждёт у причала. Немолодой, молчаливый. Принимает свёрток, не спрашивая."))
	lines.append(_plain("hero", "Адрес — на конверте. Порт. Спросите вдову с дочерью. Ника — семь лет."))
	lines.append(_plain("narrator", "Караванщик кивает. Убирает свёрток под плащ."))

	if knew_camp:
		lines.append(_plain("narrator", "Мирон хотел, чтобы было что рассказать за столом. Теперь его историю расскажет письмо. Аккуратный почерк, ни одной помарки. Ложь о работе в порту, ракушка «у знакомого», ботинки для Ники."))
		lines.append(_plain("narrator", "И постскриптум: «Кашу вари. На двоих. Моя порция — Нике. Она растёт»."))
		lines.append(_plain("narrator", "Он убрал себя из-за стола. Тихо. Как будто вышел на минуту. И не вернулся."))
	else:
		lines.append(_plain("narrator", "В письме — ложь о работе в порту. Ракушка «у знакомого». Ботинки для Ники. И постскриптум: «Кашу вари. На двоих. Моя порция — Нике»."))
		lines.append(_plain("narrator", "Он не написал «я приеду». Он знал."))

	lines.append(_plain("narrator", "Лодка отходит от причала. Парус ловит ветер. Письмо уходит на материк — к женщине, которая не спала три ночи, когда узнала, куда уехал сын."))
	lines.append(_plain("narrator", "Она получит его ложь. Лучшую ложь, которую он когда-либо написал."))
	lines.append(_plain("narrator", "И перестанет ждать писем. Как он и хотел."))

	if knew_letter2:
		lines.append(_plain("narrator", "Ника получит ракушку. Не самую большую. Но — от брата. С острова. Как он обещал."))
		lines.append(_plain("narrator", "Она повесит тринадцатый кораблик. Или пятнадцатый. А потом — перестанет. И ракушка останется на полке. Рядом с рисунком рыцаря, который так и не приплыл."))
	lines.append(_plain("healer", "…Ты сделал, что мог. Больше, чем мог."))
	lines.append(_plain("healer", "Иди. Отдохни. Он бы не хотел, чтобы ты стоял тут до рассвета."))


func _plain(speaker_id: String, text: String) -> DialogueLine:
	var l := DialogueLine.new()
	l.speaker_id = speaker_id
	l.text = text
	return l
