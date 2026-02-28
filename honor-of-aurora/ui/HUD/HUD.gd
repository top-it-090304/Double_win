extends CanvasLayer

@export var teleport_menu: Control

func _on_button_pressed() -> void:
	Events.location_changed.emit(Events.LOCATION.MENU)


func _ready():
	teleport_menu.hide()

func _input(event):
	if teleport_menu.visible and event.is_action_pressed("interact"):
		teleport_menu.hide()
		get_tree().paused = false

func show_teleport_menu():
	if teleport_menu.visible:
		return
	teleport_menu.show()
	get_tree().paused = true

func hide_teleport_menu():
	if not teleport_menu.visible:
		return
	teleport_menu.hide()
	get_tree().paused = false


func teleport_to(location: Events.LOCATION):
	teleport_menu.hide()
	get_tree().paused = false
	Events.location_changed.emit(location)
