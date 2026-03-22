extends Node

var gold: int = 0
var boss_kill: int = 0
var current_health = 100
var current_level = 1
var current_exp = 0
var archer_count: int = 0
## Сюжетные флаги для диалогов и квестов (строковый ключ → bool).
var story_flags: Dictionary = {}
## Громкости шин (0.0–1.0), см. SoundManager.apply_user_volume_settings().
var volume_music: float = 1.0
var volume_sfx: float = 1.0
var volume_ui: float = 1.0
var volume_dialogue: float = 1.0


const GAME_SAVE_FILE := "user://game_save_file.save"
const SAVE_DATA = ["gold", "boss_kill", "current_health", "current_level", "current_exp", "archer_count", "story_flags", "volume_music", "volume_sfx", "volume_ui", "volume_dialogue"]
const default_data := {
	"gold" : 0,
	"boss_kill" : 0,
	"current_health" : 100,
	"current_level" : 1,
	"current_exp" : 0,
	"archer_count" : 0,
	"story_flags" : {},
	"volume_music" : 1.0,
	"volume_sfx" : 1.0,
	"volume_ui" : 1.0,
	"volume_dialogue" : 1.0,
	}


func load_game():
	if not FileAccess.file_exists(GAME_SAVE_FILE):
		current_health = HeroProgression.get_tier_for_level(current_level).max_health
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
			elif variable.begins_with("volume_") and typeof(v) in [TYPE_FLOAT, TYPE_INT]:
				set(variable, clampf(float(v), 0.0, 1.0))
			else:
				set(variable, v)



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
		if variable == "story_flags":
			v = (v as Dictionary).duplicate()
		game_data[variable] = v
		set(variable, v)

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

	var json_object := JSON.new()
	game_save_file.store_line(json_object.stringify(game_data))
