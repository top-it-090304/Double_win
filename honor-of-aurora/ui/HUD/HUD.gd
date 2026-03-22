extends CanvasLayer

@export var teleport_menu: Control
@export var castle_menu: Control

func _on_button_pressed() -> void:
	Events.location_changed.emit(Events.LOCATION.MENU)


func _ready():
	teleport_menu.hide()

func _input(event):
	if teleport_menu.visible and event.is_action_pressed("interact"):
		hide_teleport_menu()

func show_teleport_menu():
	if teleport_menu.visible:
		return
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
	castle_menu.show()
	get_tree().paused = true


func hide_castle_menu():
	SoundManager.play_menu_close()
	castle_menu.hide()
	get_tree().paused = false
