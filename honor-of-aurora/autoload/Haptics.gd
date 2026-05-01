extends Node
## Тактильная отдача (вибрация телефона). Управляется флагом SaveManager.haptic_enabled.
## На Android Input.vibrate_handheld даёт нативные вылеты на части устройств (см. worrier_base.gd
## комментарий на _take_damage), поэтому пока поддерживается только iOS. На остальных платформах
## функции — no-op.
##
## API:
##   Haptics.pulse_light()  — короткая (≈18 мс) подсказка: попадание, поднятие монеты.
##   Haptics.pulse_medium() — средняя (≈32 мс): блок щитом, удар по врагу.
##   Haptics.pulse_strong() — сильная (≈60 мс): получение урона, разбитие брони.

const _PULSE_LIGHT_MS := 18
const _PULSE_MEDIUM_MS := 32
const _PULSE_STRONG_MS := 60


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _is_supported() -> bool:
	if SaveManager == null or not SaveManager.haptic_enabled:
		return false
	return OS.get_name() == "iOS"


func pulse_light() -> void:
	if not _is_supported():
		return
	Input.vibrate_handheld(_PULSE_LIGHT_MS)


func pulse_medium() -> void:
	if not _is_supported():
		return
	Input.vibrate_handheld(_PULSE_MEDIUM_MS)


func pulse_strong() -> void:
	if not _is_supported():
		return
	Input.vibrate_handheld(_PULSE_STRONG_MS)
