extends RefCounted
class_name CampCodexDossier


static func serdtsevina_info_plain() -> String:
	return "Сердцевина — руда из недр Авроры. Верхняя жила под базой даёт малый запас для лагеря, а глубокие жилы под островами закрыты стражами. На материке Сердцевиной питают маяки королевства. Копите руду в шахте и на островах, тратите на услуги и найм, отправляйте караваном Короне — от суммы отправок растёт титул."


static func serdtsevina_info_bbcode() -> String:
	return "[b]Сердцевина[/b] — руда из недр Авроры. Верхняя жила под базой даёт малый запас для лагеря, а глубокие жилы под островами закрыты стражами. На материке Сердцевиной питают [color=#9fd4ff]маяки королевства[/color]. Копите руду в шахте и на островах, тратите на услуги и найм, отправляйте караваном Короне — от суммы отправок растёт [color=#e8c97a]титул[/color]."


static func intro_plain_text() -> String:
	return "Сводка похода, базы и отряда. Лица лагеря — во вкладке «Досье». Ресурсы и термины — во вкладке «Справка»."


static func story_bbcode() -> String:
	var parts: PackedStringArray = []
	parts.append("[font_size=25][b]Аврора[/b][/font_size]\n")
	if not StoryState.has_flag("intro_base_island_done"):
		parts.append("[color=#aab8cc]Ты прибыл на архипелаг Аврора по указу короны. Пять островов, пять стражей. Под каждым — сердцевина, без которой гаснут маяки королевства.[/color]")
		return "\n".join(parts)
	if not StoryState.has_flag("story_island_1_cleared"):
		parts.append("[color=#aab8cc]База экспедиции на главном острове. Целитель Ордена Тихой Зари ждал тебя — корабль ушёл, обратного пути нет. На пяти соседних островах сидят стражи, запирающие рудники.[/color]")
		return "\n".join(parts)
	var cleared := _count_cleared_islands()
	if cleared < 3:
		parts.append("[color=#aab8cc]Стражи — не дикие твари. На первом нашлось клеймо ордена — восьмиконечная звезда. Карты короны лгут: шахты, обещанной казначеем, не оказалось. Рудники на материке иссякают, и корона идёт на всё ради сердцевины.[/color]")
	elif not StoryState.has_flag("truth_and_choice_done"):
		parts.append("[color=#aab8cc]Под архипелагом спит Заря — первобытная сила моря, старше слов для неё. Стражи были печатями, которые орден поставил столетия назад. Колокол на Тихой Отмели зазвонил после третьего — впервые за сто лет. С каждым убитым стражем сон тоньше.[/color]")
	elif not StoryState.has_flag("story_island_5_cleared"):
		parts.append("[color=#aab8cc]Монах признался: стражи — печати ордена. Корона знала это с самого начала. Каждый снятый узел приближал монаху отпуск к дочери. Осталось решить: будить Зарю или оставить последний замок на месте.[/color]")
	else:
		parts.append("[color=#aab8cc]Замки сняты. Вода светится, деревья скрипят без ветра, под землёй — гул. Заря просыпается. Ни орден, ни корона не знают, чем это кончится. Мир уже не будет прежним.[/color]")
	return "\n".join(parts)


static func personal_bbcode() -> String:
	var lines: PackedStringArray = []
	if StoryState.has_flag("monk_ch2_hope") or StoryState.has_flag("monk_ch4_hope") or StoryState.has_flag("monk_ch5_hope"):
		lines.append("[color=#a8c4a0]Ты давал монаху надежду — обещал, что путь закончится светом.[/color]")
	if StoryState.has_flag("monk_ch2_doubt") or StoryState.has_flag("monk_ch4_doubt") or StoryState.has_flag("monk_ch5_doubt"):
		lines.append("[color=#c4b8a0]Ты не скрывал сомнений — говорил монаху то, что не хотят слышать.[/color]")
	if StoryState.has_flag("monk_ch2_duty") or StoryState.has_flag("monk_ch4_duty") or StoryState.has_flag("monk_ch5_duty"):
		lines.append("[color=#a0b8c4]Ты напоминал монаху о долге — сначала контракт, потом дорога.[/color]")
	if StoryState.has_flag("worker_youth_dead"):
		lines.append("[color=#c4a0a0]Мирон погиб на островах. Монах не произнёс ни слова — только руки дрожали. Дома — мать и сестра, которая рисует кораблики. В кармане — ложь, написанная заранее: «Кашу вари. На двоих. Моя порция — Нике». Он убрал себя из-за стола задолго до смерти.[/color]")
	elif StoryState.has_flag("worker_youth_recruited"):
		lines.append("[color=#a0c4a8]Ты взял Мирона в отряд. Решение — на твоей совести.[/color]")
	elif StoryState.has_flag("worker_youth_works_on_base"):
		lines.append("[color=#a8c4a0]Мирон работает на базе. Целый, живой.[/color]")
	if StoryState.has_flag("hero_chose_finish_chain"):
		lines.append("[color=#c8c4a0]Ты решил идти до конца — снять последнюю печать.[/color]")
	if StoryState.has_flag("hero_chose_refuse_chain"):
		lines.append("[color=#a0b0c8]Ты отказался будить Зарю. Замок стоит.[/color]")
	if lines.is_empty():
		lines.append("[color=#aab8cc]Пока записывать нечего. Впереди — острова и беседы у церкви.[/color]")
	return "\n".join(lines)


static func get_character_entries() -> Array[Dictionary]:
	return [
		{
			"key": "hero",
			"display_name": "Рыцарь",
			"role_line": "Капитан отряда · ближний бой и щит",
			"brief_plain": "Рыцарь Авроры. Ведёт отряд и исследует острова по указу короны.",
			"portrait": "res://Asets/Unit_pack/UI Elements/UI Elements/Human Avatars/aa_player.png",
		},
		{
			"key": "healer",
			"display_name": "Целитель",
			"role_line": "Брат Ордена Тихой Зари · церковь на базе",
			"brief_plain": "Целитель экспедиции: лечение, контракт ордена с короной и беседы у церкви.",
			"portrait": "res://Asets/Unit_pack/UI Elements/UI Elements/Human Avatars/aa_healler.png",
		},
		{
			"key": "youth",
			"display_name": "Мирон",
			"role_line": "Доброволец · склад и причал",
			"brief_plain": "Доброволец с причала: работа на базе и мечта о настоящем походе. Дома — мать и сестра Ника.",
			"portrait": "res://Asets/Unit_pack/UI Elements/UI Elements/Human Avatars/Avatars_05.png",
		},
		{
			"key": "veteran",
			"display_name": "Бран",
			"role_line": "Ветеран-лучник · стрельбище",
			"brief_plain": "Бывший королевский стрелок первой экспедиции. Тренирует лучников и помнит тех, кого списали в «допустимые потери».",
			"portrait": "res://Asets/Unit_pack/UI Elements/UI Elements/Human Avatars/Avatars_08.png",
		},
	]


static func build_stats_bbcode(tree: SceneTree) -> String:
	var sections := _build_stats_sections(tree)
	var out := ""
	for s in sections:
		var sd: Dictionary = s
		var title: String = sd["title"]
		if title == "Исследование мира":
			out += _render_lore_progress(sd)
		else:
			out += "[font_size=21][b]%s[/b][/font_size]\n" % title
			for item in sd["items"]:
				var row: Dictionary = item
				out += "[color=#9eb0c8]%s[/color]  —  [color=#e8ecf0]%s[/color]\n" % [row["label"], row["value"]]
			out += "\n"
	return out


## Данные для отдельной карточки «Титул Короны» в сводке (иконка + текст, без растягивания в RichTextLabel).
static func crown_dossier_panel_data() -> Dictionary:
	var path := CrownSystem.get_current_crown_title_art_path()
	var has_art := path != "" and ResourceLoader.exists(path)
	var nm := CrownSystem.get_current_title_name()
	var t: Dictionary = CrownSystem.get_current_title()
	var ore_cap := int(t.get("expedition_ore_carry_bonus", 0))
	var gold_r := float(t.get("gold_bonus_ratio", 0.0))
	var disc := float(t.get("service_discount", 0.0))
	var chp := int(t.get("combat_hp_bonus", 0))
	var cin := float(t.get("combat_incoming_damage_mult", 1.0))
	var xpr := float(t.get("exp_bonus_ratio", 0.0))
	var sent := SaveManager.ore_sent_to_crown_total
	var fx: PackedStringArray = []
	if gold_r > 0.001:
		fx.append("+%d%% к золоту в жалованье каравана" % int(round(gold_r * 100.0)))
	if disc > 0.001:
		fx.append("скидка на здания %d%%" % int(round(disc * 100.0)))
	if ore_cap > 0:
		fx.append("лимит руды с похода +%d" % ore_cap)
	if chp > 0:
		fx.append("+%d HP" % chp)
	if cin < 0.999:
		fx.append("−%d%% урон от врагов" % int(round((1.0 - cin) * 100.0)))
	if xpr > 0.001:
		fx.append("+%d%% опыта" % int(round(xpr * 100.0)))
	var fx_line: String = " · ".join(fx) if fx.size() > 0 else "Следующие ступени титула усилят бонусы."
	return {
		"art_path": path if has_art else "",
		"title_name": nm,
		"sent_line": "Отправлено Короне Сердцевины всего: %d" % sent,
		"fx_line": fx_line,
	}


static func _render_lore_progress(section: Dictionary) -> String:
	var out := "[font_size=21][b]%s[/b][/font_size]\n\n" % section["title"]
	for item in section["items"]:
		var row: Dictionary = item
		var label: String = row["label"]
		var data: Dictionary = row.get("data", {})
		var found: int = int(data.get("found", 0))
		var total: int = int(data.get("total", 0))
		var hint: String = str(data.get("hint", ""))
		var pct := 0
		if total > 0:
			pct = int(float(found) / float(total) * 100.0)
		var bar := _make_bar(found, total)
		var status := ""
		if found >= total and total > 0:
			status = "[color=#6aaa6a] ✓[/color]"
		elif not hint.is_empty():
			status = "  [color=#607080]%s[/color]" % hint
		out += "[color=#b8c4d8]%s[/color]  [color=#8090a8]%d/%d[/color]\n" % [label, found, total]
		out += "%s  [color=#8898a8]%d%%[/color]%s\n\n" % [bar, pct, status]
	return out


static func build_timeline_bbcode() -> String:
	var beats := _timeline_beats()
	var out := ""
	var any := false
	for b in beats:
		var d: Dictionary = b
		var flg: String = String(d.get("flag", ""))
		if flg != "" and not StoryState.has_flag(flg):
			continue
		any = true
		var title: String = String(d.get("title", ""))
		var body: String = String(d.get("body", ""))
		out += "[font_size=22][b]%s[/b][/font_size]\n[font_size=21][color=#b8c0d0]%s[/color][/font_size]\n\n" % [title, body]
	if not any:
		return "[font_size=20][color=#8899aa]Хронология пуста. Исследуй острова — события появятся здесь.[/color][/font_size]"
	return out.strip_edges()


static func _timeline_beats() -> Array:
	return [
		{"flag": "intro_base_island_done", "title": "Прибытие на Аврору", "body": "Корабль ушёл. Целитель Ордена Тихой Зари встретил на берегу. Пять островов, пять стражей. Под ними — глубокие жилы Сердцевины для маяков Короны."},
		{"flag": "worker_youth_intro_done", "title": "Мирон на причале", "body": "Доброволец по объявлению короны. Просится в отряд — или хотя бы в работу."},
		{"flag": "veteran_archer_intro_done", "title": "Бран у стрельбища", "body": "Ветеран первой экспедиции. Пятнадцать лет на этих камнях. Тренирует лучников и помнит каждое из одиннадцати имён."},
		{"flag": "story_island_1_cleared", "title": "Первый страж повержен", "body": "На костях — клеймо ордена. Восьмиконечная звезда. Стражей поставили люди."},
		{"flag": "monk_story_1_done", "title": "В церкви: орден и контракт", "body": "Монах рассказал о контракте с короной: «до стабилизации узлов» — без срока, без даты."},
		{"flag": "story_island_2_cleared", "title": "Второй страж повержен", "body": "Шахты на карте не оказалось — казначей нарисовал её для указа. Корона знала заранее."},
		{"flag": "monk_story_2_done", "title": "В церкви: жена и дочь", "body": "Монах приехал вдовцом. Дочь Лиан считал мёртвой. Каждый снятый узел приближает конец контракта."},
		{"flag": "story_island_3_cleared", "title": "Третий страж повержен", "body": "Колокол на Тихой Отмели зазвонил впервые за сто лет. Стражи — печати. Под архипелагом спит Заря."},
		{"flag": "monk_story_3_done", "title": "В церкви: печати и цепь", "body": "Море теплее, ветер резче. Монах подтвердил правду: стражи — творение ордена."},
		{"flag": "monk_letter_1_read", "title": "Первое письмо Лиан", "body": "«Папа. Если ты это читаешь — просто скажи «жив»». Она научилась читать сама. Первое слово — «папа». Показать было некому."},
		{"flag": "monk_story_4_done", "title": "В церкви: Лиан жива", "body": "Письмо с большой земли. Лиан жива. Монах дрожит — впервые говорит о том, чего хочет для себя."},
		{"flag": "story_island_4_cleared", "title": "Четвёртый страж повержен", "body": "Страж не нападал первым — стоял и ждал. Живой замок ордена. Остался один."},
		{"flag": "monk_story_5_done", "title": "В церкви: свобода и цена", "body": "Монах: «Моя свобода зависит от твоего решения». Один акт — и контракт закрыт."},
		{"flag": "monk_letter_2_read", "title": "Второе письмо Лиан", "body": "«Не умирай по дороге. Это всё, о чём прошу». Она хранит мешочек с его травами. Он уже не пахнет. А она помнит."},
		{"flag": "youth_letter_1_done", "title": "Письмо с материка", "body": "Мать Мирона узнала, где он. Сестра Ника рисует кораблики и спрашивает каждое утро: «Когда приедет?» Мирон ответил: «Вернусь с историей»."},
		{"flag": "worker_youth_camp_done", "title": "Беседа с Мироном", "body": "Он спросил: «Зачем вы сюда пошли?» И рассказал про отца, который всю жизнь таскал ящики, а за столом ему нечего было сказать. «Я хочу, чтобы было что рассказать»."},
		{"flag": "youth_letter_2_done", "title": "Второе письмо мамы", "body": "«Ника перестала спрашивать, когда ты приедешь. Просто рисует кораблики и вешает на стену. Их уже семь». Мирон обещал привезти ракушку — самую большую."},
		{"flag": "youth_letter_3_done", "title": "Письмо после второго стража", "body": "Мать слышала про ложную карту и шахту. Просила не быть «бумажкой в чужом кармане». Мирон ответил: стоит на своих ногах и ищет ракушку."},
		{"flag": "youth_letter_4_done", "title": "Письмо после третьего стража", "body": "Слухи дошли до порта: колокол, перекрестившиеся лодочники. Мать просила не геройствовать там, где просят молчать. Ника нарисовала колокол."},
		{"flag": "youth_letter_5_done", "title": "Письмо после четвёртого стража", "body": "Караванщик молчал; мать просила одного — «дыши». Ника положила кораблик под подушку, чтобы сны шли «в ту сторону». Мирон ответил одной короткой строкой."},
		{"flag": "youth_letter_6_done", "title": "Шестое письмо (второй караван)", "body": "После четвёртого стража пришли два конверта подряд: пятое и шестое. В шестом — слухи о пятом острове и Ника у окна без рисунков. Мирон ответил, что не один и что стол для троих ещё возможен — до последнего похода."},
		{"flag": "worker_youth_dead", "title": "Гибель Мирона", "body": "Нелепая засада среди камней. Последние слова: «Отправь письмо. Она не должна знать». В кармане — прощание, замаскированное под хорошие новости. Он не написал «я приеду». Написал: «Моя порция — Нике. Она растёт». Убрал себя из-за стола."},
		{"flag": "youth_postmortem_1_done", "title": "Почта мёртвому", "body": "Письмо от матери пришло с караваном; целитель забрал конверт у причала и нашёл тебя в лагере. Она не знает. Монах прочитал. Прощальное письмо нужно отправить."},
		{"flag": "youth_postmortem_2_done", "title": "Одиннадцатый кораблик", "body": "Ника прислала рисунок: «Братик-рыцар. Он ищет ракушку». Она всё ещё верит. Стена конечна — вера нет."},
		{"flag": "youth_letter_sent_done", "title": "Письмо ушло", "body": "Караванщик увёз прощальное письмо Мирона на материк. Ложь — домой. Она получит его «хорошие новости» и перестанет ждать."},
		{"flag": "truth_and_choice_done", "title": "Правда и выбор", "body": "Монах признался во всём: стражи — печати, «тварь» — ложь короны, отпуск — его личная ставка. Выбор за тобой."},
		{"flag": "hero_chose_finish_chain", "title": "Решение: идти до конца", "body": "Ты пообещал снять последнюю печать. Монах увидит дочь. Заря проснётся."},
		{"flag": "hero_chose_refuse_chain", "title": "Решение: отказ", "body": "Ты отказался будить Зарю. Замок стоит. Монах остаётся — навсегда."},
		{"flag": "monk_story_6_done", "title": "Финал линии монаха", "body": "Последняя исповедь в церкви. Монах уходит — или остаётся — с тем, что ты помог ему понять."},
		{"flag": "story_island_5_cleared", "title": "Пятый страж повержен", "body": "Все замки сняты. Вода светится. Заря просыпается. Мир уже не будет прежним."},
		{"flag": "story_part1_refused_path", "title": "Финал: отказ", "body": "Последний страж стоит. Заря спит. Рыцарь уходит с чистой совестью. Корона ищет другой меч."},
	]


static func _count_cleared_islands() -> int:
	var n := 0
	for i in range(1, 6):
		if StoryState.has_flag("story_island_%d_cleared" % i):
			n += 1
	return n


static func _build_stats_sections(tree: SceneTree) -> Array:
	var p: Node = tree.get_first_node_in_group("player")
	var tier := HeroProgression.get_tier_for_level(SaveManager.current_level)
	var max_hp: int = tier.max_health
	var dmg: int = tier.attack_damage
	if p:
		if p.get("max_health") != null:
			max_hp = int(p.max_health)
		if p.get("attack_damage") != null:
			dmg = int(p.attack_damage)
	var need_exp := 0
	if p and p.has_method("get_exp_to_next_level"):
		need_exp = maxi(0, p.get_exp_to_next_level() - SaveManager.current_exp)
	var sections: Array = []
	var prog: Dictionary = {"title": "Прогресс", "items": []}
	prog["items"].append({"label": "Уровень героя", "value": str(SaveManager.current_level)})
	prog["items"].append({"label": "Опыт", "value": str(SaveManager.current_exp)})
	prog["items"].append({"label": "До следующего уровня", "value": "%d опыта" % need_exp})
	sections.append(prog)
	var combat: Dictionary = {"title": "Бой и защита", "items": []}
	combat["items"].append({"label": "Текущее здоровье", "value": "%d / %d" % [SaveManager.current_health, max_hp]})
	combat["items"].append({"label": "Урон атаки", "value": str(dmg)})
	if GameManager.armory_attack_bonus != 0:
		combat["items"].append({"label": "Бонус оружейной (выезд)", "value": "+%d к урону" % GameManager.armory_attack_bonus})
	combat["items"].append(
		{"label": "Щит при блоке", "value": "×%.2f входящего (меньше — лучше)" % GameManager.armory_shield_damage_factor}
	)
	sections.append(combat)
	var meta: Dictionary = {"title": "Ресурсы и статистика", "items": []}
	meta["items"].append({"label": "Золото", "value": str(SaveManager.gold)})
	meta["items"].append({"label": "Побеждено боссов", "value": str(SaveManager.boss_kill)})
	meta["items"].append({"label": "Смертей героя", "value": str(SaveManager.death_count)})
	meta["items"].append({"label": "Завершённых походов", "value": str(SaveManager.expedition_return_count)})
	sections.append(meta)
	var base: Dictionary = {"title": "База и армия", "items": []}
	base["items"].append(
		{
			"label": "Нанято всего",
			"value": "лучники %d · копейщики %d · рабочие %d"
			% [SaveManager.archer_count, SaveManager.lancer_count, SaveManager.pawn_count],
		}
	)
	base["items"].append({"label": "Отмеченных зон на островах", "value": str(SaveManager.island_zone_state.size())})
	base["items"].append(
		{
			"label": "Здания (уровень)",
			"value": "церковь %d · замок %d · оружейная %d · стрельбище %d"
			% [
				SaveManager.get_building_tier("Monastery") + 1,
				SaveManager.get_building_tier("Castle") + 1,
				SaveManager.get_building_tier("Barracks") + 1,
				SaveManager.get_building_tier("Archery") + 1,
			],
		}
	)
	sections.append(base)
	sections.append(_build_lore_progress_section())
	return sections


static func _build_lore_progress_section() -> Dictionary:
	var items: Array = []

	## Титулы после стартового «Рекрута»: 5 ступеней, счётчик = индекс текущего титула (0…5).
	var crown_extra := BalanceConfig.CROWN_TITLES.size() - 1
	if crown_extra < 1:
		crown_extra = 1
	var crown_idx := BalanceConfig.get_crown_title_index_for_ore_sent(SaveManager.ore_sent_to_crown_total)
	var crown_found := clampi(crown_idx, 0, crown_extra)
	items.append(
		_progress_row_raw(
			"Титулы Короны",
			crown_found,
			crown_extra,
			"Отправляйте Сердцевину караваном с базы",
		)
	)

	var boss_flags := ["story_island_1_cleared", "story_island_2_cleared", "story_island_3_cleared", "story_island_4_cleared", "story_island_5_cleared"]
	items.append(_progress_row("Стражи повержены", boss_flags, "Исследуйте острова"))

	var chest_ids := ChestLoreLibrary.get_all_note_ids()
	var chest_found := 0
	for nid in chest_ids:
		if SaveManager.has_lore_note(nid):
			chest_found += 1
	var chest_total := chest_ids.size()
	items.append(_progress_row_raw("Записки из сундуков", chest_found, chest_total, "Ищите сундуки на островах"))

	var healer_flags := ["lore_deaths_liturgy_done", "lore_archer_sentinel_done", "lore_mine_chain_done", "lore_worker_island_done", "lore_gold_blood_done", "lore_return_veteran_done"]
	items.append(_progress_row("Записи целителя", healer_flags, "Навещайте целителя у церкви"))

	var monk_flags := ["monk_story_1_done", "monk_story_2_done", "monk_story_3_done", "monk_story_4_done", "monk_story_5_done", "monk_story_6_done"]
	items.append(_progress_row("Истории целителя", monk_flags, "Говорите с целителем"))

	var veteran_flags := ["veteran_story_1_done", "veteran_story_2_done", "veteran_story_3_done", "veteran_story_4_done"]
	items.append(_progress_row("Истории ветерана", veteran_flags, "Говорите с Браном"))

	var lian_flags := ["monk_letter_1_read", "monk_letter_2_read"]
	items.append(_progress_row("Письма Лиан", lian_flags, "Продвигайте линию целителя"))

	var miron_flags := ["youth_letter_1_done", "youth_letter_2_done", "youth_letter_3_done", "youth_letter_4_done", "youth_letter_5_done", "youth_letter_6_done", "worker_youth_death_scene_done", "youth_belongings_found", "youth_postmortem_1_done", "youth_postmortem_2_done", "youth_letter_sent_done"]
	items.append(_progress_row("Линия Мирона", miron_flags, "Общайтесь с Мироном"))

	var item_found := StoryItemLibrary.get_codex_progress_item_unlocked()
	var item_total := StoryItemLibrary.get_codex_progress_item_total()
	items.append(_progress_row_raw("Предметы", item_found, item_total, "Исследуйте и слушайте"))

	return {"title": "Исследование мира", "items": items}


static func _progress_row(title: String, flags: Array, hint: String) -> Dictionary:
	var found := 0
	for f in flags:
		if StoryState.has_flag(str(f)):
			found += 1
	return _progress_row_raw(title, found, flags.size(), hint)


static func _progress_row_raw(title: String, found: int, total: int, hint: String) -> Dictionary:
	return {
		"label": title,
		"value": "",
		"data": {"found": found, "total": total, "hint": hint},
	}


static func _make_bar(found: int, total: int) -> String:
	var bar_len := 10
	var filled := 0
	if total > 0:
		filled = int(round(float(found) / float(total) * float(bar_len)))
	filled = clampi(filled, 0, bar_len)
	var empty := bar_len - filled
	var bar := ""
	if filled > 0:
		bar += "[color=#5a9a5a]%s[/color]" % "█".repeat(filled)
	if empty > 0:
		bar += "[color=#2a3038]%s[/color]" % "░".repeat(empty)
	return bar
