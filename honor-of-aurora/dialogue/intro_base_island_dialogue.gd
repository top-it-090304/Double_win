class_name IntroBaseIslandDialogue
extends DialogueSequence

## Тестовый вводный сценарий: рыцарь по приказу короля, архипелаг Аврора, награда — остров.
func _init() -> void:
	_ensure_lines()


func _notification(what: int) -> void:
	# При загрузке из .tres _init иногда не заполняет массив до готовности ресурса.
	if what == NOTIFICATION_POSTINITIALIZE:
		_ensure_lines()


func ensure_lines_ready() -> void:
	_ensure_lines()


func _ensure_lines() -> void:
	if not lines.is_empty():
		return
	id = "intro_base_island"
	var arr: Array[DialogueLine] = []
	arr.append(_line("healer", "Странник… Ты ступил на берег Авроры — первого из островов архипелага. Корабль отчалил, а впереди только туман и следы зверя."))
	arr.append(_line("hero", "По указу короля я прибыл освободить эти земли. Кто ты?"))
	arr.append(_line("healer", "Я брат ордена, оставленный здесь служить раненым и утомлённым. Кругом роются твари, а люди держатся лишь у стен и дорог, что ещё не забыли."))
	arr.append(_line("healer", "Король дал обет: кто вычистит все острова и прогонит тьму с каждого из них, тот получит в дар самый сокровенный — остров Аврора, сердце архипелага."))
	arr.append(_line("hero", "Значит, мне предстоит пройти каждый остров и сокручить тех, кто правит там хаосом?"))
	arr.append(_line("healer", "Таков завет. Не спеши: на базе ты найдёшь припасы и союзников. Когда будешь готов — отправляйся через порталы к следующим берегам."))
	arr.append(_line("healer", "А пока ступи в мой круг — дары целителя твои. Останься подле огня, и я верну тебе силы, сколько смогу."))
	lines = arr


func _line(speaker_id: String, text: String) -> DialogueLine:
	var l := DialogueLine.new()
	l.speaker_id = speaker_id
	l.text = text
	return l
