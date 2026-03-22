extends Node

var gold: int = 0
var boss_kill: int = 0
var current_health = 100
var current_level = 1
var current_exp = 0
var archer_count: int = 0
## Сюжетные флаги для диалогов и квестов (строковый ключ → bool).
var story_flags: Dictionary = {}


const GAME_SAVE_FILE := "user://game_save_file.save"
const SAVE_DATA = ["gold", "boss_kill", "current_health", "current_level", "current_exp", "archer_count", "story_flags"]
const default_data := {
	"gold" : 0,
	"boss_kill" : 0,
	"current_health" : 100,
	"current_level" : 1,
	"current_exp" : 0,
	"archer_count" : 0,
	"story_flags" : {},
	}


func load_game():
	if not FileAccess.file_exists(GAME_SAVE_FILE):
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
		
	var json_object := JSON.new()
	game_save_file.store_line(json_object.stringify(game_data))
	
