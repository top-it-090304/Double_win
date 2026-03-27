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
	arr.append(_line("healer", "Ты на базе экспедиции у архипелага Аврора. Корабль ушёл, впереди — туман, причал с лодками на острова. По голубиной почте короны мы знали: пришлёшь ты — рыцарь, которого король сам направил сюда."))
	arr.append(_line("hero", "По указу короля я должен освободить острова. Здесь добывают «сердцевину» для маяков и клятв королевства. Кто ты?"))
	arr.append(_line("healer", "Брат ордена. Меня оставили для раненых. Слухи у причала совпали с письмом: ждали не только груз — ждали того, кого при желании короны назовут лордом Авроры, если архипелаг очистит от тварей. Вокруг — твари, люди держатся у стен."))
	arr.append(_line("healer", "Главный остров — наш лагерь. На остальных — сильный враг на каждом: их зовут стражами хаоса, но это не вся правда."))
	arr.append(_line("healer", "Корона обещает награду тому, кто пройдёт все острова и вернёт рудники. В слухах — даже дар «сердца Авроры» — центра архипелага."))
	arr.append(_line("hero", "Значит, мне пройти каждый остров и победить того, кто там главный?"))
	arr.append(_line("healer", "Так в указе. Не спеши: на базе есть припасы и союзники. Когда будешь готов — на причал: оттуда лодки к островам."))
	arr.append(_line("healer", "Шахта на базе кормит маяки рудой — это одна система с островами. Рудокопы в сменах; не всем в бою."))
	arr.append(_line("healer", "На островах рудокоп пригодится иначе: разбор, лом, запас — пока ты держишь оборону."))
	arr.append(_line("healer", "К огню у приюта — дам лечение. Останься, и я верну силы, сколько смогу."))
	lines = arr


func _line(speaker_id: String, text: String) -> DialogueLine:
	var l := DialogueLine.new()
	l.speaker_id = speaker_id
	l.text = text
	return l
