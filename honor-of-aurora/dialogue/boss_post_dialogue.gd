class_name BossPostDialogue
extends DialogueSequence

## 1..5 — номер реплики после острова. Доступ задаётся флагами story_island_N_cleared + цепочка boss_post_{N-1}_done (см. DialogueDefinition).
@export var boss_index: int = 1


func _notification(what: int) -> void:
	if what == NOTIFICATION_POSTINITIALIZE:
		lines.clear()
		_ensure_lines()


func ensure_lines_ready() -> void:
	_ensure_lines()


func _ensure_lines() -> void:
	if not lines.is_empty():
		return
	id = "boss_post_%d" % boss_index
	var arr: Array[DialogueLine] = []
	match boss_index:
		1:
			arr.append(_line("healer", "Ты вернулся. И на ногах — уже хорошо."))
			arr.append(_line("hero", "Главный враг на острове мёртв. Остальные твари дрались слишком синхронно — как по одной команде."))
			arr.append(_line("healer", "Это тревожно: тут не просто зверье. У старых стражей иногда находили клеймо, похожее на корону. Совпадение или нет — не гадай слишком рано."))
			arr.append(_line("healer", "Король ждёт руду. Я жду, чтобы ты был жив. Поешь у огня — на пустой желудок геройствовать нельзя."))
		2:
			arr.append(_line("hero", "Второй остров… По карте шахта была. На месте её нет."))
			arr.append(_line("healer", "Карту подправляют задним числом. Старые договоры про этот архипелаг говорили не про руду, а про тишину — чтобы ничего не будить."))
			arr.append(_line("hero", "Ты знал?"))
			arr.append(_line("healer", "Я знаю перевязки и людей: приказ звучит убедительнее печати. Держи настойку. Не спрашивай, из чего — из того, что не кусается."))
		3:
			arr.append(_line("healer", "Колокол на Тихой Отмели долго молчал. Как только ты ушёл — он снова ударил. Море нервничает."))
			arr.append(_line("hero", "Я делаю, что велел король."))
			arr.append(_line("healer", "В ордене по старому договору не «освобождать», а «не будить». Я служил при том тексте. Мне платят за швы, не за устав."))
			arr.append(_line("hero", "Почему ты мне помогаешь?"))
			arr.append(_line("healer", "Ты уже здесь. Живого лечить проще, чем хоронить мёртвого героя."))
		4:
			arr.append(_line("hero", "Эти сильные враги — не звериные вожаки. Как будто держали что-то на месте."))
			arr.append(_line("healer", "Они были прослойкой между тобой и тем, что под островами. Ты убрал ещё одного. Всё вокруг шевелится сильнее."))
			arr.append(_line("hero", "Ты говоришь, будто это хорошо."))
			arr.append(_line("healer", "Просто факт. По клятве не могу кричать тебе в лицо. Сегодня — лечение и молитва."))
		5:
			if StoryState.has_flag("truth_and_choice_done"):
				arr.append(_line("healer", "Ты знал, что делаешь, когда шёл на последний остров. Это уже твой выбор."))
			arr.append(_line("hero", "Последний пал. Я сделал всё по указу. Архипелаг свободен?"))
			arr.append(_line("healer", "От стражей — да. От последствий — нет. Приказ был не про добычу руды."))
			arr.append(_line("hero", "О чём?"))
			arr.append(_line("healer", "Про Аврору. Её называют островом, но это скорее «сердце» всего архипелага — связь между островами."))
			arr.append(_line("healer", "В песнях не богиню вспоминали, а зарю в воде — первый свет после ночи."))
			arr.append(_line("healer", "Стражи не были врагами короны. Они были замками."))
			arr.append(_line("healer", "Ты снял замки. Слышишь? Под водой — не только волны. Кто-то вздохнул впервые за столетия."))
			arr.append(_line("hero", "Что я наделал…"))
			arr.append(_line("healer", "По бумаге ты всё сделал правильно. Но бумагу писали не для тебя. Кто выиграл от твоего меча — узнаешь дальше, где корона уже не дотягивается."))
			arr.append(_line("narrator", "Первая часть кончена. Но Аврора только проснулась."))
		_:
			arr.append(_line("healer", "…"))
	lines = arr


func _line(speaker_id: String, text: String) -> DialogueLine:
	var l := DialogueLine.new()
	l.speaker_id = speaker_id
	l.text = text
	return l
