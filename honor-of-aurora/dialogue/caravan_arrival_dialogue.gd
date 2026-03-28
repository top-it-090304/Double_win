extends DialogueSequence
class_name CaravanArrivalDialogue

## Караван Короны прибыл на базу. Караванщик передаёт приказ, письма, припасы.
## Тон: деловой, бюрократический, с проблесками человечности.


func ensure_lines_ready() -> void:
	if not lines.is_empty():
		return
	id = "caravan_arrival"

	var order_index := SaveManager.crown_order_index
	var displeasure := SaveManager.crown_displeasure
	var caravan_count := SaveManager.caravan_sent_count
	var title := CrownSystem.get_current_title_name()

	if caravan_count <= 0:
		_build_first_caravan(order_index)
	else:
		_build_regular_caravan(order_index, displeasure, title)

	_build_letter_delivery()
	_build_order_announcement(order_index)
	_build_farewell(displeasure)


func _build_first_caravan(order_index: int) -> void:
	lines.append(_plain("narrator", "На причале — лодка с флагом короны. Караванщик выгружает мешки, не поднимая глаз."))
	lines.append(_plain("caravan", "Приказ Короны — для командира экспедиции. Припасы и жалованье — на складе. Руду грузите сюда."))
	lines.append(_plain("caravan", "Я прихожу регулярно. Привожу письма и указания. Увожу руду. Всё просто."))
	lines.append(_plain("healer", "Просто — для того, кто не копает."))


func _build_regular_caravan(order_index: int, displeasure: int, title: String) -> void:
	lines.append(_plain("narrator", "Караван Короны причалил к базе."))
	if displeasure <= 0:
		lines.append(_plain("caravan", "%s. Корона передаёт жалованье и новый приказ." % title))
	elif displeasure == 1:
		lines.append(_plain("caravan", "%s. Казначей выражает… обеспокоенность темпами добычи. Жалованье урезано." % title))
	elif displeasure == 2:
		lines.append(_plain("caravan", "%s. Снабжение базы переведено на ограниченный режим. Приказ Короны — ускорить отгрузку." % title))
	else:
		lines.append(_plain("caravan", "%s. По указу короны один рудокоп перенаправлен на материк. Корона… недовольна." % title))
		lines.append(_plain("healer", "Недовольна. Красивое слово для тех, кто никогда не держал кирку."))


func _build_letter_delivery() -> void:
	var has_pending_miron_letter := (
		StoryState.has_flag("worker_youth_dead")
		and StoryState.has_flag("youth_belongings_found")
		and not StoryState.has_flag("youth_letter_sent_done")
	)
	var has_lian_letter_1 := (
		StoryState.has_flag("monk_story_3_done")
		and not StoryState.has_flag("monk_letter_1_read")
	)

	if has_lian_letter_1:
		lines.append(_plain("caravan", "Ещё — письмо. На имя целителя. Детский почерк."))
		lines.append(_plain("healer", "…Дай сюда."))

	if has_pending_miron_letter:
		lines.append(_plain("healer", "Караванщик. У нас есть конверт на материк. Для матери мальчика, который здесь работал."))
		lines.append(_plain("caravan", "Положите поверх мешков. Отвезу."))

	var knew_youth_letters := StoryState.has_flag("youth_letter_1_done")
	if knew_youth_letters and not StoryState.has_flag("worker_youth_dead"):
		var has_mother_reply := SaveManager.expedition_return_count >= 4
		if has_mother_reply:
			lines.append(_plain("caravan", "Ещё конверт — для юноши. С материка. От матери."))


func _build_order_announcement(order_index: int) -> void:
	var order := BalanceConfig.get_crown_order(order_index)
	if order.is_empty():
		return
	var ore_req := int(order.get("ore_required", 0))
	var letter_text := str(order.get("letter", ""))
	var deadline := int(order.get("deadline_expeditions", 4))

	lines.append(_plain("narrator", "Караванщик разворачивает пергамент с печатью."))
	lines.append(_plain("caravan", "Приказ Короны: поставить %d единиц сердцевины. Срок — %d походов." % [ore_req, deadline]))
	if not letter_text.is_empty():
		lines.append(_plain("caravan", "Приписка казначея: «%s»" % letter_text))


func _build_farewell(displeasure: int) -> void:
	lines.append(_plain("narrator", "Караванщик ждёт у лодки. Загрузите руду — и он отправится."))
	if displeasure >= 2:
		lines.append(_plain("healer", "Маяки горят нашей кровью. А корона считает мешки. Как обычно."))


func _plain(speaker_id: String, text: String) -> DialogueLine:
	var l := DialogueLine.new()
	l.speaker_id = speaker_id
	l.text = text
	return l
