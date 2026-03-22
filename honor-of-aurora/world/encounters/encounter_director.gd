class_name EncounterDirector
extends Node

signal zone_cleared(zone: EncounterZone)

@export var island_key: String = "lvl1"


func register_zone(zone: EncounterZone) -> void:
	zone._director = self


func on_zone_cleared(zone: EncounterZone) -> void:
	zone_cleared.emit(zone)
