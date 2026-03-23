class_name IslandEncounterShared
extends RefCounted
## Общая настройка NavigationRegion2D и фабрика зон встреч для островов.

static var NAV_OUTLINE: PackedVector2Array = PackedVector2Array([
	Vector2(-3200, -1100),
	Vector2(1600, -1100),
	Vector2(1600, 1200),
	Vector2(-3200, 1200),
])


static func attach_navigation_region(parent: Node) -> NavigationRegion2D:
	var nr := NavigationRegion2D.new()
	nr.navigation_layers = 1
	var np := NavigationPolygon.new()
	np.add_outline(NAV_OUTLINE)
	np.make_polygons_from_outlines()
	nr.navigation_polygon = np
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


static func _random_spawn_point(center: Vector2, radius: float, rng: RandomNumberGenerator, parent: Node) -> Vector2:
	for _attempt in 24:
		var off := Vector2(rng.randf_range(-1.0, 1.0), rng.randf_range(-1.0, 1.0)) * radius
		var p := center + off
		if _is_spawn_position_free(p, parent):
			return p
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
