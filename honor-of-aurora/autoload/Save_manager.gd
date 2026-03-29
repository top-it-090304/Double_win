extends Node

## Старт совпадает с default_data (новая игра / первый запуск без файла сохранения).
var gold: int = 10
## «Запас мяса» — лимит лучников+копейщиков (и отображение в HUD).
var meat_count: int = 0
## Дерево: улучшение зданий.
var wood_count: int = 0
## Руда с шахты на базе (пока учёт без расхода в геймплее).
var ore_count: int = 0
var boss_kill: int = 0
var current_health = 100
var current_level: int = 1
var current_exp = 0
var archer_count: int = 0
var lancer_count: int = 0
var pawn_count: int = 0
## Сколько раз герой умер (остров / бой).
var death_count: int = 0
## Сколько раз вернулся на базу с острова (поход завершён телепортом).
var expedition_return_count: int = 0
## Сохраняется: игрок зашёл в главное меню с острова — при «Продолжить» на базе нужен жетон диалога монаха.
var was_on_adventure_before_menu: bool = false
## Последняя игровая сцена (Events.LOCATION, не MENU) и позиция героя для «Продолжить».
var resume_game_location: int = 0
var resume_player_position_x: float = -600.0
var resume_player_position_y: float = 750.0
## Сессия: при «Продолжить» из главного меню один раз ставить героя по сохранённым координатам.
var apply_resume_position_on_next_scene: bool = false
## Следующий переход в меню — после смерти: не перезаписывать resume из позиции игрока.
var death_resume_pending: bool = false
## 1 HP после смерти (телепорт на базу); иначе при загрузке можно поднять HP до max.
var resume_from_death: bool = false

## Координаты зоны телепорта на базе (см. TeleportZone в Game_base_islad.tscn).
const BASE_TELEPORT_RESUME_X := -660.0
const BASE_TELEPORT_RESUME_Y := 865.0
## Сюжетные флаги для диалогов и квестов (строковый ключ → bool).
var story_flags: Dictionary = {}
## Зачищенные зоны островов: ключ IslandProgress.zone_save_key(island, zone_id) → true.
var island_zone_state: Dictionary = {}
## Открытые сундуки: уникальный chest_save_id → true (однократный лут).
var opened_chest_ids: Dictionary = {}
## Зафиксированный при первом появлении ярус лута (chest_save_id → int 0..5), чтобы рогалик-ролл не менялся до открытия.
var chest_rolled_tiers: Dictionary = {}
## Уровни зданий на базе: ключ building_type → 0..4 (BuildingColor: 0 = первая текстура / «уровень 1» … 4 = макс.).
const DEFAULT_BUILDING_LEVELS := {
	"Monastery": 0,
	"Castle": 0,
	"Barracks": 0,
	"Archery": 0,
	"Mine": 0,
}
var building_levels: Dictionary = DEFAULT_BUILDING_LEVELS.duplicate()
## Громкости шин (0.0–1.0), см. SoundManager.apply_user_volume_settings().
var volume_music: float = 1.0
var volume_sfx: float = 1.0
var volume_ui: float = 1.0
var volume_dialogue: float = 1.0
## Сложность: 0 = лёгкий, 1 = нормальный, 2 = сложный (см. DifficultyConfig.Id).
var difficulty_id: int = 1
## Масштаб интерфейса окна (75–130, 100 = по умолчанию). См. Window.content_scale_factor.
var ui_scale_percent: int = 100
## Ограничение FPS (0 = без ограничения, иначе 30–240).
var max_fps: int = 60
## 0 мин., 1 сред., 2 макс., 3 свой (только лимит FPS из max_fps). См. PerformancePreset.
var performance_mode: int = 1
## Сенсорное управление: 0 = авто, 1 = всегда показывать, 2 = скрыть (ПК/геймпад).
var touch_mode: int = 0
## Размер виртуального джойстика и кнопок, % (70–150).
var touch_scale_percent: int = 100
## Прозрачность сенсорного HUD, % (25–100).
var touch_opacity_percent: int = 52
## Вибрация при уроне (Android / iOS).
var haptic_enabled: bool = true
## Бонус к макс. HP героя поверх значения тира (сохраняется).
var hero_max_health_bonus: int = 0
## Бонус к скорости героя поверх значения тира (сохраняется).
var hero_speed_bonus: float = 0.0
## Premium-экономика: купленная руда за реальные деньги/SDK.
var premium_ore_purchased_total: int = 0
var premium_ore_purchase_count: int = 0

## ─── Система Короны: караваны, приказы, титулы, немилость ───
## Руда, отправленная Короне за всю игру.
var ore_sent_to_crown_total: int = 0
## Индекс текущего приказа (0 = нет активного, 1–5 = по сюжету).
var crown_order_index: int = 0
## Руда, уже отправленная по текущему приказу.
var crown_order_ore_sent: int = 0
## Экспедиций осталось до дедлайна текущего приказа (0 = просрочен / нет приказа).
var crown_order_deadline_remaining: int = 0
## Количество просроченных приказов подряд (для расчёта немилости).
var crown_orders_failed: int = 0
## Уровень немилости Короны (0–3).
var crown_displeasure: int = 0
## Индекс текущего титула (0–5).
var crown_title_index: int = 0
## Экспедиций до следующего каравана.
var expeditions_until_caravan: int = 3
## Караван ожидает на базе (игрок ещё не загрузил).
var caravan_pending: bool = false
## Сколько раз отправлял караван.
var caravan_sent_count: int = 0
## Одобрение Короны (0–3): бонусы за стабильное выполнение приказов.
var crown_favor: int = 0
## Износ снаряжения (0–100): снижается с каждым походом, чинится в казармах.
var armor_durability: int = 100
## Привалы, использованные в текущем походе.
var rest_used_this_expedition: int = 0
## Ресурсы, собранные в текущем походе (для cap-а).
var expedition_ore_collected: int = 0
var expedition_wood_collected: int = 0
var expedition_meat_collected: int = 0

## Кэш тяжёлого build_codex_seen_state на один кадр (см. invalidate_codex_state_build_cache).
var _codex_state_cache_frame: int = -1000000
var _codex_state_cache_tree_id: int = 0
var _codex_state_cache_data: Dictionary = {}


const _CODEX_SNAP_KEY := "_codex_snap_v1"
const _CODEX_SNAP_MIGRATED_KEY := "_codex_snap_v1_migrated"
const _CODEX_UI_KEY := "_codex_ui"

const GAME_SAVE_FILE := "user://game_save_file.save"
const SAVE_DATA = ["gold", "meat_count", "wood_count", "ore_count", "boss_kill", "current_health", "current_level", "current_exp", "archer_count", "lancer_count", "pawn_count", "death_count", "expedition_return_count", "was_on_adventure_before_menu", "resume_game_location", "resume_player_position_x", "resume_player_position_y", "resume_from_death", "story_flags", "island_zone_state", "opened_chest_ids", "chest_rolled_tiers", "building_levels", "volume_music", "volume_sfx", "volume_ui", "volume_dialogue", "difficulty_id", "ui_scale_percent", "max_fps", "performance_mode", "touch_mode", "touch_scale_percent", "touch_opacity_percent", "haptic_enabled", "hero_max_health_bonus", "hero_speed_bonus", "premium_ore_purchased_total", "premium_ore_purchase_count", "ore_sent_to_crown_total", "crown_order_index", "crown_order_ore_sent", "crown_order_deadline_remaining", "crown_orders_failed", "crown_displeasure", "crown_title_index", "expeditions_until_caravan", "caravan_pending", "caravan_sent_count", "crown_favor", "armor_durability"]
const default_data := {
	"gold" : 10,
	"meat_count" : 0,
	"wood_count" : 0,
	"ore_count" : 0,
	"boss_kill" : 0,
	"current_health" : 100,
	"current_level" : 1,
	"current_exp" : 0,
	"archer_count" : 0,
	"lancer_count" : 0,
	"pawn_count" : 0,
	"death_count" : 0,
	"expedition_return_count" : 0,
	"was_on_adventure_before_menu" : false,
	"resume_game_location" : 0,
	"resume_player_position_x" : -600.0,
	"resume_player_position_y" : 750.0,
	"resume_from_death" : false,
	"story_flags" : {},
	"island_zone_state" : {},
	"opened_chest_ids" : {},
	"chest_rolled_tiers" : {},
	"building_levels" : {
		"Monastery": 0,
		"Castle": 0,
		"Barracks": 0,
		"Archery": 0,
	},
	"volume_music" : 1.0,
	"volume_sfx" : 1.0,
	"volume_ui" : 1.0,
	"volume_dialogue" : 1.0,
	"difficulty_id" : 1,
	"ui_scale_percent" : 100,
	"max_fps" : 60,
	"performance_mode" : 1,
	"touch_mode" : 0,
	"touch_scale_percent" : 100,
	"touch_opacity_percent" : 52,
	"haptic_enabled" : true,
	"hero_max_health_bonus" : 0,
	"hero_speed_bonus" : 0.0,
	"premium_ore_purchased_total" : 0,
	"premium_ore_purchase_count" : 0,
	"ore_sent_to_crown_total" : 0,
	"crown_order_index" : 0,
	"crown_order_ore_sent" : 0,
	"crown_order_deadline_remaining" : 0,
	"crown_orders_failed" : 0,
	"crown_displeasure" : 0,
	"crown_title_index" : 0,
	"expeditions_until_caravan" : 3,
	"caravan_pending" : false,
	"caravan_sent_count" : 0,
	"crown_favor" : 0,
	"armor_durability" : 100,
}


func load_game():
	if not FileAccess.file_exists(GAME_SAVE_FILE):
		current_health = HeroProgression.get_tier_for_level(current_level).max_health
		building_levels = DEFAULT_BUILDING_LEVELS.duplicate()
		_normalize_settings_fields()
		apply_window_and_engine_settings()
		invalidate_codex_state_build_cache()
		call_deferred("apply_window_and_engine_settings")
		return
		
	var game_save_file = FileAccess.open(GAME_SAVE_FILE, FileAccess.READ)
	if game_save_file == null:
		printerr("Save faild with code {0}".format([FileAccess.get_open_error()]))
		return
		
	var json_object := JSON.new()
	var error = json_object.parse(game_save_file.get_line())
	if error != OK:
		return
		
	var game_data = json_object.get_data()
	for variable in SAVE_DATA:
		if variable in game_data:
			var v: Variant = game_data[variable]
			if variable == "story_flags" and v is Dictionary:
				story_flags = (v as Dictionary).duplicate()
			elif variable == "island_zone_state" and v is Dictionary:
				island_zone_state = (v as Dictionary).duplicate()
			elif variable == "opened_chest_ids" and v is Dictionary:
				opened_chest_ids = (v as Dictionary).duplicate()
			elif variable == "chest_rolled_tiers" and v is Dictionary:
				chest_rolled_tiers = (v as Dictionary).duplicate()
			elif variable == "building_levels" and v is Dictionary:
				building_levels = (v as Dictionary).duplicate()
			elif variable.begins_with("volume_") and typeof(v) in [TYPE_FLOAT, TYPE_INT]:
				set(variable, clampf(float(v), 0.0, 1.0))
			elif variable == "ui_scale_percent" and typeof(v) in [TYPE_FLOAT, TYPE_INT]:
				ui_scale_percent = clampi(int(v), 75, 130)
			elif variable == "max_fps" and typeof(v) in [TYPE_FLOAT, TYPE_INT]:
				max_fps = clampi(int(v), 0, 240)
			elif variable == "performance_mode" and typeof(v) in [TYPE_FLOAT, TYPE_INT]:
				performance_mode = PerformancePreset.clamp_mode(int(v))
			elif variable == "touch_mode" and typeof(v) in [TYPE_FLOAT, TYPE_INT]:
				touch_mode = clampi(int(v), 0, 2)
			elif variable == "touch_scale_percent" and typeof(v) in [TYPE_FLOAT, TYPE_INT]:
				touch_scale_percent = clampi(int(v), 70, 150)
			elif variable == "touch_opacity_percent" and typeof(v) in [TYPE_FLOAT, TYPE_INT]:
				touch_opacity_percent = clampi(int(v), 25, 100)
			elif variable == "haptic_enabled":
				haptic_enabled = bool(v)
			else:
				set(variable, v)
		elif variable == "island_zone_state":
			island_zone_state = {}
		elif variable == "opened_chest_ids":
			opened_chest_ids = {}
		elif variable == "chest_rolled_tiers":
			chest_rolled_tiers = {}
		elif variable == "building_levels":
			building_levels = DEFAULT_BUILDING_LEVELS.duplicate()

	building_levels = _normalize_building_levels(building_levels)

	_migrate_story_island_flags_from_legacy_boss_kill()
	_migrate_truth_choice_flags()
	_migrate_worker_youth_refused_to_base_worker()
	_migrate_worker_youth_prompt_anchor()
	if not game_data.has("difficulty_id"):
		difficulty_id = 1
	difficulty_id = clampi(int(difficulty_id), 0, 2)
	if not game_data.has("lancer_count"):
		lancer_count = 0
	if not game_data.has("pawn_count"):
		pawn_count = 0
	if not game_data.has("gold"):
		gold = int(default_data["gold"])
	if not game_data.has("meat_count"):
		meat_count = 0
	if not game_data.has("wood_count"):
		wood_count = 0
	if not game_data.has("ore_count"):
		ore_count = 0
	if not game_data.has("hero_max_health_bonus"):
		hero_max_health_bonus = 0
	if not game_data.has("hero_speed_bonus"):
		hero_speed_bonus = 0.0
	if not game_data.has("premium_ore_purchased_total"):
		premium_ore_purchased_total = 0
	if not game_data.has("premium_ore_purchase_count"):
		premium_ore_purchase_count = 0
	if not game_data.has("ore_sent_to_crown_total"):
		ore_sent_to_crown_total = 0
	if not game_data.has("crown_order_index"):
		crown_order_index = 0
	if not game_data.has("crown_order_ore_sent"):
		crown_order_ore_sent = 0
	if not game_data.has("crown_order_deadline_remaining"):
		crown_order_deadline_remaining = 0
	if not game_data.has("crown_orders_failed"):
		crown_orders_failed = 0
	if not game_data.has("crown_displeasure"):
		crown_displeasure = 0
	if not game_data.has("crown_title_index"):
		crown_title_index = 0
	if not game_data.has("expeditions_until_caravan"):
		expeditions_until_caravan = BalanceConfig.CARAVAN_EXPEDITION_INTERVAL
	if not game_data.has("caravan_pending"):
		caravan_pending = false
	if not game_data.has("caravan_sent_count"):
		caravan_sent_count = 0
	if not game_data.has("opened_chest_ids"):
		opened_chest_ids = {}
	if not game_data.has("chest_rolled_tiers"):
		chest_rolled_tiers = {}
	hero_max_health_bonus = maxi(0, int(hero_max_health_bonus))
	hero_speed_bonus = float(hero_speed_bonus)
	premium_ore_purchased_total = maxi(0, int(premium_ore_purchased_total))
	premium_ore_purchase_count = maxi(0, int(premium_ore_purchase_count))
	ore_sent_to_crown_total = maxi(0, int(ore_sent_to_crown_total))
	crown_order_index = clampi(int(crown_order_index), 0, 5)
	crown_order_ore_sent = maxi(0, int(crown_order_ore_sent))
	crown_order_deadline_remaining = maxi(0, int(crown_order_deadline_remaining))
	crown_orders_failed = maxi(0, int(crown_orders_failed))
	crown_displeasure = clampi(int(crown_displeasure), 0, BalanceConfig.DISPLEASURE_MAX_LEVEL)
	crown_title_index = clampi(int(crown_title_index), 0, BalanceConfig.CROWN_TITLES.size() - 1)
	expeditions_until_caravan = maxi(0, int(expeditions_until_caravan))
	caravan_sent_count = maxi(0, int(caravan_sent_count))
	if not game_data.has("crown_favor"):
		crown_favor = 0
	crown_favor = clampi(int(crown_favor), 0, BalanceConfig.CROWN_FAVOR_MAX_LEVEL)
	if not game_data.has("armor_durability"):
		armor_durability = 100
	armor_durability = clampi(int(armor_durability), 0, BalanceConfig.ARMOR_MAX_DURABILITY)
	var _warriors := archer_count + lancer_count
	if meat_count < _warriors:
		meat_count = _warriors
	if not game_data.has("resume_from_death"):
		resume_from_death = (
			current_health == 1
			and resume_game_location == int(Events.LOCATION.BASE)
			and abs(resume_player_position_x - BASE_TELEPORT_RESUME_X) < 2.0
			and abs(resume_player_position_y - BASE_TELEPORT_RESUME_Y) < 2.0
		)

	current_level = clampi(int(current_level), 1, BalanceConfig.MAX_HERO_LEVEL)
	if current_level >= BalanceConfig.MAX_HERO_LEVEL:
		current_exp = 0

	if not game_data.has("performance_mode"):
		performance_mode = PerformancePreset.Mode.CUSTOM

	_normalize_settings_fields()
	apply_window_and_engine_settings()
	invalidate_codex_state_build_cache()
	call_deferred("apply_window_and_engine_settings")


func _normalize_settings_fields() -> void:
	ui_scale_percent = clampi(int(ui_scale_percent), 75, 130)
	max_fps = clampi(int(max_fps), 0, 240)
	performance_mode = PerformancePreset.clamp_mode(int(performance_mode))
	touch_mode = clampi(int(touch_mode), 0, 2)
	touch_scale_percent = clampi(int(touch_scale_percent), 70, 150)
	touch_opacity_percent = clampi(int(touch_opacity_percent), 25, 100)
	difficulty_id = clampi(int(difficulty_id), 0, 2)


## Окно и движок после загрузки сохранения или смены настроек.
func apply_window_and_engine_settings() -> void:
	var w := get_window()
	if w:
		w.content_scale_factor = clampf(float(ui_scale_percent) / 100.0, 0.75, 1.5)
	PerformancePreset.apply_from_save_manager(self)
	var tree := get_tree()
	if tree:
		tree.call_group("wind_decor_sprite", "apply_wind_speed_from_settings")


## Старые сохранения без развилки: кто уже прошёл последний остров или финал монаха — считаем «добить цепь».
func _migrate_truth_choice_flags() -> void:
	if bool(story_flags.get("truth_and_choice_done", false)):
		return
	if bool(story_flags.get("story_island_5_cleared", false)):
		story_flags["truth_and_choice_done"] = true
		story_flags["hero_chose_finish_chain"] = true
		save_game()
		return
	if bool(story_flags.get("monk_story_6_done", false)):
		story_flags["truth_and_choice_done"] = true
		story_flags["hero_chose_finish_chain"] = true
		save_game()


## Старый отказ «не место в походе» блокировал всё; теперь юноша — рабочий на базе.
func _migrate_worker_youth_refused_to_base_worker() -> void:
	if not bool(story_flags.get("worker_youth_refused", false)):
		return
	story_flags.erase("worker_youth_refused")
	story_flags["worker_youth_works_on_base"] = true
	save_game()


## Интро уже пройдено, но якоря для периодических просьб не было — выставляем текущий счётчик походов.
func _migrate_worker_youth_prompt_anchor() -> void:
	if not bool(story_flags.get("worker_youth_intro_done", false)):
		return
	if story_flags.has("worker_youth_last_prompt_expedition_return"):
		return
	story_flags["worker_youth_last_prompt_expedition_return"] = expedition_return_count
	save_game()


func _migrate_story_island_flags_from_legacy_boss_kill() -> void:
	if bool(story_flags.get("_story_islands_migrated", false)):
		return
	var has_any := false
	for i in range(1, 6):
		if bool(story_flags.get("story_island_%d_cleared" % i, false)):
			has_any = true
			break
	if has_any:
		story_flags["_story_islands_migrated"] = true
		save_game()
		return
	if boss_kill <= 0:
		story_flags["_story_islands_migrated"] = true
		save_game()
		return
	for j in range(1, mini(boss_kill + 1, 6)):
		story_flags["story_island_%d_cleared" % j] = true
	story_flags["_story_islands_migrated"] = true
	save_game()


func notify_squad_member_died(unit: Node) -> void:
	if unit == null:
		return
	if bool(unit.get_meta("no_squad_death", false)):
		return
	if unit.is_in_group("story_youth_companion"):
		StoryState.set_flag("worker_youth_dead", true)
		return
	if unit.is_in_group("ally_archer"):
		archer_count = maxi(0, archer_count - 1)
	elif unit.is_in_group("ally_lancer"):
		lancer_count = maxi(0, lancer_count - 1)
	elif unit.is_in_group("ally_pawn"):
		pawn_count = maxi(0, pawn_count - 1)
	save_game()


var _save_game_deferred_pending: bool = false


func save_game():
	var game_save_file = FileAccess.open(GAME_SAVE_FILE, FileAccess.WRITE)
	if game_save_file == null:
		printerr("Save faild with code {0}".format([FileAccess.get_open_error()]))
		return
		
	var game_data := {}
	for variable in SAVE_DATA:
		game_data[variable] = get(variable)
	var json_object := JSON.new()
	game_save_file.store_line(json_object.stringify(game_data))


## Одна запись на диск в конце кадра (несколько сундуков с роллом яруса не вызывают save_game подряд).
func request_save_game_deferred() -> void:
	if _save_game_deferred_pending:
		return
	_save_game_deferred_pending = true
	call_deferred("_flush_deferred_save_game")


func _flush_deferred_save_game() -> void:
	_save_game_deferred_pending = false
	save_game()


func _normalize_building_levels(src: Dictionary) -> Dictionary:
	var out := DEFAULT_BUILDING_LEVELS.duplicate()
	if src.is_empty():
		return out
	for k in out.keys():
		if src.has(k):
			out[k] = clampi(int(src[k]), 0, 4)
	return out


func is_chest_opened(chest_id: String) -> bool:
	if chest_id.is_empty():
		return false
	return bool(opened_chest_ids.get(chest_id, false))


func mark_chest_opened(chest_id: String) -> void:
	if chest_id.is_empty():
		return
	opened_chest_ids[chest_id] = true


## Сундуки островов (id вида isl1_..., isl2_...) — сброс при возврате на базу с похода.
func reset_island_chest_progress_after_expedition() -> void:
	var re := RegEx.new()
	if re.compile("^isl\\d+_") != OK:
		return
	var rm_o: Array[String] = []
	for k in opened_chest_ids.keys():
		var ks := str(k)
		if re.search(ks):
			rm_o.append(ks)
	for ks in rm_o:
		opened_chest_ids.erase(ks)
	var rm_t: Array[String] = []
	for k in chest_rolled_tiers.keys():
		var ks := str(k)
		if re.search(ks):
			rm_t.append(ks)
	for ks in rm_t:
		chest_rolled_tiers.erase(ks)
	## Старые сохранения: один id на все инстансы на острове 1.
	for legacy in ["demo_base_chest_1"]:
		opened_chest_ids.erase(legacy)
		chest_rolled_tiers.erase(legacy)


func get_saved_chest_loot_tier(chest_id: String) -> int:
	if chest_id.is_empty() or not chest_rolled_tiers.has(chest_id):
		return -1
	return clampi(int(chest_rolled_tiers[chest_id]), 0, 5)


func save_chest_loot_tier_roll(chest_id: String, tier: int) -> void:
	if chest_id.is_empty():
		return
	chest_rolled_tiers[chest_id] = clampi(tier, 0, 5)


func has_lore_note(note_id: String) -> bool:
	if note_id.is_empty():
		return false
	return bool(story_flags.get("lore_note_%s" % note_id, false))


func mark_lore_note_found(note_id: String) -> void:
	if note_id.is_empty():
		return
	story_flags["lore_note_%s" % note_id] = true
	invalidate_codex_state_build_cache()


func get_codex_content_version() -> int:
	var n := 0
	for key in story_flags:
		var k: String = str(key)
		if k.begins_with("_"):
			continue
		if k.ends_with("_done") or k.ends_with("_read") or k.ends_with("_cleared") or k.ends_with("_found") or k.begins_with("lore_note_") or k == "worker_youth_dead" or k == "worker_youth_recruited" or k == "worker_youth_works_on_base":
			n += 1
	return n


func invalidate_codex_state_build_cache() -> void:
	_codex_state_cache_frame = -1000000
	_codex_state_cache_tree_id = 0
	_codex_state_cache_data.clear()


func _build_codex_seen_state_uncached(tree: SceneTree) -> Dictionary:
	var arch: Array = []
	for e in CampCodexLoreArchive.get_unlocked_entries():
		arch.append(str(e.get("id", "")))
	arch.sort()
	var items: Array = []
	for it in StoryItemLibrary.get_unlocked_items():
		items.append(str(it.get("id", "")))
	items.sort()
	var char_h := {}
	for ch in CampCodexDossier.get_character_entries():
		var k := str(ch.get("key", ""))
		char_h[k] = CampCodexDossierStories.get_story_bbcode(k).hash()
	return {
		"archive_ids": arch,
		"item_ids": items,
		"dossier_story": CampCodexDossier.story_bbcode().hash(),
		"dossier_personal": CampCodexDossier.personal_bbcode().hash(),
		"dossier_stats": CampCodexDossier.build_stats_bbcode(tree).hash(),
		"char_stories": char_h,
		"timeline": CampCodexDossier.build_timeline_bbcode().hash(),
	}


func build_codex_seen_state(tree: SceneTree) -> Dictionary:
	if tree == null:
		return {}
	var f := Engine.get_process_frames()
	var tid := tree.get_instance_id()
	if f == _codex_state_cache_frame and tid == _codex_state_cache_tree_id and not _codex_state_cache_data.is_empty():
		return _codex_state_cache_data
	_codex_state_cache_data = _build_codex_seen_state_uncached(tree)
	_codex_state_cache_frame = f
	_codex_state_cache_tree_id = tid
	return _codex_state_cache_data


func _codex_int_hash(v: Variant) -> int:
	if v == null:
		return 0
	if v is int:
		return v
	if v is float:
		return int(v)
	return int(v)


func _codex_string_array_from_variant(v: Variant) -> PackedStringArray:
	var out: PackedStringArray = []
	if v is Array:
		for x in v as Array:
			out.append(str(x))
	elif v is PackedStringArray:
		out = (v as PackedStringArray).duplicate()
	out.sort()
	return out


func _codex_char_map_from_variant(v: Variant) -> Dictionary:
	var out := {}
	if v is Dictionary:
		for k in v:
			out[str(k)] = _codex_int_hash(v[k])
	return out


func get_codex_seen_state_dict() -> Dictionary:
	var js := str(story_flags.get(_CODEX_SNAP_KEY, ""))
	if js.is_empty():
		return {}
	var parsed: Variant = JSON.parse_string(js)
	return parsed as Dictionary if parsed is Dictionary else {}


func _codex_snapshots_equal(cur: Dictionary, seen: Dictionary) -> bool:
	var ca := _codex_string_array_from_variant(cur.get("archive_ids", []))
	var sa := _codex_string_array_from_variant(seen.get("archive_ids", []))
	if ca != sa:
		return false
	var ci := _codex_string_array_from_variant(cur.get("item_ids", []))
	var si := _codex_string_array_from_variant(seen.get("item_ids", []))
	if ci != si:
		return false
	if _codex_int_hash(cur.get("dossier_story", 0)) != _codex_int_hash(seen.get("dossier_story", 0)):
		return false
	if _codex_int_hash(cur.get("dossier_personal", 0)) != _codex_int_hash(seen.get("dossier_personal", 0)):
		return false
	if _codex_int_hash(cur.get("dossier_stats", 0)) != _codex_int_hash(seen.get("dossier_stats", 0)):
		return false
	if _codex_int_hash(cur.get("timeline", 0)) != _codex_int_hash(seen.get("timeline", 0)):
		return false
	var cc := _codex_char_map_from_variant(cur.get("char_stories", {}))
	var sc := _codex_char_map_from_variant(seen.get("char_stories", {}))
	if cc.size() != sc.size():
		return false
	for k in cc:
		if not sc.has(k) or int(sc[k]) != int(cc[k]):
			return false
	return true


func _ensure_codex_snap_migrated(tree: SceneTree) -> void:
	if story_flags.get(_CODEX_SNAP_MIGRATED_KEY, false):
		return
	story_flags[_CODEX_SNAP_MIGRATED_KEY] = true
	if not str(story_flags.get(_CODEX_SNAP_KEY, "")).is_empty():
		return
	var last_seen: int = int(story_flags.get("_codex_seen_version", 0))
	var cur_ver := get_codex_content_version()
	if cur_ver <= last_seen:
		story_flags[_CODEX_SNAP_KEY] = JSON.stringify(build_codex_seen_state(tree))


func mark_codex_opened(tree: SceneTree = null) -> void:
	var t: SceneTree = tree if tree != null else get_tree()
	story_flags["_codex_seen_version"] = get_codex_content_version()
	if t != null:
		story_flags[_CODEX_SNAP_KEY] = JSON.stringify(build_codex_seen_state(t))
	save_game()


func _codex_summary_combined_hash_from_state(st: Dictionary) -> int:
	var a := _codex_int_hash(st.get("dossier_story", 0))
	var b := _codex_int_hash(st.get("dossier_personal", 0))
	var c := _codex_int_hash(st.get("dossier_stats", 0))
	var s := "%d|%d|%d" % [a, b, c]
	return int(s.hash())


func _codex_ui_ensure_subdicts(ui: Dictionary) -> void:
	if not ui.has("a") or not ui["a"] is Dictionary:
		ui["a"] = {}
	if not ui.has("c") or not ui["c"] is Dictionary:
		ui["c"] = {}
	if not ui.has("i") or not ui["i"] is Dictionary:
		ui["i"] = {}


func _ensure_codex_ui_clicked_initialized(tree: SceneTree) -> void:
	if story_flags.has(_CODEX_UI_KEY) and story_flags[_CODEX_UI_KEY] is Dictionary:
		_codex_ui_ensure_subdicts(story_flags[_CODEX_UI_KEY])
		return
	var st := build_codex_seen_state(tree)
	var ui := {"a": {}, "c": {}, "i": {}, "sum": 0, "tl": 0}
	for id in _codex_string_array_from_variant(st.get("archive_ids", [])):
		ui["a"][id] = true
	for id in _codex_string_array_from_variant(st.get("item_ids", [])):
		ui["i"][id] = true
	var ch_raw: Variant = st.get("char_stories", {})
	if ch_raw is Dictionary:
		for k in ch_raw:
			ui["c"][str(k)] = _codex_int_hash(ch_raw[k])
	ui["sum"] = _codex_summary_combined_hash_from_state(st)
	ui["tl"] = _codex_int_hash(st.get("timeline", 0))
	story_flags[_CODEX_UI_KEY] = ui


func codex_mark_archive_clicked(entry_id: String) -> void:
	if entry_id.is_empty():
		return
	var tree := get_tree()
	if tree == null:
		return
	_ensure_codex_ui_clicked_initialized(tree)
	var ui: Dictionary = story_flags[_CODEX_UI_KEY]
	_codex_ui_ensure_subdicts(ui)
	(ui["a"] as Dictionary)[entry_id] = true
	save_game()
	_notify_codex_hud_refresh()


func codex_mark_character_clicked(tree: SceneTree, char_key: String) -> void:
	if char_key.is_empty() or tree == null:
		return
	_ensure_codex_ui_clicked_initialized(tree)
	var h := CampCodexDossierStories.get_story_bbcode(char_key).hash()
	var ui: Dictionary = story_flags[_CODEX_UI_KEY]
	_codex_ui_ensure_subdicts(ui)
	(ui["c"] as Dictionary)[char_key] = h
	save_game()
	_notify_codex_hud_refresh()


func codex_mark_item_clicked(item_id: String) -> void:
	if item_id.is_empty():
		return
	var tree := get_tree()
	if tree == null:
		return
	_ensure_codex_ui_clicked_initialized(tree)
	var ui: Dictionary = story_flags[_CODEX_UI_KEY]
	_codex_ui_ensure_subdicts(ui)
	(ui["i"] as Dictionary)[item_id] = true
	save_game()
	_notify_codex_hud_refresh()


func codex_mark_summary_seen(tree: SceneTree) -> void:
	if tree == null:
		return
	_ensure_codex_ui_clicked_initialized(tree)
	var st := build_codex_seen_state(tree)
	var ui: Dictionary = story_flags[_CODEX_UI_KEY]
	ui["sum"] = _codex_summary_combined_hash_from_state(st)
	save_game()
	_notify_codex_hud_refresh()


func codex_mark_timeline_seen(tree: SceneTree) -> void:
	if tree == null:
		return
	_ensure_codex_ui_clicked_initialized(tree)
	var st := build_codex_seen_state(tree)
	var ui: Dictionary = story_flags[_CODEX_UI_KEY]
	ui["tl"] = _codex_int_hash(st.get("timeline", 0))
	save_game()
	_notify_codex_hud_refresh()


func _notify_codex_hud_refresh() -> void:
	var tree := get_tree()
	if tree == null:
		return
	for n in tree.get_nodes_in_group("hud"):
		if n.has_method("_update_codex_badge"):
			n.call("_update_codex_badge")


func _codex_marker_collection_nonempty(v: Variant) -> bool:
	if v is PackedStringArray:
		return not (v as PackedStringArray).is_empty()
	if v is Array:
		return not (v as Array).is_empty()
	return false


func _codex_info_has_pending(info: Dictionary) -> bool:
	var tabs_v: Variant = info.get("tabs", [])
	if tabs_v is Array:
		for t in tabs_v as Array:
			if t:
				return true
	if _codex_marker_collection_nonempty(info.get("new_archive_ids", null)):
		return true
	if _codex_marker_collection_nonempty(info.get("new_item_ids", null)):
		return true
	if _codex_marker_collection_nonempty(info.get("new_char_keys", null)):
		return true
	return false


func has_unseen_codex_content() -> bool:
	var tree := get_tree()
	if tree == null:
		return false
	_ensure_codex_snap_migrated(tree)
	_ensure_codex_ui_clicked_initialized(tree)
	var cur := build_codex_seen_state(tree)
	var info := compute_codex_new_marker_info_with_cur(tree, cur)
	if _codex_info_has_pending(info):
		return true
	## Совместимость: старые сохранения без снимка — счётчик флагов.
	var snap_s := str(story_flags.get(_CODEX_SNAP_KEY, ""))
	if snap_s.is_empty():
		var last_seen: int = int(story_flags.get("_codex_seen_version", 0))
		return get_codex_content_version() > last_seen
	var seen: Dictionary = get_codex_seen_state_dict()
	if seen.is_empty():
		var last_seen2: int = int(story_flags.get("_codex_seen_version", 0))
		return get_codex_content_version() > last_seen2
	return not _codex_snapshots_equal(cur, seen)


func compute_codex_new_marker_info(tree: SceneTree) -> Dictionary:
	return compute_codex_new_marker_info_with_cur(tree, build_codex_seen_state(tree))


func compute_codex_new_marker_info_with_cur(tree: SceneTree, cur: Dictionary) -> Dictionary:
	_ensure_codex_snap_migrated(tree)
	_ensure_codex_ui_clicked_initialized(tree)
	var ui: Dictionary = story_flags[_CODEX_UI_KEY]
	_codex_ui_ensure_subdicts(ui)
	var a: Dictionary = ui["a"] as Dictionary
	var c: Dictionary = ui["c"] as Dictionary
	var i: Dictionary = ui["i"] as Dictionary
	var cur_arch := _codex_string_array_from_variant(cur.get("archive_ids", []))
	var new_arch: PackedStringArray = []
	for id in cur_arch:
		if not a.get(id, false):
			new_arch.append(id)
	var cur_items := _codex_string_array_from_variant(cur.get("item_ids", []))
	var new_items: PackedStringArray = []
	for id in cur_items:
		if not i.get(id, false):
			new_items.append(id)
	var cc := _codex_char_map_from_variant(cur.get("char_stories", {}))
	var new_chars: PackedStringArray = []
	var cur_sum := _codex_summary_combined_hash_from_state(cur)
	var cur_tl := _codex_int_hash(cur.get("timeline", 0))
	var ack_sum := _codex_int_hash(ui.get("sum", -1999999999))
	var ack_tl := _codex_int_hash(ui.get("tl", -1999999999))
	var tabs: Array = [false, false, false, false, false, false]
	if cur_sum != ack_sum:
		tabs[0] = true
	for k in cc:
		var cur_h := int(cc[k])
		var ack_raw: Variant = c.get(k, -1888888888)
		var ack_h := _codex_int_hash(ack_raw)
		if cur_h != ack_h:
			tabs[1] = true
			new_chars.append(k)
	if not new_arch.is_empty():
		tabs[2] = true
	if cur_tl != ack_tl:
		tabs[3] = true
	if not new_items.is_empty():
		tabs[4] = true
	return {
		"tabs": tabs,
		"new_archive_ids": new_arch,
		"new_item_ids": new_items,
		"new_char_keys": new_chars,
	}


func get_building_tier(building_type: String) -> int:
	if not building_levels.has(building_type):
		return 0
	return clampi(int(building_levels[building_type]), 0, 4)


func set_building_tier(building_type: String, tier: int) -> void:
	building_levels[building_type] = clampi(tier, 0, 4)


func get_resume_location_enum() -> Events.LOCATION:
	var v: int = clampi(resume_game_location, 0, int(Events.LOCATION.LVL5))
	return v as Events.LOCATION


func configure_death_resume_to_base_teleport() -> void:
	current_health = 1
	resume_from_death = true
	resume_game_location = int(Events.LOCATION.BASE)
	resume_player_position_x = BASE_TELEPORT_RESUME_X
	resume_player_position_y = BASE_TELEPORT_RESUME_Y
	apply_resume_position_on_next_scene = true
	death_resume_pending = true
	save_game()


func reset_data():
	invalidate_codex_state_build_cache()
	var keep_vm := volume_music
	var keep_vs := volume_sfx
	var keep_vu := volume_ui
	var keep_vd := volume_dialogue
	## Сначала память и сигналы — даже если запись файла не удастся, новая игра не останется со старым золотом/ресурсами.
	var game_data := {}
	for variable in SAVE_DATA:
		var v: Variant = default_data[variable]
		if variable == "story_flags" or variable == "island_zone_state" or variable == "opened_chest_ids" or variable == "chest_rolled_tiers":
			v = (v as Dictionary).duplicate()
		elif variable == "building_levels":
			v = DEFAULT_BUILDING_LEVELS.duplicate()
		game_data[variable] = v
		set(variable, v)

	building_levels = DEFAULT_BUILDING_LEVELS.duplicate()
	game_data["building_levels"] = building_levels.duplicate()

	volume_music = keep_vm
	volume_sfx = keep_vs
	volume_ui = keep_vu
	volume_dialogue = keep_vd
	game_data["volume_music"] = volume_music
	game_data["volume_sfx"] = volume_sfx
	game_data["volume_ui"] = volume_ui
	game_data["volume_dialogue"] = volume_dialogue

	current_health = HeroProgression.get_tier_for_level(current_level).max_health
	game_data["current_health"] = current_health

	# Мясо и дерево: старт новой игры (default_data) + согласование с лимитом отряда и обновление HUD.
	meat_count = int(default_data["meat_count"])
	wood_count = int(default_data["wood_count"])
	var _warriors_new_game := archer_count + lancer_count
	if meat_count < _warriors_new_game:
		meat_count = _warriors_new_game
	game_data["meat_count"] = meat_count
	game_data["wood_count"] = wood_count
	Events.gold_changed.emit(gold)
	Events.meat_changed.emit(meat_count)
	Events.wood_changed.emit(wood_count)
	Events.ore_changed.emit(ore_count)

	death_resume_pending = false
	resume_from_death = false

	var game_save_file = FileAccess.open(GAME_SAVE_FILE, FileAccess.WRITE)
	if game_save_file == null:
		printerr("Save faild with code {0}".format([FileAccess.get_open_error()]))
		return

	var json_object := JSON.new()
	game_save_file.store_line(json_object.stringify(game_data))
