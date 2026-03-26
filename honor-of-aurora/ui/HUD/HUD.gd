@tool
extends "res://ui/HUD/game_hud.gd"
## В редакторе HUD скрыт (не отвлекает от сцены); в игре включается в _ready.

@export var teleport_menu: Control
@export var castle_menu: Control
@export var barracks_menu: Control
@export var squad_orders_menu: Control
@export var debug_menu: Control


func set_target_location(location: Events.LOCATION) -> void:
	if teleport_menu and teleport_menu.has_method("set_target_location"):
		teleport_menu.call("set_target_location", location)

func _on_button_pressed() -> void:
	Events.location_changed.emit(Events.LOCATION.MENU)


func _ready() -> void:
	visible = not Engine.is_editor_hint()
	set_process_input(true)
	teleport_menu.hide()
	if debug_menu:
		debug_menu.hide()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_debug_menu"):
		if debug_menu == null:
			return
		if debug_menu.visible:
			hide_debug_menu()
		else:
			show_debug_menu()
		get_viewport().set_input_as_handled()
		return
	if debug_menu != null and debug_menu.visible and event.is_action_pressed("ui_cancel"):
		hide_debug_menu()
		get_viewport().set_input_as_handled()
		return
	if teleport_menu.visible:
		if event.is_action_pressed("ui_cancel"):
			hide_teleport_menu()
			get_viewport().set_input_as_handled()
		return
	if barracks_menu != null and barracks_menu.visible and event.is_action_pressed("ui_cancel"):
		hide_barracks_menu()
		get_viewport().set_input_as_handled()
		return
	if squad_orders_menu != null and squad_orders_menu.visible and event.is_action_pressed("ui_cancel"):
		if squad_orders_menu.has_method("close"):
			squad_orders_menu.close()
		get_viewport().set_input_as_handled()
		return
	if castle_menu != null and castle_menu.visible and event.is_action_pressed("ui_cancel"):
		if castle_menu.has_method("try_close_hire_submenu") and castle_menu.try_close_hire_submenu():
			get_viewport().set_input_as_handled()
			return
		hide_castle_menu()
		get_viewport().set_input_as_handled()

func show_teleport_menu():
	if teleport_menu.visible:
		return
	if debug_menu and debug_menu.visible:
		hide_debug_menu()
	if squad_orders_menu and squad_orders_menu.visible and squad_orders_menu.has_method("close"):
		squad_orders_menu.close()
	if barracks_menu:
		barracks_menu.hide()
	if castle_menu:
		castle_menu.hide()
	SoundManager.play_menu_open()
	teleport_menu.show()
	get_tree().paused = true

func hide_teleport_menu():
	if not teleport_menu.visible:
		return
	SoundManager.play_menu_close()
	teleport_menu.hide()
	get_tree().paused = false


func teleport_to(location: Events.LOCATION):
	if teleport_menu.visible:
		hide_teleport_menu()
	else:
		get_tree().paused = false
	Events.location_changed.emit(location)


func show_castle_menu():
	SoundManager.play_menu_open()
	if debug_menu and debug_menu.visible:
		hide_debug_menu()
	if squad_orders_menu and squad_orders_menu.visible and squad_orders_menu.has_method("close"):
		squad_orders_menu.close()
	if barracks_menu:
		barracks_menu.hide()
	if castle_menu == null:
		return
	if castle_menu.has_method("reset_castle_menu_state"):
		castle_menu.reset_castle_menu_state()
	castle_menu.show()
	get_tree().paused = true


func hide_castle_menu():
	SoundManager.play_menu_close()
	if castle_menu == null:
		return
	castle_menu.hide()
	get_tree().paused = false


func show_barracks_menu():
	if teleport_menu and teleport_menu.visible:
		hide_teleport_menu()
	SoundManager.play_menu_open()
	if debug_menu and debug_menu.visible:
		hide_debug_menu()
	if squad_orders_menu and squad_orders_menu.visible and squad_orders_menu.has_method("close"):
		squad_orders_menu.close()
	if castle_menu:
		castle_menu.hide()
	if barracks_menu == null:
		return
	if barracks_menu.has_method("reset_barracks_menu_state"):
		barracks_menu.reset_barracks_menu_state()
	barracks_menu.show()
	get_tree().paused = true


func hide_barracks_menu():
	SoundManager.play_menu_close()
	if barracks_menu == null:
		return
	barracks_menu.hide()
	get_tree().paused = false


func try_open_squad_orders_menu(unit: Node2D) -> bool:
	if DialogueManager.is_active():
		return false
	if SquadCombatState.is_engaged():
		return false
	if unit == null or not is_instance_valid(unit):
		return false
	if unit.has_method("is_pawn_in_ore_mine") and unit.is_pawn_in_ore_mine():
		return false
	if squad_orders_menu == null or not squad_orders_menu.has_method("open_for"):
		return false
	if squad_orders_menu.visible:
		return false
	if teleport_menu and teleport_menu.visible:
		return false
	if barracks_menu and barracks_menu.visible:
		return false
	if castle_menu and castle_menu.visible:
		return false
	if debug_menu and debug_menu.visible:
		return false
	squad_orders_menu.open_for(unit)
	return true


func show_debug_menu() -> void:
	if debug_menu == null or debug_menu.visible:
		return
	if squad_orders_menu and squad_orders_menu.visible and squad_orders_menu.has_method("close"):
		squad_orders_menu.close()
	if barracks_menu and barracks_menu.visible:
		hide_barracks_menu()
	if castle_menu and castle_menu.visible:
		hide_castle_menu()
	if teleport_menu and teleport_menu.visible:
		hide_teleport_menu()
	SoundManager.play_menu_open()
	debug_menu.show()
	get_tree().paused = true


func hide_debug_menu() -> void:
	if debug_menu == null or not debug_menu.visible:
		return
	SoundManager.play_menu_close()
	debug_menu.hide()
	get_tree().paused = false
