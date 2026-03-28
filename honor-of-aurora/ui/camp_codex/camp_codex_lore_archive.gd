extends RefCounted
class_name CampCodexLoreArchive
## Единая точка данных для вкладки «Архив» кодекса.
## Объединяет записки из сундуков, записи целителя (лор-зоны) и письма Лиан.

const CAT_CROWN := "Корона и политика"
const CAT_ORDER := "Орден и Заря"
const CAT_EXPEDITION := "Первая экспедиция"
const CAT_CAMP := "Быт лагеря"
const CAT_HEALER := "Записи целителя"
const CAT_LETTERS := "Письма"
const CAT_YOUTH_MAIL := "Переписка юноши"

const CATEGORY_ORDER: PackedStringArray = [
	CAT_CROWN, CAT_ORDER, CAT_EXPEDITION, CAT_HEALER, CAT_LETTERS, CAT_YOUTH_MAIL, CAT_CAMP,
]

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
	"monk_story_1": {"title": "У огня: орден и контракт", "cat": CAT_HEALER, "flag": "monk_story_1_done"},
	"monk_story_3": {"title": "У огня: три стража и цепь", "cat": CAT_HEALER, "flag": "monk_story_3_done"},
	"monk_letter_1": {"title": "Письмо Лиан (первое)", "cat": CAT_LETTERS, "flag": "monk_letter_1_read"},
	"monk_letter_2": {"title": "Письмо Лиан (второе)", "cat": CAT_LETTERS, "flag": "monk_letter_2_read"},
	"youth_mother_letter_1": {"title": "Письмо мамы (первое)", "cat": CAT_YOUTH_MAIL, "flag": "youth_letter_1_done"},
	"youth_reply_1": {"title": "Ответ юноши (первый)", "cat": CAT_YOUTH_MAIL, "flag": "youth_letter_1_done"},
	"youth_mother_letter_2": {"title": "Письмо мамы (второе)", "cat": CAT_YOUTH_MAIL, "flag": "youth_letter_2_done"},
	"youth_reply_2": {"title": "Ответ юноши (второй)", "cat": CAT_YOUTH_MAIL, "flag": "youth_letter_2_done"},
	"youth_last_letter": {"title": "Последнее письмо юноши", "cat": CAT_YOUTH_MAIL, "flag": "worker_youth_death_scene_done"},
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
		out.append({
			"id": key,
			"title": str(meta.get("title", key)),
			"category": str(meta.get("cat", CAT_HEALER)),
			"text_bbcode": _format_lore_zone_text(key),
		})
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
	var out: Array[Dictionary] = []
	for cat in CATEGORY_ORDER:
		if not by_cat.has(cat):
			continue
		out.append({"category": cat, "entries": by_cat[cat] as Array})
	for cat in by_cat:
		var already := false
		for c in CATEGORY_ORDER:
			if c == cat:
				already = true
				break
		if not already:
			out.append({"category": cat, "entries": by_cat[cat] as Array})
	return out


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
