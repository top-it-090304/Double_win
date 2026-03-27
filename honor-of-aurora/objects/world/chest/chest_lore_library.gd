class_name ChestLoreLibrary
extends Object
## Тексты записок по id. Добавляйте ключи и сюда, и в кандидаты на сундуке (lore_note_candidates).

const _TEXTS: Dictionary = {
	"chest_note_aurora_rumor":
	"«Северное сиянье видели и на старых картах. Кто нёс честь — тому дорога короче.»\n\nПодпись стёрта.",
	"chest_note_ore_mine":
	"«Руда из недр — не украшение. Храни запас: без неё кузнец и капитан молчат одинаково.»",
	"chest_note_meat_supply":
	"«Провиант для стрелков — закон. Пустой котёл хуже пустого колчана.»",
}


static func get_note_text(note_id: String) -> String:
	if note_id.is_empty() or not _TEXTS.has(note_id):
		return ""
	return str(_TEXTS[note_id])


static func get_all_note_ids() -> PackedStringArray:
	var out := PackedStringArray()
	for k in _TEXTS.keys():
		out.append(String(k))
	return out
