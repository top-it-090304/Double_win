extends Node
## Адаптивные и контекстные подсказки для новичка. Активны на «Лёгком» (DifficultyConfig.is_easy()).
## Память — на сессию (не сохраняется), чтобы подсказки не «протухали» в save.
##
## Функционал:
##   1) Адаптивная подсказка после повторных смертей на одной локации (порог DEATH_STREAK_FOR_HINT).
##   2) Хук для контекстных подсказок (см. notify_red_enemy_seen, notify_low_hp, notify_armor_critical).
##
## Все подсказки идут через HintToast (не блокируют ввод).

const DEATH_STREAK_FOR_HINT := 2
## Окно сессии в секундах: смерти за пределами окна — серия сбрасывается, чтобы подсказка не вылезла спустя час.
const DEATH_STREAK_WINDOW_SEC := 1800.0

const TIP_DURATION_SEC := 8.0
const TIP_DURATION_SHORT_SEC := 5.0

## Серия смертей: { location_int: { count: int, last_death_msec: int } }.
var _death_streak: Dictionary = {}
## Локации, для которых уже показали адаптивную подсказку (per-session, не повторяем).
var _adaptive_hint_shown: Dictionary = {}
## Запрос показать подсказку при ближайшем входе в локацию (id -> текст).
var _pending_location_tip: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if Events and Events.has_signal("location_changed"):
		if not Events.location_changed.is_connected(_on_location_changed):
			Events.location_changed.connect(_on_location_changed)


func _is_easy_active() -> bool:
	return DifficultyConfig != null and DifficultyConfig.is_easy()


## Сообщить о смерти героя на текущей adventure-локации. Вызывается из worrier_base.die().
func notify_player_death(loc: int) -> void:
	if not _is_easy_active():
		return
	if not Events.is_adventure_location(loc as Events.LOCATION):
		return
	var now_msec := float(Time.get_ticks_msec())
	var entry: Dictionary = _death_streak.get(loc, {"count": 0, "last_death_msec": 0.0})
	var last := float(entry.get("last_death_msec", 0.0))
	if last > 0.0 and (now_msec - last) > DEATH_STREAK_WINDOW_SEC * 1000.0:
		entry["count"] = 0
	entry["count"] = int(entry.get("count", 0)) + 1
	entry["last_death_msec"] = now_msec
	_death_streak[loc] = entry
	if int(entry["count"]) >= DEATH_STREAK_FOR_HINT and not _adaptive_hint_shown.has(loc):
		_pending_location_tip[loc] = _build_adaptive_hint_text()


func _on_location_changed(loc: Events.LOCATION) -> void:
	if not _is_easy_active():
		return
	if not Events.is_adventure_location(loc):
		return
	## Первый заход на адвенчуру — короткое напоминание про управление.
	notify_first_island_arrival()
	var key: int = int(loc)
	if _pending_location_tip.has(key) and not _adaptive_hint_shown.has(key):
		var text := str(_pending_location_tip[key])
		_pending_location_tip.erase(key)
		_adaptive_hint_shown[key] = true
		_show_after_delay(text, TIP_DURATION_SEC, 1.2)


func _show_after_delay(text: String, duration_sec: float, delay_sec: float) -> void:
	## Подсказку показываем чуть после загрузки сцены, чтобы не накладываться на интро-диалог.
	## get_tree() может быть null во время смены сцены (Wayland/Aurora) — деградируем мирно.
	var st := get_tree()
	if st == null:
		if HintToast != null:
			HintToast.show_tip(text, duration_sec)
		return
	var t := st.create_timer(delay_sec, true, false, true)
	t.timeout.connect(func() -> void:
		if HintToast != null:
			HintToast.show_tip(text, duration_sec)
	)


func _build_adaptive_hint_text() -> String:
	## Подсказка — короткая, конкретная, дружелюбная. Несколько вариантов на случай повторов.
	var lines: Array[String] = [
		"Не сдавайся: попробуй щит (правая кнопка) перед ударом — урон режется. На «Лёгком» броня держится дольше, не бойся блокировать.",
		"Подсказка: на «Лёгком» можно отдыхать у костра до 6 раз за поход. Если HP ниже половины — иди отдыхать, не геройствуй.",
		"Совет: красные враги выше тебя по уровню. Возвращайся на базу, прокачайся в монастыре или возьми ещё лучников — и приходи снова.",
	]
	var idx := int(_adaptive_hint_shown.size()) % lines.size()
	return lines[idx]


## --- Контекстные подсказки онбординга. Каждая показывается один раз за сессию. ---

func notify_red_enemy_seen() -> void:
	if not _is_easy_active() or HintToast == null:
		return
	HintToast.show_tip_once(
		"red_enemy",
		"Красный враг выше тебя по уровню — бьёт сильнее. Подними уровень в монастыре или приходи с лучниками.",
		TIP_DURATION_SEC
	)


func notify_low_hp() -> void:
	if not _is_easy_active() or HintToast == null:
		return
	HintToast.show_tip_once(
		"low_hp",
		"HP ниже трети. Используй привал у костра (значок отдыха внизу), пока не поздно.",
		TIP_DURATION_SHORT_SEC
	)


func notify_armor_critical() -> void:
	if HintToast == null:
		return
	HintToast.show_tip_once(
		"armor_critical",
		"Броня почти разбита (красная иконка). На базе в Оружейной её можно починить.",
		TIP_DURATION_SHORT_SEC
	)


func notify_first_island_arrival() -> void:
	if not _is_easy_active() or HintToast == null:
		return
	HintToast.show_tip_once(
		"first_island",
		"Управление: джойстик слева — ходить, правая кнопка — щит, нижняя — удар. Долгое касание союзника откроет приказы.",
		TIP_DURATION_SEC + 2.0
	)


func reset_session_state() -> void:
	_death_streak.clear()
	_adaptive_hint_shown.clear()
	_pending_location_tip.clear()
	if HintToast != null and HintToast.has_method("reset_shown_keys"):
		HintToast.reset_shown_keys()
