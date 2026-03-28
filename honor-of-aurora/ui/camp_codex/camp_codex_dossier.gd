extends RefCounted
class_name CampCodexDossier


static func intro_plain_text() -> String:
	return "Сводка похода, базы и отряда: цифры, общий взгляд на мир и личные пометки. Лица лагеря — во вкладке «Досье»."


static func story_bbcode() -> String:
	return (
		"[font_size=22][b]Аврора[/b][/font_size]\n\n"
		+ "[color=#aab8cc]Архипелаг держит рудники и стражей — пока корона не снимет указ. "
		+ "Каждый поход добавляет к этой картине новый штрих: кто встретился у огня, что открыли острова, чем закончился разговор о цепи.[/color]"
	)


static func personal_bbcode() -> String:
	return (
		"[color=#aab8cc]Свои пометки с дороги — позже. Найденные в мире тексты лежат во вкладке «Архив записок».[/color]"
	)


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
			"role_line": "Брат Ордена Тихой Зари · монастырь на базе",
			"brief_plain": "Целитель экспедиции: лечение, оговорённый с короной контракт ордена и разговоры у огня.",
			"portrait": "res://Asets/Unit_pack/UI Elements/UI Elements/Human Avatars/aa_healler.png",
		},
		{
			"key": "youth",
			"display_name": "Юноша",
			"role_line": "Доброволец · склад и причал",
			"brief_plain": "Доброволец с причала: работа на базе и просьба не забыть о нём, когда начнётся настоящий поход.",
			"portrait": "res://Asets/Unit_pack/UI Elements/UI Elements/Human Avatars/Avatars_05.png",
		},
		{
			"key": "veteran",
			"display_name": "Бран",
			"role_line": "Ветеран-лучник · стрельбище",
			"brief_plain": "Бран, бывший королевский стрелок первой экспедиции. Тренирует лучников и помнит тех, кого списали в «допустимые потери».",
			"portrait": "res://Asets/Unit_pack/UI Elements/UI Elements/Human Avatars/Avatars_08.png",
		},
	]


static func build_stats_bbcode(tree: SceneTree) -> String:
	var sections := _build_stats_sections(tree)
	var out := ""
	for s in sections:
		var sd: Dictionary = s
		out += "[font_size=18][b]%s[/b][/font_size]\n" % sd["title"]
		for item in sd["items"]:
			var row: Dictionary = item
			out += "[color=#9eb0c8]%s[/color]  —  [color=#e8ecf0]%s[/color]\n" % [row["label"], row["value"]]
		out += "\n"
	return out


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
	combat["items"].append({"label": "Здоровье (сохранение)", "value": "%d / %d" % [SaveManager.current_health, max_hp]})
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
			"value": "лучники %d · копейщики %d · пешки %d"
			% [SaveManager.archer_count, SaveManager.lancer_count, SaveManager.pawn_count],
		}
	)
	base["items"].append({"label": "Отмеченных зон на островах", "value": str(SaveManager.island_zone_state.size())})
	base["items"].append(
		{
			"label": "Здания (уровень)",
			"value": "монастырь %d · замок %d · оружейная %d · стрельбище %d"
			% [
				SaveManager.get_building_tier("Monastery") + 1,
				SaveManager.get_building_tier("Castle") + 1,
				SaveManager.get_building_tier("Barracks") + 1,
				SaveManager.get_building_tier("Archery") + 1,
			],
		}
	)
	sections.append(base)
	return sections
