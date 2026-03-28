class_name EncounterZone
extends Area2D

## Уникальный id в пределах острова (сохранение).
@export var zone_id: String = "zone"
@export var island_key: String = "lvl1"
## Центр зоны в глобальных координатах сцены (если не задан — global_position узла).
@export var zone_center: Vector2 = Vector2.ZERO
@export var trigger_radius: float = 420.0
## Волны: каждая волна — массив EncounterWaveEntry.
@export var waves: Array = []
@export var max_concurrent_in_zone: int = 14
@export var spawn_spread: float = 96.0
@export var leash_radius: float = 950.0
## Уровень острова (1..5): все враги в зоне получают этот enemy_level для баланса.
@export var island_tier: int = 1

var _cleared: bool = false
var _started: bool = false
var _current_wave_index: int = -1
var _alive_from_wave: int = 0
var _director: Node = null
var _spawn_parent: Node = null
var _rng := RandomNumberGenerator.new()

var _shape: CollisionShape2D


func _ready() -> void:
	add_to_group("encounter_zone")
	_rng.randomize()
	collision_layer = 0
	collision_mask = 2
	monitorable = false
	monitoring = true
	body_entered.connect(_on_body_entered)
	_ensure_shape()
	if zone_center == Vector2.ZERO:
		zone_center = global_position
	if _shape and _shape.shape is CircleShape2D:
		(_shape.shape as CircleShape2D).radius = trigger_radius
	_refresh_cleared_from_save()
	call_deferred("_check_player_already_inside")


func _check_player_already_inside() -> void:
	if _cleared or _started:
		return
	for body in get_overlapping_bodies():
		_on_body_entered(body)


func _ensure_shape() -> void:
	_shape = get_node_or_null("CollisionShape2D") as CollisionShape2D
	if _shape == null:
		_shape = CollisionShape2D.new()
		var circle := CircleShape2D.new()
		circle.radius = trigger_radius
		_shape.shape = circle
		add_child(_shape)


func setup_from_config(
	p_director: Node,
	p_spawn_parent: Node,
	p_island: String,
	p_id: String,
	p_center: Vector2,
	p_radius: float,
	p_waves: Array,
	p_leash: float,
	p_island_tier: int = 1
) -> void:
	_director = p_director
	_spawn_parent = p_spawn_parent
	island_key = p_island
	zone_id = p_id
	zone_center = p_center
	trigger_radius = p_radius
	leash_radius = p_leash
	waves = p_waves
	island_tier = p_island_tier
	global_position = p_center
	_ensure_shape()
	if _shape and _shape.shape is CircleShape2D:
		(_shape.shape as CircleShape2D).radius = trigger_radius
	_refresh_cleared_from_save()


func _refresh_cleared_from_save() -> void:
	var key := IslandProgress.zone_save_key(island_key, zone_id)
	_cleared = SaveManager.island_zone_state.get(key, false) as bool
	if _cleared:
		_started = true


func _save_key() -> String:
	return IslandProgress.zone_save_key(island_key, zone_id)


func _on_body_entered(body: Node) -> void:
	if not GameplayFacade.is_player_body(body):
		return
	if PostFinaleWorld.blocks_new_enemy_spawns():
		_started = true
		return
	if _cleared or _started:
		return
	_started = true
	# Нельзя add_child/менять monitoring во время flush queries (сигнал body_entered).
	call_deferred("_start_next_wave")


func _start_next_wave() -> void:
	if PostFinaleWorld.blocks_new_enemy_spawns():
		return
	_current_wave_index += 1
	while _current_wave_index < waves.size():
		var w: Array = waves[_current_wave_index]
		if not w.is_empty():
			break
		_current_wave_index += 1
	if _current_wave_index >= waves.size():
		_mark_cleared()
		return
	var wave: Array = waves[_current_wave_index]
	_alive_from_wave = 0
	for entry in wave:
		if entry is EncounterWaveEntry:
			_spawn_wave_entry(entry as EncounterWaveEntry)


func _spawn_wave_entry(entry: EncounterWaveEntry) -> void:
	if entry.enemy_scene == null or entry.count <= 0:
		return
	var parent: Node = _spawn_parent if _spawn_parent else get_parent()
	for i in entry.count:
		if _count_alive_in_zone() >= max_concurrent_in_zone:
			break
		var inst := entry.enemy_scene.instantiate() as Node2D
		if inst == null:
			continue
		var pos := _pick_spawn_position()
		inst.global_position = pos
		parent.add_child(inst)
		_alive_from_wave += 1
		if inst is CharacterBody2D:
			var eb: Node = inst
			if eb.has_method("assign_encounter_zone"):
				eb.assign_encounter_zone(self, pos, leash_radius)
		if inst.has_method("configure_for_island_tier"):
			inst.call_deferred("configure_for_island_tier", island_tier)


func _pick_spawn_position() -> Vector2:
	var attempts := 18
	for _i in attempts:
		var off := Vector2(_rng.randf_range(-spawn_spread, spawn_spread), _rng.randf_range(-spawn_spread, spawn_spread))
		var p := zone_center + off
		if _is_spawn_position_free(p):
			return p
	return zone_center


func _is_spawn_position_free(p: Vector2) -> bool:
	var space := get_world_2d().direct_space_state
	var q := PhysicsShapeQueryParameters2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 28.0
	q.shape = circle
	q.transform = Transform2D(0.0, p)
	q.collision_mask = 1
	var hits := space.intersect_shape(q, 6)
	return hits.is_empty()


func _count_alive_in_zone() -> int:
	var n := 0
	var parent: Node = _spawn_parent if _spawn_parent else get_parent()
	for c in parent.get_children():
		if not is_instance_valid(c):
			continue
		if c.is_in_group("enemy") and c.has_meta("_encounter_zone_id"):
			if str(c.get_meta("_encounter_zone_id")) == zone_id:
				n += 1
	return n


func notify_enemy_removed(enemy: Node) -> void:
	if str(enemy.get_meta("_encounter_zone_id", "")) != zone_id:
		return
	_alive_from_wave = maxi(0, _alive_from_wave - 1)
	if _alive_from_wave <= 0:
		call_deferred("_start_next_wave")


func _mark_cleared() -> void:
	if _cleared:
		return
	_cleared = true
	var key := _save_key()
	SaveManager.island_zone_state[key] = true
	SaveManager.save_game()
	if _director and _director.has_method("on_zone_cleared"):
		_director.on_zone_cleared(self)


## После глобального удаления врагов финалом — чтобы волны не зависали в «ждём следующую».
func apply_finale_spawn_shutdown() -> void:
	if not PostFinaleWorld.blocks_new_enemy_spawns():
		return
	_started = true
	_current_wave_index = waves.size()
	_alive_from_wave = 0


func force_reset_for_debug() -> void:
	_cleared = false
	_started = false
	_current_wave_index = -1
	SaveManager.island_zone_state.erase(_save_key())
