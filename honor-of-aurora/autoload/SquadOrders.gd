extends Node
## Глобальный режим отряда (купленные юниты): следование, патруль или стояние.

enum Mode { COMBAT, PATROL, HOLD }

var mode: Mode = Mode.COMBAT

signal mode_changed(new_mode: Mode)


func _ready() -> void:
	Events.location_changed.connect(_on_location_changed)
	call_deferred("_sync_mode_to_current_location")


func _sync_mode_to_current_location() -> void:
	_on_location_changed(Events.current_location)


func _on_location_changed(loc: Events.LOCATION) -> void:
	if Events.is_adventure_location(loc):
		set_mode(Mode.COMBAT)
	elif loc == Events.LOCATION.BASE:
		set_mode(Mode.PATROL)


func set_mode(m: Mode) -> void:
	if mode == m:
		return
	mode = m
	mode_changed.emit(mode)


func reset_to_combat() -> void:
	set_mode(Mode.COMBAT)
