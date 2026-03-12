extends Node

var gold: int = 0
var boss_kill: int = 0
var current_health = 100
var current_level = 1
var current_exp = 0

const GAME_SAVE_FILE := "user://game_save_file.save"
const SAVE_DATA = ["gold", "boss_kill", "current_health", "current_level", "current_exp"]
const default_data := {
	"gold" : 0,
	"boss_kill" : 0,
	"current_health" : 100,
	"current_level" : 1,
	"current_exp" : 0
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
			set(variable, game_data[variable])



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
		game_data[variable] = default_data[variable]
		set(variable, default_data[variable])
		
	var json_object := JSON.new()
	game_save_file.store_line(json_object.stringify(game_data))
	
