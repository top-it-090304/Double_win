extends Node

var gold: int = 0
var boss_kill: int = 0
var current_health = 100
var current_level = 1
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
## Уровни зданий на базе: ключ building_type → 0..4 (BuildingColor: 0 = первая текстура / «уровень 1» … 4 = макс.).
const DEFAULT_BUILDING_LEVELS := {
	"Monastery": 0,
	"Castle": 0,
	"Barracks": 0,
	"Archery": 0,
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
## Сенсорное управление: 0 = авто, 1 = всегда показывать, 2 = скрыть (ПК/геймпад).
var touch_mode: int = 0
## Размер виртуального джойстика и кнопок, % (70–150).
var touch_scale_percent: int = 100
## Прозрачность сенсорного HUD, % (25–100).
var touch_opacity_percent: int = 52
## Вибрация при уроне (Android / iOS).
var haptic_enabled: bool = true


const GAME_SAVE_FILE := "user://game_save_file.save"
const SAVE_DATA = ["gold", "boss_kill", "current_health", "current_level", "current_exp", "archer_count", "lancer_count", "pawn_count", "death_count", "expedition_return_count", "was_on_adventure_before_menu", "resume_game_location", "resume_player_position_x", "resume_player_position_y", "resume_from_death", "story_flags", "island_zone_state", "building_levels", "volume_music", "volume_sfx", "volume_ui", "volume_dialogue", "difficulty_id", "ui_scale_percent", "max_fps", "touch_mode", "touch_scale_percent", "touch_opacity_percent", "haptic_enabled"]
const default_data := {
	"gold" : 0,
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
	"touch_mode" : 0,
	"touch_scale_percent" : 100,
	"touch_opacity_percent" : 52,
	"haptic_enabled" : true,
}


func load_game():
	if not FileAccess.file_exists(GAME_SAVE_FILE):
		current_health = HeroProgression.get_tier_for_level(current_level).max_health
		building_levels = DEFAULT_BUILDING_LEVELS.duplicate()
		_normalize_settings_fields()
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
			elif variable == "building_levels" and v is Dictionary:
				building_levels = (v as Dictionary).duplicate()
			elif variable.begins_with("volume_") and typeof(v) in [TYPE_FLOAT, TYPE_INT]:
				set(variable, clampf(float(v), 0.0, 1.0))
			elif variable == "ui_scale_percent" and typeof(v) in [TYPE_FLOAT, TYPE_INT]:
				ui_scale_percent = clampi(int(v), 75, 130)
			elif variable == "max_fps" and typeof(v) in [TYPE_FLOAT, TYPE_INT]:
				max_fps = clampi(int(v), 0, 240)
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
		elif variable == "building_levels":
			building_levels = DEFAULT_BUILDING_LEVELS.duplicate()

	building_levels = _normalize_building_levels(building_levels)

	_migrate_story_island_flags_from_legacy_boss_kill()
	_migrate_truth_choice_flags()
	if not game_data.has("difficulty_id"):
		difficulty_id = 1
	difficulty_id = clampi(int(difficulty_id), 0, 2)
	if not game_data.has("lancer_count"):
		lancer_count = 0
	if not game_data.has("pawn_count"):
		pawn_count = 0
	if not game_data.has("resume_from_death"):
		resume_from_death = (
			current_health == 1
			and resume_game_location == int(Events.LOCATION.BASE)
			and abs(resume_player_position_x - BASE_TELEPORT_RESUME_X) < 2.0
			and abs(resume_player_position_y - BASE_TELEPORT_RESUME_Y) < 2.0
		)

	_normalize_settings_fields()
	call_deferred("apply_window_and_engine_settings")


func _normalize_settings_fields() -> void:
	ui_scale_percent = clampi(int(ui_scale_percent), 75, 130)
	max_fps = clampi(int(max_fps), 0, 240)
	touch_mode = clampi(int(touch_mode), 0, 2)
	touch_scale_percent = clampi(int(touch_scale_percent), 70, 150)
	touch_opacity_percent = clampi(int(touch_opacity_percent), 25, 100)
	difficulty_id = clampi(int(difficulty_id), 0, 2)


## Окно и движок после загрузки сохранения или смены настроек.
func apply_window_and_engine_settings() -> void:
	var w := get_window()
	if w:
		w.content_scale_factor = clampf(float(ui_scale_percent) / 100.0, 0.75, 1.5)
	if max_fps <= 0:
		Engine.max_fps = 0
	else:
		Engine.max_fps = clampi(max_fps, 30, 240)


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
	if unit.is_in_group("ally_archer"):
		archer_count = maxi(0, archer_count - 1)
	elif unit.is_in_group("ally_lancer"):
		lancer_count = maxi(0, lancer_count - 1)
	elif unit.is_in_group("ally_pawn"):
		pawn_count = maxi(0, pawn_count - 1)
	save_game()


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


func _normalize_building_levels(src: Dictionary) -> Dictionary:
	var out := DEFAULT_BUILDING_LEVELS.duplicate()
	if src.is_empty():
		return out
	for k in out.keys():
		if src.has(k):
			out[k] = clampi(int(src[k]), 0, 4)
	return out


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
	var keep_vm := volume_music
	var keep_vs := volume_sfx
	var keep_vu := volume_ui
	var keep_vd := volume_dialogue
	var game_save_file = FileAccess.open(GAME_SAVE_FILE, FileAccess.WRITE)
	if game_save_file == null:
		printerr("Save faild with code {0}".format([FileAccess.get_open_error()]))
		return
		
	var game_data := {}
	for variable in SAVE_DATA:
		var v: Variant = default_data[variable]
		if variable == "story_flags" or variable == "island_zone_state":
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

	death_resume_pending = false
	resume_from_death = false

	var json_object := JSON.new()
	game_save_file.store_line(json_object.stringify(game_data))
