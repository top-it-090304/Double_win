class_name IslandEncounterShared
extends RefCounted
## Общая настройка NavigationRegion2D и фабрика зон встреч для островов.

static var NAV_OUTLINE: PackedVector2Array = PackedVector2Array([
	Vector2(-3200, -1100),
	Vector2(1600, -1100),
	Vector2(1600, 1200),
	Vector2(-3200, 1200),
])


const _ISLAND_NAV_SCENE := preload("res://world/islads/island_navigation_region.tscn")

## Макс. расстояние от случайной точки до ближайшей точки на сетке: если больше — считаем точку вне проходимой зоны (вода и т.п.).
const MAX_SPAWN_NAV_SNAP_DISTANCE: float = 96.0


static func attach_navigation_region(parent: Node) -> NavigationRegion2D:
	var existing := parent.find_child("IslandNavigationRegion", true, false)
	if existing is NavigationRegion2D:
		return existing as NavigationRegion2D
	var nr := _ISLAND_NAV_SCENE.instantiate() as NavigationRegion2D
	parent.add_child(nr)
	return nr


static func wave(scene: PackedScene, count: int) -> EncounterWaveEntry:
	var e := EncounterWaveEntry.new()
	e.enemy_scene = scene
	e.count = count
	return e


static func register_zones(
	director: EncounterDirector,
	parent: Node,
	island_key: String,
	island_tier: int,
	zones_cfg: Array
) -> void:
	for z in zones_cfg:
		var zone := EncounterZone.new()
		zone.setup_from_config(
			director,
			parent,
			island_key,
			z["id"],
			z["center"],
			z["radius"],
			z["waves"],
			z["leash"],
			island_tier
		)
		parent.add_child(zone)
		director.register_zone(zone)


## Роумеры без волн: патруль по острову, не привязаны к очистке зоны.
static func spawn_roaming_pack(
	parent: Node,
	island_tier: int,
	enemy_scene: PackedScene,
	count: int,
	area_center: Vector2,
	area_radius: float,
	leash: float
) -> void:
	if PostFinaleWorld.blocks_new_enemy_spawns():
		return
	if enemy_scene == null or count <= 0:
		return
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	for _i in count:
		var pos := _random_spawn_point(area_center, area_radius, rng, parent)
		var inst := enemy_scene.instantiate() as Node2D
		if inst == null:
			continue
		inst.global_position = pos
		parent.add_child(inst)
		if inst.has_method("assign_ambient_spawn"):
			inst.assign_ambient_spawn(pos, leash)
		if inst.has_method("configure_for_island_tier"):
			inst.call_deferred("configure_for_island_tier", island_tier)


## Возвращает точку на нав-сетке или `null`, если сырой точки слишком далеко до проходимой области.
static func refine_spawn_point_for_island(raw: Vector2, root: Node) -> Variant:
	var world: World2D = root.get_world_2d() if root else null
	if world == null:
		return raw
	var map_rid: RID = world.get_navigation_map()
	if map_rid == RID():
		return raw
	var snapped: Vector2 = NavigationServer2D.map_get_closest_point(map_rid, raw)
	if raw.distance_to(snapped) > MAX_SPAWN_NAV_SNAP_DISTANCE:
		return null
	return snapped


static func _random_spawn_point(center: Vector2, radius: float, rng: RandomNumberGenerator, parent: Node) -> Vector2:
	for _attempt in 32:
		var off := Vector2(rng.randf_range(-1.0, 1.0), rng.randf_range(-1.0, 1.0)) * radius
		var p := center + off
		var refined: Variant = refine_spawn_point_for_island(p, parent)
		if refined == null:
			continue
		p = refined as Vector2
		if _is_spawn_position_free(p, parent):
			return p
	## Запасной выбор у центра зоны на сетке, если случайные точки не удались.
	var fb_var: Variant = refine_spawn_point_for_island(center, parent)
	if fb_var != null:
		var fb: Vector2 = fb_var as Vector2
		if _is_spawn_position_free(fb, parent):
			return fb
	return center


static func _is_spawn_position_free(p: Vector2, parent: Node) -> bool:
	var world: World2D = parent.get_world_2d()
	if world == null:
		return true
	var space: PhysicsDirectSpaceState2D = world.direct_space_state
	var q := PhysicsShapeQueryParameters2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 28.0
	q.shape = circle
	q.transform = Transform2D(0.0, p)
	q.collision_mask = 1
	var hits: Array = space.intersect_shape(q, 6)
	return hits.is_empty()


## ═══════════════════════════════════════════════════════
##  РЕСУРСНЫЕ ПИКАПЫ ПРИ ОЧИСТКЕ ЗОНЫ
## ═══════════════════════════════════════════════════════

const _ORE_PICKUP_SCENE := preload("res://objects/resource_pickups/ore_pickup.tscn")
const _WOOD_PICKUP_SCENE := preload("res://objects/resource_pickups/wood_pickup.tscn")
const _MEAT_PICKUP_SCENE := preload("res://objects/resource_pickups/meat_pickup.tscn")

const _RESOURCE_DROP_SPREAD := 64.0
const _ORE_GUARDIAN_HP_MULT := 2.5
const _ORE_GUARDIAN_DMG_MULT := 1.8

static var _ore_zone_chance_by_tier: Array[float] = [0.15, 0.20, 0.25, 0.30, 0.40]


static func connect_resource_drops(director: EncounterDirector, parent: Node, island_tier: int, guardian_scene: PackedScene = null) -> void:
	director.zone_cleared.connect(func(zone: EncounterZone) -> void:
		_on_zone_cleared_spawn_resources(zone, parent, island_tier, guardian_scene)
	)


static func _on_zone_cleared_spawn_resources(zone: EncounterZone, parent: Node, island_tier: int, guardian_scene: PackedScene) -> void:
	var center := zone.zone_center
	var rng := RandomNumberGenerator.new()
	rng.randomize()

	var wood_count := rng.randi_range(1, 2 + island_tier / 2)
	var meat_count := rng.randi_range(0, 1 + island_tier / 3)

	for _i in wood_count:
		_spawn_pickup_near(parent, _WOOD_PICKUP_SCENE, center, rng)

	if _MEAT_PICKUP_SCENE != null:
		for _j in meat_count:
			_spawn_pickup_near(parent, _MEAT_PICKUP_SCENE, center, rng)

	var ore_chance: float = _ore_zone_chance_by_tier[clampi(island_tier - 1, 0, _ore_zone_chance_by_tier.size() - 1)]
	if rng.randf() < ore_chance:
		var ore_pos := _random_offset(center, _RESOURCE_DROP_SPREAD * 1.5, rng)
		_spawn_pickup_at(parent, _ORE_PICKUP_SCENE, ore_pos)
		if guardian_scene != null:
			_spawn_ore_guardian(parent, guardian_scene, ore_pos, island_tier, zone)


static func _spawn_pickup_near(parent: Node, scene: PackedScene, center: Vector2, rng: RandomNumberGenerator) -> void:
	var pos := _random_offset(center, _RESOURCE_DROP_SPREAD, rng)
	_spawn_pickup_at(parent, scene, pos)


static func _spawn_pickup_at(parent: Node, scene: PackedScene, pos: Vector2) -> void:
	if scene == null:
		return
	var inst := scene.instantiate() as Node2D
	if inst == null:
		return
	inst.global_position = pos
	parent.call_deferred("add_child", inst)


static func _spawn_ore_guardian(parent: Node, scene: PackedScene, ore_pos: Vector2, island_tier: int, zone: EncounterZone) -> void:
	var inst := scene.instantiate() as Node2D
	if inst == null:
		return
	inst.global_position = ore_pos + Vector2(40, -20)
	parent.call_deferred("add_child", inst)
	if inst.has_method("configure_for_island_tier"):
		inst.call_deferred("configure_for_island_tier", island_tier)
	inst.set_meta("ore_guardian", true)
	inst.set_meta("_hp_mult", _ORE_GUARDIAN_HP_MULT)
	inst.set_meta("_dmg_mult", _ORE_GUARDIAN_DMG_MULT)


static func _random_offset(center: Vector2, spread: float, rng: RandomNumberGenerator) -> Vector2:
	return center + Vector2(rng.randf_range(-spread, spread), rng.randf_range(-spread, spread))
