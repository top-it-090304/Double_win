extends RefCounted
class_name CampCodexLoreArchive
## Единая точка данных для вкладки «Архив» кодекса.
## Объединяет записки из сундуков, записи целителя (лор-зоны) и письма Лиан.

const CAT_CROWN := "Корона и политика"
const CAT_ORDER := "Орден и Заря"
const CAT_EXPEDITION := "Первая экспедиция"
const CAT_CAMP := "Быт лагеря"
const CAT_HEALER := "Записи целителя"
const CAT_LETTERS := "✉ Письма Лиан"
const CAT_YOUTH_MAIL := "✉ Переписка Мирона"
const CAT_GRATITUDE := "★ Благодарность авторов"

const CATEGORY_ORDER: PackedStringArray = [
	CAT_CROWN, CAT_ORDER, CAT_EXPEDITION, CAT_HEALER, CAT_LETTERS, CAT_YOUTH_MAIL, CAT_CAMP, CAT_GRATITUDE,
]

const _CATEGORY_HINTS: Dictionary = {
	CAT_LETTERS: "Дочь целителя пишет отцу на острова",
	CAT_YOUTH_MAIL: "Письма Мирона домой и ответы матери",
	CAT_HEALER: "Наблюдения целителя у церкви",
	CAT_EXPEDITION: "Воспоминания тех, кто был здесь до вас",
	CAT_CROWN: "Указы, контракты и политика короны",
	CAT_ORDER: "Тайны Ордена Тихой Зари",
	CAT_CAMP: "Записки и находки из лагеря",
	CAT_GRATITUDE: "Слова тех, кто поддержал экспедицию",
}

const _SPEAKER_NAMES: Dictionary = {
	"healer": "Целитель",
	"veteran": "Ветеран",
	"letter": "",
}

const _LORE_ZONE_META: Dictionary = {
	"lore_crown_purse": {"title": "Казна и маяки", "cat": CAT_CROWN, "flag": "lore_crown_purse_done"},
	"lore_crown_contract": {"title": "Контракт ордена с короной", "cat": CAT_CROWN, "flag": "lore_crown_contract_done"},
	"lore_order_oath": {"title": "Клятва Ордена Тихой Зари", "cat": CAT_ORDER, "flag": "lore_order_oath_done"},
	"lore_chain_seal": {"title": "Пять печатей и цепь", "cat": CAT_ORDER, "flag": "lore_chain_seal_done"},
	"lore_deaths_liturgy": {"title": "О смерти и возвращении", "cat": CAT_HEALER, "flag": "lore_deaths_liturgy_done"},
	"lore_archer_sentinel": {"title": "Лучники на стене", "cat": CAT_HEALER, "flag": "lore_archer_sentinel_done"},
	"lore_mine_chain": {"title": "Шахта и рудокопы", "cat": CAT_HEALER, "flag": "lore_mine_chain_done"},
	"lore_worker_island": {"title": "Рабочий на островах", "cat": CAT_HEALER, "flag": "lore_worker_island_done"},
	"lore_gold_blood": {"title": "Золото и кровь", "cat": CAT_HEALER, "flag": "lore_gold_blood_done"},
	"lore_return_veteran": {"title": "О возвращениях и ранах", "cat": CAT_HEALER, "flag": "lore_return_veteran_done"},
	"lore_veteran_first_expedition": {"title": "Первая экспедиция (рассказ)", "cat": CAT_EXPEDITION, "flag": "lore_veteran_first_expedition_done"},
	"lore_veteran_training": {"title": "Тренировка лучников", "cat": CAT_EXPEDITION, "flag": "lore_veteran_training_done"},
	"monk_story_1": {"title": "В церкви: орден и контракт", "cat": CAT_HEALER, "flag": "monk_story_1_done"},
	"monk_story_3": {"title": "В церкви: три стража и цепь", "cat": CAT_HEALER, "flag": "monk_story_3_done"},
	"monk_letter_1": {"title": "✉ Лиан → отцу (первое)", "cat": CAT_LETTERS, "flag": "monk_letter_1_read", "is_letter": true},
	"monk_letter_2": {"title": "✉ Лиан → отцу (второе)", "cat": CAT_LETTERS, "flag": "monk_letter_2_read", "is_letter": true},
	"youth_mother_letter_1": {"title": "✉ Мама → сыну (первое)", "cat": CAT_YOUTH_MAIL, "flag": "youth_letter_1_done", "is_letter": true, "order": 1},
	"youth_reply_1": {"title": "✉ Сын → маме (первый ответ)", "cat": CAT_YOUTH_MAIL, "flag": "youth_letter_1_done", "is_letter": true, "order": 2},
	"youth_mother_letter_2": {"title": "✉ Мама → сыну (второе)", "cat": CAT_YOUTH_MAIL, "flag": "youth_letter_2_done", "is_letter": true, "order": 3},
	"youth_reply_2": {"title": "✉ Сын → маме (второй ответ)", "cat": CAT_YOUTH_MAIL, "flag": "youth_letter_2_done", "is_letter": true, "order": 4},
	"youth_mother_letter_wave_3": {"title": "✉ Мама → сыну (после второго стража)", "cat": CAT_YOUTH_MAIL, "flag": "youth_letter_3_done", "is_letter": true, "order": 5},
	"youth_reply_wave_3": {"title": "✉ Сын → маме (ответ)", "cat": CAT_YOUTH_MAIL, "flag": "youth_letter_3_done", "is_letter": true, "order": 6},
	"youth_mother_letter_wave_4": {"title": "✉ Мама → сыну (после третьего стража)", "cat": CAT_YOUTH_MAIL, "flag": "youth_letter_4_done", "is_letter": true, "order": 7},
	"youth_reply_wave_4": {"title": "✉ Сын → маме (ответ)", "cat": CAT_YOUTH_MAIL, "flag": "youth_letter_4_done", "is_letter": true, "order": 8},
	"youth_mother_letter_wave_5": {"title": "✉ Мама → сыну (после четвёртого стража)", "cat": CAT_YOUTH_MAIL, "flag": "youth_letter_5_done", "is_letter": true, "order": 9},
	"youth_reply_wave_5": {"title": "✉ Сын → маме (ответ)", "cat": CAT_YOUTH_MAIL, "flag": "youth_letter_5_done", "is_letter": true, "order": 10},
	"youth_mother_letter_wave_6": {"title": "✉ Мама → сыну (второй караван после четвёртого стража)", "cat": CAT_YOUTH_MAIL, "flag": "youth_letter_6_done", "is_letter": true, "order": 11},
	"youth_reply_wave_6": {"title": "✉ Сын → маме (ответ)", "cat": CAT_YOUTH_MAIL, "flag": "youth_letter_6_done", "is_letter": true, "order": 12},
	"youth_last_letter": {"title": "✉ Последнее письмо Мирона (прощальное)", "cat": CAT_YOUTH_MAIL, "flag": "worker_youth_death_scene_done", "is_letter": true, "order": 13},
	"youth_mother_letter_3": {"title": "✉ Мама → сыну (третье, без ответа)", "cat": CAT_YOUTH_MAIL, "flag": "youth_postmortem_1_done", "flag_also": "youth_letter_2_done", "is_letter": true, "order": 14},
	"youth_mother_letter_postmortem_2": {"title": "✉ Мама → сыну (без ответа)", "cat": CAT_YOUTH_MAIL, "flag": "youth_postmortem_2_done", "flag_also": "youth_letter_1_done", "flag_not": "youth_letter_2_done", "is_letter": true, "order": 15},
	"youth_nika_drawing_postmortem": {"title": "✉ Рисунок Ники (одиннадцатый кораблик)", "cat": CAT_YOUTH_MAIL, "flag": "youth_postmortem_2_done", "is_letter": true, "order": 16},
}

## {id, title, category, text_bbcode} — только разблокированные записи.
static func get_unlocked_entries() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var chest_ids: PackedStringArray = ChestLoreLibrary.get_all_note_ids()
	for nid in chest_ids:
		if not SaveManager.has_lore_note(nid):
			continue
		out.append({
			"id": nid,
			"title": ChestLoreLibrary.get_note_display_title(nid),
			"category": ChestLoreLibrary.get_note_category(nid),
			"text_bbcode": str(ChestLoreLibrary.get_note_text(nid)),
		})
	for key in _LORE_ZONE_META:
		var meta: Dictionary = _LORE_ZONE_META[key]
		var flag: String = str(meta.get("flag", ""))
		if flag.is_empty() or not StoryState.has_flag(flag):
			continue
		var flag_also: String = str(meta.get("flag_also", ""))
		if not flag_also.is_empty() and not StoryState.has_flag(flag_also):
			continue
		var flag_not: String = str(meta.get("flag_not", ""))
		if not flag_not.is_empty() and StoryState.has_flag(flag_not):
			continue
		var entry: Dictionary = {
			"id": key,
			"title": str(meta.get("title", key)),
			"category": str(meta.get("cat", CAT_HEALER)),
			"text_bbcode": _format_lore_zone_text(key),
		}
		if meta.has("is_letter"):
			entry["is_letter"] = true
		if meta.has("order"):
			entry["order"] = int(meta["order"])
		out.append(entry)
	return out


## Записи, сгруппированные по категориям в порядке CATEGORY_ORDER.
static func get_entries_grouped() -> Array[Dictionary]:
	var entries := get_unlocked_entries()
	var by_cat: Dictionary = {}
	for e in entries:
		var cat: String = str(e.get("category", ""))
		if not by_cat.has(cat):
			by_cat[cat] = []
		(by_cat[cat] as Array).append(e)
	for cat in by_cat:
		var arr: Array = by_cat[cat] as Array
		arr.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
			return int(a.get("order", 999)) < int(b.get("order", 999)))
	var out: Array[Dictionary] = []
	for cat in CATEGORY_ORDER:
		if not by_cat.has(cat):
			continue
		out.append({
			"category": cat,
			"hint": str(_CATEGORY_HINTS.get(cat, "")),
			"entries": by_cat[cat] as Array,
		})
	for cat in by_cat:
		var already := false
		for c in CATEGORY_ORDER:
			if c == cat:
				already = true
				break
		if not already:
			out.append({
				"category": cat,
				"hint": str(_CATEGORY_HINTS.get(cat, "")),
				"entries": by_cat[cat] as Array,
			})
	return out

static func get_category_hint(cat: String) -> String:
	return str(_CATEGORY_HINTS.get(cat, ""))


static func get_total_for_category(cat: String) -> int:
	var total := 0
	for nid in ChestLoreLibrary.get_all_note_ids():
		if ChestLoreLibrary.get_note_category(nid) == cat:
			total += 1
	for key in _LORE_ZONE_META:
		var meta: Dictionary = _LORE_ZONE_META[key]
		if str(meta.get("cat", "")) == cat:
			total += 1
	return total


static func has_any_unlocked() -> bool:
	var chest_ids: PackedStringArray = ChestLoreLibrary.get_all_note_ids()
	for nid in chest_ids:
		if SaveManager.has_lore_note(nid):
			return true
	for key in _LORE_ZONE_META:
		var meta: Dictionary = _LORE_ZONE_META[key]
		var flag: String = str(meta.get("flag", ""))
		if not flag.is_empty() and StoryState.has_flag(flag):
			return true
	return false


static func _format_lore_zone_text(key: String) -> String:
	if not LoreZoneDialogue.LORE_TABLE.has(key):
		return ""
	var rows: Array = LoreZoneDialogue.LORE_TABLE[key]
	var parts: PackedStringArray = []
	for row in rows:
		if row is Array and row.size() >= 2:
			var speaker: String = str(row[0])
			var text: String = str(row[1])
			var name: String = str(_SPEAKER_NAMES.get(speaker, speaker))
			if speaker == "letter" or name.is_empty():
				parts.append("[i][color=#d4c8a0]%s[/color][/i]" % text)
			else:
				parts.append("[color=#8899aa]%s:[/color] %s" % [name, text])
	return "\n\n".join(parts)
