class_name IntroBaseIslandDialogue
extends DialogueSequence

func _init() -> void:
	_ensure_lines()


func _notification(what: int) -> void:
	if what == NOTIFICATION_POSTINITIALIZE:
		_ensure_lines()


func ensure_lines_ready() -> void:
	_ensure_lines()


func _ensure_lines() -> void:
	if not lines.is_empty():
		return
	id = "intro_base_island"
	var arr: Array[DialogueLine] = []
	arr.append(_line("healer", "Странник… Ты на базе экспедиции у архипелага Аврора. Корабль отчалил, впереди — туман, порталы к островам и следы зверя."))
	arr.append(_line("hero", "По указу короля я прибыл освободить острова. Добываемая здесь «сердцевина» держит маяки и клятвы королевства. Кто ты?"))
	arr.append(_line("healer", "Брат ордена. Меня оставили для раненых и утомлённых. Кругом роются твари, люди держатся у стен и дорог, что ещё помнят."))
	arr.append(_line("healer", "Главный остров — наш лагерь. Остальные нужно вычистить от хозяев хаоса: каждый остров — свой узел, свой страж… и своя головная боль."))
	arr.append(_line("healer", "Корона обещает награду тому, кто пройдёт цепь островов и вернёт рудники. В слухах — даже дар «сердца Авроры» — того самого центра цепи."))
	arr.append(_line("hero", "Значит, мне предстоит пройти каждый остров и сокручить тех, кто правит там хаосом?"))
	arr.append(_line("healer", "Таков завет на бумаге. Не спеши: на базе — припасы и союзники. Когда будешь готов — уходи через порталы к берегам."))
	arr.append(_line("healer", "А пока ступи в мой круг — дары целителя твои. Останься подле огня, и я верну тебе силы, сколько смогу."))
	lines = arr


func _line(speaker_id: String, text: String) -> DialogueLine:
	var l := DialogueLine.new()
	l.speaker_id = speaker_id
	l.text = text
	return l
