extends Node2D
## Тестовый остров: копия первого уровня с разными врагами в зонах встреч.
## Запуск: откройте `Game_test_island.tscn` и нажмите F6 (Play Scene), либо временно укажите эту сцену главной в project.godot.

const ISLAND_KEY := "test"
const spawn_position: Vector2 = Vector2(600, 740)

const _SNAKE := preload("res://enemies/snake/Snake.tscn")
const _GNOME := preload("res://enemies/gnome/gnome.tscn")
const _GNOLL := preload("res://enemies/gnoll/gnoll.tscn")
const _SPIDER := preload("res://enemies/spider/spider.tscn")
const _TROLL := preload("res://enemies/troll/troll.tscn")
const _BEAR := preload("res://enemies/bear/bear.tscn")
const _LIZARD := preload("res://enemies/lizard/lizard.tscn")
const _PANDA := preload("res://enemies/panda/panda.tscn")
const _THIEF := preload("res://enemies/thief/thief.tscn")
const _SHAMAN := preload("res://enemies/shaman/shaman.tscn")
const _SKULL := preload("res://enemies/skull/skull.tscn")
const _TURTLE := preload("res://enemies/turtle/turtle.tscn")
const _LANCER_SCENE := preload("res://ally/lancer/scenes/lancer_base.tscn")

var _nav_region: NavigationRegion2D


func get_spawn_position() -> Vector2:
	return spawn_position


func _ready() -> void:
	_setup_navigation_region()
	_setup_encounters()
	call_deferred("_spawn_ally_lancer_at_squad_point")


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
				[_wave_entry(_SNAKE, 1), _wave_entry(_GNOME, 1), _wave_entry(_SPIDER, 1)],
				[_wave_entry(_TROLL, 1), _wave_entry(_GNOLL, 1)],
			],
		},
		{
			"id": "north_west",
			"center": Vector2(-1584, 172),
			"radius": 450.0,
			"leash": 950.0,
			"waves":
			[
				[_wave_entry(_BEAR, 1), _wave_entry(_LIZARD, 1)],
				[_wave_entry(_PANDA, 1), _wave_entry(_THIEF, 1)],
			],
		},
		{
			"id": "deep_ruins",
			"center": Vector2(-2531, -427),
			"radius": 480.0,
			"leash": 1000.0,
			"waves":
			[
				[_wave_entry(_SHAMAN, 1), _wave_entry(_SKULL, 1)],
				[_wave_entry(_GNOME, 2), _wave_entry(_TURTLE, 1)],
			],
		},
		{
			"id": "ridge",
			"center": Vector2(-1117, -746),
			"radius": 440.0,
			"leash": 980.0,
			"waves":
			[
				[_wave_entry(_SNAKE, 2), _wave_entry(_GNOLL, 1)],
				[_wave_entry(_SPIDER, 2), _wave_entry(_TROLL, 1)],
			],
		},
		{
			"id": "south_beach",
			"center": Vector2(1253, 13),
			"radius": 460.0,
			"leash": 1020.0,
			"waves":
			[
				[_wave_entry(_GNOLL, 1), _wave_entry(_LIZARD, 1), _wave_entry(_PANDA, 1)],
				[_wave_entry(_BEAR, 1), _wave_entry(_THIEF, 1), _wave_entry(_SHAMAN, 1)],
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


func _spawn_ally_lancer_at_squad_point() -> void:
	var player: Node2D = null
	for _i in range(20):
		player = get_tree().get_first_node_in_group("player") as Node2D
		if player:
			break
		await get_tree().process_frame
	if player == null:
		return
	var avoid: Array[Vector2] = [player.global_position]
	var slot := SaveManager.archer_count + SaveManager.lancer_count + SaveManager.pawn_count
	var want: int = slot + 1
	var positions := GameManager.pick_archer_spawn_positions(self, want, avoid)
	if positions.is_empty():
		return
	var idx: int = clampi(slot, 0, positions.size() - 1)
	var lancer := _LANCER_SCENE.instantiate() as Node2D
	if lancer == null:
		return
	lancer.set_meta("no_squad_death", true)
	add_child(lancer)
	lancer.global_position = positions[idx]
