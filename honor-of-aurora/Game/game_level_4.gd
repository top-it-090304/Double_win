extends "res://Game/game_level_spawn_layer.gd"

const ISLAND_KEY := "lvl4"
const ISLAND_TIER := 4

const _HARPOON := preload("res://enemies/harpoon fish/harpoon_Fish.tscn")
const _LANCER := preload("res://enemies/lancer/lancertscn.tscn")
const _GNOLL := preload("res://enemies/gnoll/gnoll.tscn")
const _SPIDER := preload("res://enemies/spider/spider.tscn")
const _BEAR := preload("res://enemies/bear/bear.tscn")


func _ready() -> void:
	if StoryState.has_flag("story_island_4_cleared"):
		return
	IslandEncounterShared.attach_navigation_region(self)
	var director := EncounterDirector.new()
	director.island_key = ISLAND_KEY
	add_child(director)
	IslandEncounterShared.register_zones(director, self, ISLAND_KEY, ISLAND_TIER, _zones_cfg())
	IslandEncounterShared.connect_resource_drops(director, self, ISLAND_TIER, _BEAR)
	_spawn_roamers()


func _zones_cfg() -> Array:
	return [
		{
			"id": "east_path",
			"center": Vector2(-489, 141),
			"radius": 420.0,
			"leash": 920.0,
			"waves":
			[
				[IslandEncounterShared.wave(_HARPOON, 2), IslandEncounterShared.wave(_GNOLL, 2)],
				[IslandEncounterShared.wave(_BEAR, 2), IslandEncounterShared.wave(_SPIDER, 2)],
			],
		},
		{
			"id": "north_west",
			"center": Vector2(-1584, 172),
			"radius": 450.0,
			"leash": 950.0,
			"waves":
			[
				[IslandEncounterShared.wave(_LANCER, 2)],
				[IslandEncounterShared.wave(_HARPOON, 2), IslandEncounterShared.wave(_GNOLL, 2)],
			],
		},
		{
			"id": "deep_ruins",
			"center": Vector2(-2531, -427),
			"radius": 480.0,
			"leash": 1000.0,
			"waves":
			[
				[IslandEncounterShared.wave(_SPIDER, 3), IslandEncounterShared.wave(_HARPOON, 2)],
				[IslandEncounterShared.wave(_BEAR, 2), IslandEncounterShared.wave(_LANCER, 2)],
			],
		},
		{
			"id": "ridge",
			"center": Vector2(-1117, -746),
			"radius": 440.0,
			"leash": 980.0,
			"waves":
			[
				[IslandEncounterShared.wave(_GNOLL, 2), IslandEncounterShared.wave(_SPIDER, 2)],
				[IslandEncounterShared.wave(_LANCER, 2), IslandEncounterShared.wave(_HARPOON, 2)],
			],
		},
		{
			"id": "south_beach",
			"center": Vector2(1253, 13),
			"radius": 460.0,
			"leash": 1020.0,
			"waves":
			[
				[IslandEncounterShared.wave(_LANCER, 2), IslandEncounterShared.wave(_HARPOON, 2)],
				[IslandEncounterShared.wave(_BEAR, 2), IslandEncounterShared.wave(_SPIDER, 3)],
			],
		},
	]


func _spawn_roamers() -> void:
	var hub := Vector2(-1100, -120)
	IslandEncounterShared.spawn_roaming_pack(self, ISLAND_TIER, _GNOLL, 2, hub, 1100.0, 1600.0)
	IslandEncounterShared.spawn_roaming_pack(self, ISLAND_TIER, _HARPOON, 2, hub, 1100.0, 1600.0)
	IslandEncounterShared.spawn_roaming_pack(self, ISLAND_TIER, _SPIDER, 2, hub, 1100.0, 1600.0)
