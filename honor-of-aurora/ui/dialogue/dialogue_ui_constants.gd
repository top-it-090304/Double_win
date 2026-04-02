## Общие константы визуала диалога (см. dialogue_window.gd — те же размеры и цвета текста).
extends RefCounted
class_name DialogueUiConstants

const NAME_FONT_SIZE := 14
const TEXT_FONT_SIZE := 22
const NAME_FONT_COLOR := Color(1, 1, 1, 1)
const TEXT_FONT_COLOR := Color(1, 1, 1, 1)
const MARGIN_LEFT := 16
const MARGIN_TOP := 12
const MARGIN_RIGHT := 16
const MARGIN_BOTTOM := 12
const VBOX_SEP := 6


static func _scale_percent() -> int:
	if SaveManager == null:
		return 100
	return clampi(SaveManager.dialogue_text_scale_percent, 75, 130)


## Кегль имени говорящего с учётом настройки «Крупность текста в диалогах».
static func get_name_font_size() -> int:
	return maxi(8, int(round(float(NAME_FONT_SIZE) * float(_scale_percent()) / 100.0)))


## Кегль текста реплики.
static func get_text_font_size() -> int:
	return maxi(8, int(round(float(TEXT_FONT_SIZE) * float(_scale_percent()) / 100.0)))


## Варианты ответа: чуть меньше основного текста, но не ниже 12.
static func get_choice_button_font_size() -> int:
	return maxi(12, get_text_font_size() - 2)
