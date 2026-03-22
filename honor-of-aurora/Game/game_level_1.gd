extends Node2D

const ISLAND_KEY := "lvl1"

const _SNAKE := preload("res://enemies/snake/Snake.tscn")
const _GNOME := preload("res://enemies/gnome/gnome.tscn")

var _nav_region: NavigationRegion2D


func _ready() -> void:
	if StoryState.has_flag("story_island_1_cleared"):
		return
	_setup_navigation_region()
	_setup_encounters()


func _setup_navigation_region() -> void:
	_nav_region = NavigationRegion2D.new()
	_nav_region.navigation_layers = 1
	var np := NavigationPolygon.new()
	np.add_outline(
		PackedVector2Array(
			[
				Vector2(-3200, -1100),
				Vector2(1600, -1100),
				Vector2(1600, 1200),
				Vector2(-3200, 1200),
			]
		)
	)
	np.make_polygons_from_outlines()
	_nav_region.navigation_polygon = np
	add_child(_nav_region)


func _wave_entry(scene: PackedScene, count: int) -> EncounterWaveEntry:
	var e := EncounterWaveEntry.new()
	e.enemy_scene = scene
	e.count = count
	return e


func _setup_encounters() -> void:
	var director := EncounterDirector.new()
	director.island_key = ISLAND_KEY
	add_child(director)

	var zones_cfg: Array = [
		{
			"id": "east_path",
			"center": Vector2(-489, 141),
			"radius": 420.0,
			"leash": 920.0,
			"waves":
			[
				[_wave_entry(_SNAKE, 2)],
				[_wave_entry(_SNAKE, 1), _wave_entry(_GNOME, 1)],
			],
		},
		{
			"id": "north_west",
			"center": Vector2(-1584, 172),
			"radius": 450.0,
			"leash": 950.0,
			"waves":
			[
				[_wave_entry(_GNOME, 2)],
				[_wave_entry(_SNAKE, 2), _wave_entry(_GNOME, 1)],
			],
		},
		{
			"id": "deep_ruins",
			"center": Vector2(-2531, -427),
			"radius": 480.0,
			"leash": 1000.0,
			"waves":
			[
				[_wave_entry(_SNAKE, 1), _wave_entry(_GNOME, 2)],
				[_wave_entry(_GNOME, 2)],
			],
		},
		{
			"id": "ridge",
			"center": Vector2(-1117, -746),
			"radius": 440.0,
			"leash": 980.0,
			"waves":
			[
				[_wave_entry(_SNAKE, 2)],
				[_wave_entry(_SNAKE, 2), _wave_entry(_GNOME, 2)],
			],
		},
		{
			"id": "south_beach",
			"center": Vector2(1253, 13),
			"radius": 460.0,
			"leash": 1020.0,
			"waves":
			[
				[_wave_entry(_GNOME, 2)],
				[_wave_entry(_SNAKE, 3)],
			],
		},
	]

	for z in zones_cfg:
		var zone := EncounterZone.new()
		zone.setup_from_config(
			director,
			self,
			ISLAND_KEY,
			z["id"],
			z["center"],
			z["radius"],
			z["waves"],
			z["leash"]
		)
		add_child(zone)
		director.register_zone(zone)
