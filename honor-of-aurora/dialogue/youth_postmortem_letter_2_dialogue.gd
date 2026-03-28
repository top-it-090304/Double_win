extends DialogueSequence


func ensure_lines_ready() -> void:
	if not lines.is_empty():
		return
	id = "youth_postmortem_letter_2"

	var knew_letter1: bool = StoryState.has_flag("youth_letter_1_done")
	var knew_letter2: bool = StoryState.has_flag("youth_letter_2_done")

	lines.append(_plain("narrator", "Целитель стоит у огня. Перед ним — свёрток. Маленький, перевязанный верёвкой."))
	lines.append(_plain("healer", "Опять пришло. На его имя."))

	if knew_letter2:
		lines.append(_plain("healer", "Не письмо. Посылка."))
		lines.append(_plain("narrator", "Внутри — рисунок. Новый. Кораблик больше прежнего, с двумя парусами. Рядом — фигурка с мечом. Подпись: «Братик-рыцар. Он ищет ракушку»."))
		lines.append(_plain("narrator", "Через «а». Ей семь — или уже восемь. Она всё ещё рисует."))
		lines.append(_plain("healer", "Одиннадцатый кораблик. Она вешает их на стену. Скоро стены не хватит."))
		lines.append(_plain("narrator", "К рисунку приложена записка: «Ника говорит — когда кораблик дойдёт до острова, братик его увидит и приплывёт обратно. Я не спорю. Она верит за нас обоих. Мама.»"))
		lines.append(_plain("healer", "…Она верит за нас обоих."))
		lines.append(_plain("narrator", "Монах повторяет это дважды. Потом замолкает."))
	elif knew_letter1:
		lines.append(_plain("narrator", "Внутри — два листка. Письмо и рисунок."))
		lines.append(_plain("narrator", "Рисунок: кораблик с парусами, рядом — человечек с мечом. Подпись: «Братик-рыцар». Через «а»."))
		lines.append(_plain("healer", "Ника. Ей семь. Она думает, что брат — рыцарь."))
		lines.append(_plain("narrator", "Письмо: «Сынок. Писем нет. Ника говорит — ты просто занят. Она рисует тебе кораблики. Каждый день. Я не могу ей объяснить, почему ты молчишь. Потому что сама не знаю. Мама.»"))
		lines.append(_plain("narrator", "Сама не знает. И не узнает — пока не получит его прощальное."))
	else:
		lines.append(_plain("narrator", "Монах открывает. Два листка: исписанный и цветной, мятый, с детским рисунком."))
		lines.append(_plain("healer", "Мать. И сестра — Ника. Она рисует кораблики. Думает, что брат ищет сокровища."))
		lines.append(_plain("narrator", "Рисунок: кораблик, человечек с мечом, подпись: «Братику-рыцару». Через «а». Рядом — огромная ракушка, больше кораблика."))
		lines.append(_plain("narrator", "Письмо: «Сынок. Ответь. Одно слово. Любое. Мама.»"))
		lines.append(_plain("narrator", "Четыре слова от женщины, которая не спала три ночи, когда узнала, куда он уехал. Теперь не спит, потому что молчит не лодочница — молчит он."))

	lines.append(_plain("healer", "Мы отправили его письмо?"))
	lines.append(_plain("hero", "Нет ещё."))
	lines.append(_plain("healer", "Чем дольше тянем — тем больше рисунков. Тем больше кораблей на стене. Тем тяжелее потом."))
	lines.append(_plain("healer", "Отправь. Пусть она получит его ложь. Пусть перестанет ждать. Пусть Ника дорисует последний кораблик — и повесит рядом с ракушкой, которой нет."))
	lines.append(_plain("narrator", "Рисунок ты кладёшь к его вещам. Ника старалась. Два паруса. Рыцарь с мечом. Ракушка — огромная. Такой не бывает. Но она не знает."))


func _plain(speaker_id: String, text: String) -> DialogueLine:
	var l := DialogueLine.new()
	l.speaker_id = speaker_id
	l.text = text
	return l
