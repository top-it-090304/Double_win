extends Node

const GOLD_PICKUP_SCENE := preload("res://objects/resource_pickups/gold_pickup.tscn")
const MEAT_PICKUP_SCENE := preload("res://objects/resource_pickups/meat_pickup.tscn")
const WOOD_PICKUP_SCENE := preload("res://objects/resource_pickups/wood_pickup.tscn")
const ORE_PICKUP_SCENE := preload("res://objects/resource_pickups/ore_pickup.tscn")
const BOSS_ORE_SPARK_SCENE := preload("res://objects/resource_pickups/boss_ore_spark.tscn")

var current_scene_player: Node = null

## Оружейная (Barracks): бонусы до возврата с острова. Сбрасываются при прибытии на базу с похода.
var armory_attack_bonus: int = 0
## Доля входящего урона в блоке щитом (база 0.2). Меньше — лучше защита.
var armory_shield_damage_factor: float = 0.2
var armory_sword_prepared: bool = false
var armory_shield_prepared: bool = false

const ARMORY_SWORD_DAMAGE_BONUS: int = 12
const ARMORY_SHIELD_FACTOR_DELTA: float = 0.035
const ARMORY_SHIELD_FACTOR_MIN: float = 0.07
## Базовая доля урона, проходящая в блоке щитом (20%).
const ARMORY_SHIELD_BASE_DAMAGE_FACTOR: float = 0.2
## На каждый уровень здания Barracks (0→4): +12.5% к силе временного бафа (заточка / щит).
const ARMORY_TIER_BUFF_PER_LEVEL: float = 0.125

## Церковь (меню здания): ритуал выносливости + благословение стойкости на поход.
var monastery_vitality_prepared: bool = false
var monastery_hp_bonus_ratio: float = 0.0
var monastery_fortitude_prepared: bool = false
var monastery_fortitude_damage_reduction: float = 0.0

const MONASTERY_VITALITY_BASE_RATIO: float = 0.08
const MONASTERY_VITALITY_PER_TIER_RATIO: float = 0.03
const MONASTERY_FORTITUDE_BASE_RATIO: float = 0.10
const MONASTERY_FORTITUDE_PER_TIER_RATIO: float = 0.04

## Стрельбище: пассивы от уровня + временные приказы на поход.
var archery_volley_prepared: bool = false
var archery_guard_prepared: bool = false

const ARCHERY_PASSIVE_HP_PER_TIER: float = 0.08
const ARCHERY_PASSIVE_AS_PER_TIER: float = 0.05
const ARCHERY_VOLLEY_BASE_RATIO: float = 0.08
const ARCHERY_VOLLEY_PER_TIER_RATIO: float = 0.03
const ARCHERY_GUARD_BASE_RATIO: float = 0.10
const ARCHERY_GUARD_PER_TIER_RATIO: float = 0.03

const ALLY_HP_PER_TIER_RATIO: float = 0.18
const ALLY_DAMAGE_PER_TIER_RATIO: float = 0.14
const ALLY_SPEED_PER_TIER_RATIO: float = 0.04

## Снимок отряда на старте похода — нужен для расчёта «павших» к ритуалу воскрешения.
var _expedition_snapshot_active: bool = false
var _expedition_start_archer_count: int = 0
var _expedition_start_lancer_count: int = 0
var _expedition_start_pawn_count: int = 0

## Плейтест (только debug): убийства врагов с последнего аппа уровня.
var playtest_kills_since_level_up: int = 0


## Уровень оружейной на базе (0 = чёрная текстура … 4 = жёлтая). Влияет только на величину временных бафов.
func get_armory_building_tier() -> int:
	return SaveManager.get_building_tier("Barracks")


## Множитель силы бафа «перед походом» от прокачки здания Barracks.
func get_armory_prep_strength_multiplier() -> float:
	return 1.0 + ARMORY_TIER_BUFF_PER_LEVEL * float(get_armory_building_tier())


func get_monastery_building_tier() -> int:
	return SaveManager.get_building_tier("Monastery")


func get_archery_building_tier() -> int:
	return SaveManager.get_building_tier("Archery")


func get_monastery_vitality_ratio_preview() -> float:
	var t := get_monastery_building_tier()
	return MONASTERY_VITALITY_BASE_RATIO + MONASTERY_VITALITY_PER_TIER_RATIO * float(t)


func get_monastery_fortitude_ratio_preview() -> float:
	var t := get_monastery_building_tier()
	return MONASTERY_FORTITUDE_BASE_RATIO + MONASTERY_FORTITUDE_PER_TIER_RATIO * float(t)


func get_archery_passive_hp_ratio() -> float:
	return ARCHERY_PASSIVE_HP_PER_TIER * float(get_archery_building_tier())


func get_archery_passive_attack_speed_ratio() -> float:
	return ARCHERY_PASSIVE_AS_PER_TIER * float(get_archery_building_tier())


func get_archery_volley_ratio_preview() -> float:
	var t := get_archery_building_tier()
	return ARCHERY_VOLLEY_BASE_RATIO + ARCHERY_VOLLEY_PER_TIER_RATIO * float(t)


func get_archery_guard_ratio_preview() -> float:
	var t := get_archery_building_tier()
	return ARCHERY_GUARD_BASE_RATIO + ARCHERY_GUARD_PER_TIER_RATIO * float(t)


func get_archery_attack_speed_multiplier() -> float:
	var passive_mul := 1.0 + get_archery_passive_attack_speed_ratio()
	var active_mul := 1.0 + (get_archery_volley_ratio_preview() if archery_volley_prepared else 0.0)
	return passive_mul * active_mul


func get_archery_hp_multiplier() -> float:
	var passive_mul := 1.0 + get_archery_passive_hp_ratio()
	var active_mul := 1.0 + (get_archery_guard_ratio_preview() if archery_guard_prepared else 0.0)
	return passive_mul * active_mul


func get_monastery_hp_multiplier() -> float:
	return 1.0 + monastery_hp_bonus_ratio


func get_monastery_damage_reduction_multiplier() -> float:
	return 1.0 - monastery_fortitude_damage_reduction


func get_armory_sword_buff_cost() -> int:
	return BalanceConfig.get_armory_sword_buff_cost()


func get_armory_shield_buff_cost() -> int:
	return BalanceConfig.get_armory_shield_buff_cost()


## Сколько урона добавит следующая заточка (к атаке героя, до конца похода).
func get_armory_sword_buff_damage_preview() -> int:
	return int(round(float(ARMORY_SWORD_DAMAGE_BONUS) * get_armory_prep_strength_multiplier()))


## На сколько снизится доля урона в блоке (абсолютные процентные пункты от полного удара).
func get_armory_shield_buff_delta_ratio() -> float:
	return ARMORY_SHIELD_FACTOR_DELTA * get_armory_prep_strength_multiplier()


## Доля урона в блоке после следующей правки (0…1).
func get_armory_shield_factor_after_buff_preview() -> float:
	return maxf(ARMORY_SHIELD_FACTOR_MIN, ARMORY_SHIELD_BASE_DAMAGE_FACTOR - get_armory_shield_buff_delta_ratio())


func try_prepare_armory_sword() -> bool:
	if armory_sword_prepared:
		return false
	if not GameplayFacade.try_spend_gold_or_ore(BalanceConfig.get_armory_sword_buff_cost()):
		return false
	armory_sword_prepared = true
	var mul := get_armory_prep_strength_multiplier()
	armory_attack_bonus += int(round(float(ARMORY_SWORD_DAMAGE_BONUS) * mul))
	var player := _find_player_node_in_current_scene()
	if player and player.has_method("apply_armory_attack_bonus_from_manager"):
		player.apply_armory_attack_bonus_from_manager()
	return true


func try_prepare_armory_shield() -> bool:
	if armory_shield_prepared:
		return false
	if not GameplayFacade.try_spend_gold_or_ore(BalanceConfig.get_armory_shield_buff_cost()):
		return false
	armory_shield_prepared = true
	var mul := get_armory_prep_strength_multiplier()
	var delta := ARMORY_SHIELD_FACTOR_DELTA * mul
	armory_shield_damage_factor = maxf(ARMORY_SHIELD_FACTOR_MIN, armory_shield_damage_factor - delta)
	return true


func try_prepare_monastery_vitality() -> bool:
	if monastery_vitality_prepared:
		return false
	if not GameplayFacade.try_spend_gold_plus_ore(
		BalanceConfig.get_monastery_vitality_gold_cost(),
		BalanceConfig.get_monastery_vitality_ore_cost()
	):
		return false
	monastery_vitality_prepared = true
	monastery_hp_bonus_ratio = get_monastery_vitality_ratio_preview()
	var player := _find_player_node_in_current_scene()
	if player and player.has_method("apply_hero_stat_bonuses_from_save"):
		player.apply_hero_stat_bonuses_from_save()
	return true


func try_prepare_monastery_fortitude() -> bool:
	if monastery_fortitude_prepared:
		return false
	if not GameplayFacade.try_spend_gold_plus_ore(
		BalanceConfig.get_monastery_revive_gold_cost(),
		BalanceConfig.get_monastery_revive_ore_cost()
	):
		return false
	monastery_fortitude_prepared = true
	monastery_fortitude_damage_reduction = get_monastery_fortitude_ratio_preview()
	return true


func try_prepare_archery_volley() -> bool:
	if archery_volley_prepared:
		return false
	if not GameplayFacade.try_spend_gold_plus_ore(
		BalanceConfig.get_archery_volley_gold_cost(),
		BalanceConfig.get_archery_volley_ore_cost()
	):
		return false
	archery_volley_prepared = true
	_apply_archery_modifiers_to_active_archers()
	return true


func try_prepare_archery_guard() -> bool:
	if archery_guard_prepared:
		return false
	if not GameplayFacade.try_spend_gold_plus_ore(
		BalanceConfig.get_archery_guard_gold_cost(),
		BalanceConfig.get_archery_guard_ore_cost()
	):
		return false
	archery_guard_prepared = true
	_apply_archery_modifiers_to_active_archers()
	return true


func reset_armory_preparation() -> void:
	armory_attack_bonus = 0
	armory_shield_damage_factor = ARMORY_SHIELD_BASE_DAMAGE_FACTOR
	armory_sword_prepared = false
	armory_shield_prepared = false


func reset_monastery_preparation() -> void:
	monastery_vitality_prepared = false
	monastery_hp_bonus_ratio = 0.0
	monastery_fortitude_prepared = false
	monastery_fortitude_damage_reduction = 0.0


func reset_archery_preparation() -> void:
	archery_volley_prepared = false
	archery_guard_prepared = false
	_apply_archery_modifiers_to_active_archers()


func _apply_archery_modifiers_to_active_archers() -> void:
	for n in get_tree().get_nodes_in_group("ally_archer"):
		if n and is_instance_valid(n) and n.has_method("apply_archery_modifiers_from_manager"):
			n.apply_archery_modifiers_from_manager()


func refresh_archery_modifiers_for_active_units() -> void:
	_apply_archery_modifiers_to_active_archers()


func get_ally_building_tier(unit_kind: String) -> int:
	match unit_kind:
		"archer":
			return SaveManager.get_building_tier("Archery")
		"pawn":
			return SaveManager.get_building_tier("Castle")
		"lancer", _:
			return SaveManager.get_building_tier("Barracks")


func get_ally_tier_stat_multiplier(unit_kind: String) -> Dictionary:
	var tier := get_ally_building_tier(unit_kind)
	return {
		"hp": 1.0 + ALLY_HP_PER_TIER_RATIO * float(tier),
		"damage": 1.0 + ALLY_DAMAGE_PER_TIER_RATIO * float(tier),
		"speed": 1.0 + ALLY_SPEED_PER_TIER_RATIO * float(tier),
	}


func get_tier_visual_modulate(tier: int) -> Color:
	match clampi(tier, 0, 4):
		1:
			return Color(0.76, 0.88, 1.0, 1.0) # blue
		2:
			return Color(1.0, 0.78, 0.78, 1.0) # red
		3:
			return Color(0.9, 0.8, 1.0, 1.0) # purple
		4:
			return Color(1.0, 0.95, 0.72, 1.0) # yellow
		_:
			return Color(1.0, 1.0, 1.0, 1.0) # black/base


func refresh_all_companion_progression() -> void:
	for group_name in ["ally_archer", "ally_lancer", "ally_pawn"]:
		for n in get_tree().get_nodes_in_group(group_name):
			if n and is_instance_valid(n) and n.has_method("apply_building_progression_from_manager"):
				n.apply_building_progression_from_manager()


func purchase_premium_ore_pack(pack_id: String) -> bool:
	var pack := BalanceConfig.get_premium_ore_pack(pack_id)
	if pack.is_empty():
		return false
	var ore_amount := maxi(0, int(pack.get("ore", 0))) + maxi(0, int(pack.get("bonus_ore", 0)))
	if ore_amount <= 0:
		return false
	## `add_ore` пишет сейв до обновления premium_* — для покупки нужна одна атомарная запись.
	add_ore_volatile(ore_amount)
	SaveManager.premium_ore_purchased_total += ore_amount
	SaveManager.premium_ore_purchase_count += 1
	_check_patron_tier_unlock()
	SaveManager.save_game()
	Events.premium_ore_pack_purchased.emit(pack_id, ore_amount)
	return true


func _check_patron_tier_unlock() -> void:
	var total := SaveManager.premium_ore_purchased_total
	for t in BalanceConfig.PATRON_TIERS:
		if not (t is Dictionary):
			continue
		if total < int(t.get("ore_threshold", 0)):
			continue
		var reward_id := str(t.get("reward", ""))
		match reward_id:
			"thank_letter":
				if not StoryState.has_flag("patron_thank_letter"):
					StoryState.write_flag("patron_thank_letter", true)
			"title_frame":
				if not StoryState.has_flag("patron_title_frame"):
					StoryState.write_flag("patron_title_frame", true)
			"chronicle_name":
				if not StoryState.has_flag("patron_chronicle_name"):
					StoryState.write_flag("patron_chronicle_name", true)
			"chest_note":
				if not StoryState.has_flag("patron_chest_note"):
					StoryState.write_flag("patron_chest_note", true)


func _capture_expedition_start_snapshot() -> void:
	_expedition_snapshot_active = true
	_expedition_start_archer_count = SaveManager.archer_count
	_expedition_start_lancer_count = SaveManager.lancer_count
	_expedition_start_pawn_count = SaveManager.pawn_count


func _finalize_expedition_losses_snapshot() -> void:
	if not _expedition_snapshot_active:
		return
	_expedition_snapshot_active = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process_input(true)
	SaveManager.load_game()
	Events.sync_story_state_from_save()
	Events.location_changed.connect(handle_location_changed)
	if not Events.crown_title_changed.is_connected(_on_crown_title_changed_refresh_hero_stats):
		Events.crown_title_changed.connect(_on_crown_title_changed_refresh_hero_stats)
	_ensure_pc_input_map()


func _on_crown_title_changed_refresh_hero_stats(_idx: int, _title_name: String) -> void:
	var p := current_scene_player
	if p != null and p.has_method("apply_hero_stat_bonuses_from_save"):
		p.apply_hero_stat_bonuses_from_save()


func _ensure_pc_input_map() -> void:
	var pairs: Array = [
		["move_up", KEY_W],
		["move_down", KEY_S],
		["move_left", KEY_A],
		["move_right", KEY_D],
	]
	for pair in pairs:
		var action: String = pair[0]
		var keycode: int = pair[1]
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		if InputMap.action_get_events(action).is_empty():
			var k := InputEventKey.new()
			k.keycode = keycode
			InputMap.action_add_event(action, k)
	if not InputMap.has_action("toggle_debug_menu"):
		InputMap.add_action("toggle_debug_menu")
	if InputMap.action_get_events("toggle_debug_menu").is_empty():
		var k2 := InputEventKey.new()
		k2.keycode = KEY_F3
		InputMap.action_add_event("toggle_debug_menu", k2)
	if not InputMap.has_action("debug_full_health"):
		InputMap.add_action("debug_full_health")
	if InputMap.action_get_events("debug_full_health").is_empty():
		var kh := InputEventKey.new()
		kh.keycode = KEY_H
		InputMap.action_add_event("debug_full_health", kh)


func _input(event: InputEvent) -> void:
	if not event.is_action_pressed("debug_full_health"):
		return
	var p: Node = _find_player_node_in_current_scene()
	if p != null and p.has_method("fill_health_to_max_persistent"):
		p.fill_health_to_max_persistent()
	get_viewport().set_input_as_handled()


var _archer_scene: PackedScene
var _lancer_scene: PackedScene
var _pawn_scene: PackedScene
var _youth_worker_scene: PackedScene

## Полноэкранная заглушка на 1 кадр между сменой сцены и спавном героя: иначе виден мир с «камерой по умолчанию» в (0,0), не там где resume/spawn.
var _scene_transition_blocker_layer: CanvasLayer = null

## Уже в памяти при старте: нет подвисания на load() при первом «Новая игра».
const BASE_SCENE_PACKED: PackedScene = preload("res://Game/Game_base_islad.tscn")
const PLAYER_SCENE_PACKED: PackedScene = preload("res://ally/player/scenes/worrier_base.tscn")


func _get_player_scene() -> PackedScene:
	return PLAYER_SCENE_PACKED

const ARCHER_SPAWN_SPACING := 80.0
const ARCHER_MIN_SPAWN_SEPARATION := 72.0

const _GROUND_TILE_LAYER_NAMES := ["floor_0", "floor_1", "floor_2", "bridge", "steps"]
const _ARCHER_LAND_SEARCH_RADIUS_CELLS := 48
## Если зона спавна отряда покрывает слишком много тайлов — полный перебор клеток подвисает игру.
const _MAX_SQUAD_ZONE_TILES := 12000

func _get_archer_scene() -> PackedScene:
	if _archer_scene == null:
		_archer_scene = load("res://ally/archer/arche_baser.tscn") as PackedScene
	return _archer_scene


func _get_lancer_scene() -> PackedScene:
	if _lancer_scene == null:
		_lancer_scene = load("res://ally/lancer/scenes/lancer_base.tscn") as PackedScene
	return _lancer_scene


func _get_pawn_scene() -> PackedScene:
	if _pawn_scene == null:
		_pawn_scene = load("res://ally/pawn/scenes/pawn_base.tscn") as PackedScene
	return _pawn_scene


func _get_youth_worker_companion_scene() -> PackedScene:
	if _youth_worker_scene == null:
		_youth_worker_scene = load("res://ally/youth_worker/youth_worker_companion.tscn") as PackedScene
	return _youth_worker_scene


func _find_boat_tilemap_layer(node: Node) -> TileMapLayer:
	if node is TileMapLayer and node.name == "boat":
		return node as TileMapLayer
	for c in node.get_children():
		var found := _find_boat_tilemap_layer(c)
		if found:
			return found
	return null


## Центр занятых тайлов слоя «boat» в мировых координатах (среднее, если тайлов несколько).
func get_boat_tile_center_global(scene_root: Node) -> Vector2:
	var boat := _find_boat_tilemap_layer(scene_root)
	if boat == null or boat.tile_set == null:
		return Vector2.ZERO
	var cells := boat.get_used_cells()
	if cells.is_empty():
		return Vector2.ZERO
	var ts := boat.tile_set.tile_size
	var acc := Vector2.ZERO
	for cell in cells:
		var local := boat.map_to_local(cell) + Vector2(ts) * 0.5
		acc += boat.to_global(local)
	return acc / float(cells.size())


func _spawn_point_clear(pos: Vector2, avoid: Array[Vector2], min_dist: float) -> bool:
	for p in avoid:
		if pos.distance_to(p) < min_dist:
			return false
	return true

func _collision_shape_global_rect(cs: CollisionShape2D) -> Rect2:
	var shape = cs.shape
	if shape is RectangleShape2D:
		var rs := shape as RectangleShape2D
		var half := rs.size * 0.5
		var corners: Array[Vector2] = [
			Vector2(-half.x, -half.y),
			Vector2(half.x, -half.y),
			Vector2(half.x, half.y),
			Vector2(-half.x, half.y),
		]
		var min_v: Vector2
		var max_v: Vector2
		var first := true
		for c in corners:
			var g: Vector2 = cs.global_transform * c
			if first:
				min_v = g
				max_v = g
				first = false
			else:
				min_v = Vector2(mini(min_v.x, g.x), mini(min_v.y, g.y))
				max_v = Vector2(maxi(max_v.x, g.x), maxi(max_v.y, g.y))
		return Rect2(min_v, max_v - min_v)
	return Rect2()

func get_squad_spawn_zone_global_rect(scene_root: Node) -> Rect2:
	var zones := scene_root.get_tree().get_nodes_in_group("squad_spawn_zone")
	if zones.is_empty():
		return Rect2()
	var zone := zones[0] as Area2D
	if zone == null:
		return Rect2()
	var cs := zone.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if cs == null:
		return Rect2()
	return _collision_shape_global_rect(cs)

func _world_centers_on_land_in_rect(scene_root: Node, floor_ref: TileMapLayer, global_rect: Rect2) -> Array[Vector2]:
	var out: Array[Vector2] = []
	var corners: Array[Vector2] = [
		global_rect.position,
		global_rect.position + Vector2(global_rect.size.x, 0),
		global_rect.position + global_rect.size,
		global_rect.position + Vector2(0, global_rect.size.y),
	]
	var min_x: int = 2147483647
	var max_x: int = -2147483648
	var min_y: int = 2147483647
	var max_y: int = -2147483648
	for pt in corners:
		var mc := floor_ref.local_to_map(floor_ref.to_local(pt))
		min_x = mini(min_x, mc.x)
		max_x = maxi(max_x, mc.x)
		min_y = mini(min_y, mc.y)
		max_y = maxi(max_y, mc.y)
	var span_x: int = max_x - min_x + 3
	var span_y: int = max_y - min_y + 3
	if span_x > 0 and span_y > 0 and span_x * span_y > _MAX_SQUAD_ZONE_TILES:
		return out
	for x in range(min_x - 1, max_x + 2):
		for y in range(min_y - 1, max_y + 2):
			var c := Vector2i(x, y)
			var wc := _world_center_for_tile(floor_ref, c)
			if not global_rect.has_point(wc):
				continue
			if not _has_ground_tile_at_world(scene_root, wc):
				continue
			out.append(wc)
	return out

func pick_archer_spawn_positions(scene_root: Node, count: int, avoid: Array[Vector2], min_sep: float = ARCHER_MIN_SPAWN_SEPARATION) -> Array[Vector2]:
	var out: Array[Vector2] = []
	var floor_ref := scene_root.find_child("floor_0", true, false) as TileMapLayer
	if floor_ref == null or floor_ref.tile_set == null:
		return _pick_archer_spawn_fallback(scene_root, count, avoid, min_sep)
	var zone_rect := get_squad_spawn_zone_global_rect(scene_root)
	var seed := avoid[0] if not avoid.is_empty() else Vector2.ZERO
	if zone_rect.size.x > 0.0 and zone_rect.size.y > 0.0:
		var candidates := _world_centers_on_land_in_rect(scene_root, floor_ref, zone_rect)
		if candidates.is_empty() and count > 0:
			return _pick_archer_spawn_fallback(scene_root, count, avoid, min_sep)
		var center := zone_rect.get_center()
		candidates.sort_custom(func(a: Vector2, b: Vector2) -> bool:
			return a.distance_squared_to(center) < b.distance_squared_to(center))
		for pos in candidates:
			if out.size() >= count:
				break
			if _spawn_point_clear(pos, avoid + out, min_sep):
				out.append(pos)
	if out.size() < count:
		var fill_from := zone_rect.get_center() if zone_rect.size.x > 0.0 and zone_rect.size.y > 0.0 else seed
		while out.size() < count:
			var idx := out.size()
			var attempt := find_archer_spawn_on_land(scene_root, fill_from + Vector2(idx * 32.0, 0.0), avoid + out, min_sep)
			out.append(attempt)
	return out

func _pick_archer_spawn_fallback(scene_root: Node, count: int, avoid: Array[Vector2], min_sep: float) -> Array[Vector2]:
	var out: Array[Vector2] = []
	var seed := avoid[0] if not avoid.is_empty() else Vector2.ZERO
	for i in range(count):
		out.append(find_archer_spawn_on_land(scene_root, seed + Vector2(i * ARCHER_SPAWN_SPACING, 0.0), avoid + out, min_sep))
	return out

func _world_center_for_tile(layer: TileMapLayer, map_coords: Vector2i) -> Vector2:
	var ts: Vector2i = layer.tile_set.tile_size
	var local := layer.map_to_local(map_coords) + Vector2(ts) * 0.5
	return layer.to_global(local)

func _has_ground_tile_at_world(scene_root: Node, world_pos: Vector2) -> bool:
	for layer_name in _GROUND_TILE_LAYER_NAMES:
		var layer := scene_root.find_child(layer_name, true, false) as TileMapLayer
		if layer == null or layer.tile_set == null:
			continue
		var map_coords := layer.local_to_map(layer.to_local(world_pos))
		if layer.get_cell_source_id(map_coords) != -1:
			return true
	return false

func find_archer_spawn_on_land(scene_root: Node, desired_global: Vector2, avoid_positions: Array[Vector2] = [], min_separation: float = ARCHER_MIN_SPAWN_SEPARATION) -> Vector2:
	var floor_ref := scene_root.find_child("floor_0", true, false) as TileMapLayer
	if floor_ref == null or floor_ref.tile_set == null:
		return desired_global
	var center_cell := floor_ref.local_to_map(floor_ref.to_local(desired_global))
	for r in range(_ARCHER_LAND_SEARCH_RADIUS_CELLS + 1):
		for dx in range(-r, r + 1):
			for dy in range(-r, r + 1):
				if maxi(abs(dx), abs(dy)) != r:
					continue
				var c := center_cell + Vector2i(dx, dy)
				var world_center := _world_center_for_tile(floor_ref, c)
				if not _has_ground_tile_at_world(scene_root, world_center):
					continue
				if avoid_positions.is_empty() or _spawn_point_clear(world_center, avoid_positions, min_separation):
					return world_center
	return desired_global

const _LOCATION_SCENE_PATHS := {
	Events.LOCATION.BASE: "res://Game/Game_base_islad.tscn",
	Events.LOCATION.LVL1: "res://Game/Game_level_1.tscn",
	Events.LOCATION.LVL2: "res://Game/Game_level_2.tscn",
	Events.LOCATION.LVL3: "res://Game/Game_level_3.tscn",
	Events.LOCATION.LVL4: "res://Game/Game_level_4.tscn",
	Events.LOCATION.LVL5: "res://Game/Game_level_5.tscn",
	Events.LOCATION.MENU: "res://Game/Game_menu.tscn",
}

var _location_scene_cache: Dictionary = {}


func _get_location_scene(loc: Events.LOCATION) -> Variant:
	if loc == Events.LOCATION.BASE:
		return BASE_SCENE_PACKED
	if _location_scene_cache.has(loc):
		return _location_scene_cache[loc]
	var path: String = _LOCATION_SCENE_PATHS.get(loc, "") as String
	if path.is_empty():
		return null
	var scene: PackedScene = load(path) as PackedScene
	_location_scene_cache[loc] = scene
	return scene


## Сюжетный доступ к телепорту на остров 5 (отказ от цепочки / финал / повтор после зачистки).
func can_access_last_island_lv5() -> bool:
	if StoryState.has_flag("hero_chose_refuse_chain"):
		return false
	if StoryState.has_flag("hero_chose_finish_chain") and StoryState.has_flag("truth_and_choice_done"):
		return true
	if StoryState.has_flag("story_island_5_cleared"):
		return true
	return false


## Разрешён ли телепорт на локацию из меню (последовательное открытие островов после боссов; база всегда).
func can_teleport_to_location(loc: Events.LOCATION) -> bool:
	match loc:
		Events.LOCATION.BASE:
			return true
		Events.LOCATION.LVL1:
			return true
		Events.LOCATION.LVL2:
			return StoryState.has_flag("story_island_1_cleared")
		Events.LOCATION.LVL3:
			return StoryState.has_flag("story_island_2_cleared")
		Events.LOCATION.LVL4:
			return StoryState.has_flag("story_island_3_cleared")
		Events.LOCATION.LVL5:
			if not StoryState.has_flag("story_island_4_cleared"):
				return false
			return can_access_last_island_lv5()
		_:
			return true


func handle_location_changed(new_location: Events.LOCATION):
	## DialogueWindow живёт в HUD текущей сцены; при change_scene корутины await ломаются (data.tree null),
	## а DialogueManager остаётся с активным диалогом — _player_input_frozen() блокирует движение навсегда.
	if DialogueManager.is_active():
		DialogueManager.end_dialogue()
	## Телепорт/меню зданий/squad_orders и т.д. ставят get_tree().paused = true без DialogueManager;
	## при смене сцены (смерть → меню → продолжить) hide_* не вызывается — пауза остаётся, герой не обрабатывается.
	## Сюжет юноши: paused=true перед диалогом смерти — при уходе со сцены до конца реплики то же самое.
	get_tree().paused = false
	if new_location == Events.LOCATION.MENU:
		PostFinaleWorld.reset_state_for_main_menu()
	var prev_location := Events.current_location
	var expedition_return_count_incremented := false

	# Выход в меню (HUD): сохраняем сцену и позицию героя; герой в меню не создаётся — только UI.
	# После смерти resume уже задан (база, зона телепорта, 1 HP) — не перезаписывать.
	if new_location == Events.LOCATION.MENU:
		if SaveManager.death_resume_pending:
			SaveManager.death_resume_pending = false
		else:
			# Сначала текущее состояние (в т.ч. volatile из F3) на диск — иначе load_game перезапишет память старым файлом.
			SaveManager.save_game()
			SaveManager.load_game()
			Events.sync_story_state_from_save()
			Events.gold_changed.emit(SaveManager.gold)
			Events.meat_changed.emit(SaveManager.meat_count)
			Events.wood_changed.emit(SaveManager.wood_count)
			Events.ore_changed.emit(SaveManager.ore_count)
			var player: Node = _find_player_node_in_current_scene()
			if player and player.has_method("sync_from_save"):
				player.sync_from_save()
			if player and is_instance_valid(player) and player.get("health") != null:
				SaveManager.current_health = int(player.get("health"))
				SaveManager.resume_game_location = int(prev_location)
				SaveManager.resume_player_position_x = player.global_position.x
				SaveManager.resume_player_position_y = player.global_position.y
			if Events.is_adventure_location(prev_location):
				Events.was_on_adventure_before_menu = true
				SaveManager.was_on_adventure_before_menu = true
		SaveManager.save_game()

	# Прямой телепорт: база ← остров.
	if new_location == Events.LOCATION.BASE and Events.is_adventure_location(prev_location):
		reset_armory_preparation()
		reset_monastery_preparation()
		reset_archery_preparation()
		_finalize_expedition_losses_snapshot()
		SaveManager.reset_island_chest_progress_after_expedition()
		var _isl_ret := IslandProgress.story_island_index_from_location(prev_location)
		if _isl_ret >= 1:
			IslandProgress.reset_zone_save_for_island_if_boss_alive(_isl_ret)
		SaveManager.expedition_return_count += 1
		expedition_return_count_incremented = true
		Events.pending_healer_dialogue_after_expedition = true
		Events.was_on_adventure_before_menu = false
		SaveManager.was_on_adventure_before_menu = false
		CrownSystem.harvest_mine_on_expedition_return()
		CrownSystem.tick_caravan_on_expedition_return()
		SaveManager.save_game()

	# Главное меню → база («Продолжить»): если до меню были на острове, считаем это возвратом с похода.
	if new_location == Events.LOCATION.BASE and prev_location == Events.LOCATION.MENU:
		if SaveManager.was_on_adventure_before_menu:
			reset_armory_preparation()
			reset_monastery_preparation()
			reset_archery_preparation()
			_finalize_expedition_losses_snapshot()
			SaveManager.reset_island_chest_progress_after_expedition()
			var _isl_menu := IslandProgress.story_island_index_from_location(SaveManager.resume_game_location as Events.LOCATION)
			if _isl_menu >= 1:
				IslandProgress.reset_zone_save_for_island_if_boss_alive(_isl_menu)
			SaveManager.expedition_return_count += 1
			expedition_return_count_incremented = true
			Events.pending_healer_dialogue_after_expedition = true
			Events.was_on_adventure_before_menu = false
			SaveManager.was_on_adventure_before_menu = false
			CrownSystem.harvest_mine_on_expedition_return()
			CrownSystem.tick_caravan_on_expedition_return()
			SaveManager.save_game()

	if prev_location == Events.LOCATION.BASE and Events.is_adventure_location(new_location):
		## Караван у причала нельзя увезти на остров. Если борт ещё ждёт загрузки, при отплытии
		## паромщик отпускает его порожним — как «Отпустить порожним» в замке. Иначе возможны
		## рассинхроны после прерванного диалога прибытия или быстрой смены сцены.
		if SaveManager.caravan_pending:
			CrownSystem.dismiss_caravan_empty()
		CrownSystem.spend_expedition_provisions()
		_capture_expedition_start_snapshot()

	Events.current_location = new_location
	if new_location == Events.LOCATION.BASE:
		PostFinaleWorld.player_movement_locked = false
	if expedition_return_count_incremented and new_location == Events.LOCATION.BASE:
		Events.expedition_returned.emit(SaveManager.expedition_return_count)
	## После выхода из главного меню HUD создаётся заново — один раз синхронизируем счётчики (как при входе в меню).
	if prev_location == Events.LOCATION.MENU and new_location != Events.LOCATION.MENU:
		call_deferred("_emit_hud_save_resource_signals")
	var packed: Variant = _get_location_scene(new_location)
	if packed == null or not (packed is PackedScene):
		push_error("GameManager: no PackedScene for location %s" % new_location)
		return
	if _teleport_should_toggle_world_ambience(prev_location, new_location):
		SaveManager.world_ambience_night = not SaveManager.world_ambience_night
	## Из главного меню: не использовать чёрный экран — оставить сцену меню поверх, пока не заспавнится герой
	## (change_scene_to_packed уничтожил бы корень меню сразу).
	var use_menu_overlay := prev_location == Events.LOCATION.MENU and new_location != Events.LOCATION.MENU
	var hide_world_until_player := new_location != Events.LOCATION.MENU and not use_menu_overlay
	if hide_world_until_player:
		_show_scene_transition_blocker()
	# Старый герой — дочерний узел текущей сцены; change_scene_to_packed освобождает дерево вместе с ним.
	current_scene_player = null
	if use_menu_overlay and get_tree().current_scene != null:
		var overlay: Node = await MenuStartTransition.run_cover()
		var menu_root: Node = get_tree().current_scene
		var new_scene: Node = (packed as PackedScene).instantiate()
		if new_scene == null:
			push_error("GameManager: instantiate failed for location %s" % new_location)
			await MenuStartTransition.run_exit(overlay)
			if hide_world_until_player:
				_hide_scene_transition_blocker()
			return
		var root := get_tree().root
		root.add_child(new_scene)
		get_tree().set_current_scene(new_scene)
		root.move_child(menu_root, -1)
		if is_instance_valid(overlay):
			root.move_child(overlay, -1)
		await get_tree().process_frame
		if get_tree().current_scene == null:
			await get_tree().process_frame
		_finish_player_placement_after_scene_change(new_location)
		menu_root.queue_free()
		await MenuStartTransition.run_exit(overlay)
		if new_location == Events.LOCATION.BASE:
			call_deferred("_apply_pending_healer_dialogue_token_on_base")
			call_deferred("_try_caravan_arrival_dialogue_on_base_ready")
		return
	var err := get_tree().change_scene_to_packed(packed as PackedScene)
	if err != OK:
		push_error("GameManager: change_scene_to_packed failed: %s" % err)
		if hide_world_until_player:
			_hide_scene_transition_blocker()
		return
	# Ожидание кадра: current_scene и дерево должны стабилизироваться (см. godot#86286).
	# Без этого _finish_player_placement часто видел пустую сцену — герой и камера не создавались.
	await get_tree().process_frame
	if get_tree().current_scene == null:
		await get_tree().process_frame
	_finish_player_placement_after_scene_change(new_location)
	if hide_world_until_player:
		_hide_scene_transition_blocker()
	# После загрузки базы монах применяет жетон (см. monk_base).
	if new_location == Events.LOCATION.BASE:
		call_deferred("_apply_pending_healer_dialogue_token_on_base")
		call_deferred("_try_caravan_arrival_dialogue_on_base_ready")


func _try_caravan_arrival_dialogue_on_base_ready() -> void:
	CrownSystem.try_play_caravan_arrival_if_pending()


func _apply_pending_healer_dialogue_token_on_base() -> void:
	get_tree().call_group("healer", "apply_pending_healer_dialogue_token")


func _emit_hud_save_resource_signals() -> void:
	Events.gold_changed.emit(SaveManager.gold)
	Events.meat_changed.emit(SaveManager.meat_count)
	Events.wood_changed.emit(SaveManager.wood_count)
	Events.ore_changed.emit(SaveManager.ore_count)


## Только для ui/debug_menu (F3). Та же запись SaveManager, что и остальной геймплей.
func debug_reset_death_count_to_zero() -> void:
	SaveManager.death_count = 0
	SaveManager.save_game()


func debug_add_hero_speed_bonus(delta: float) -> void:
	SaveManager.hero_speed_bonus += delta
	var p := _find_player_node_in_current_scene()
	if p != null and p.has_method("apply_hero_stat_bonuses_from_save"):
		p.apply_hero_stat_bonuses_from_save()
	SaveManager.save_game()


func debug_apply_progress_reset_like_new_game() -> void:
	SaveManager.reset_data()
	reset_armory_preparation()
	reset_monastery_preparation()
	reset_archery_preparation()
	Events.gold_changed.emit(SaveManager.gold)
	Events.meat_changed.emit(SaveManager.meat_count)
	Events.wood_changed.emit(SaveManager.wood_count)
	Events.ore_changed.emit(SaveManager.ore_count)
	Events.sync_story_state_from_save()
	var p := _find_player_node_in_current_scene()
	if p != null and p.has_method("sync_from_save"):
		p.sync_from_save()
	if p != null and p.has_method("apply_armory_attack_bonus_from_manager"):
		p.apply_armory_attack_bonus_from_manager()


func add_gold(amount: int):
	SaveManager.gold += amount
	Events.gold_changed.emit(SaveManager.gold)
	SaveManager.save_game()
	if amount > 0:
		SoundManager.play_pickup_gold()


## Как add_gold, но без записи на диск (отладка; сбрасывается при смене сцены).
func add_gold_volatile(amount: int) -> void:
	SaveManager.gold += amount
	Events.gold_changed.emit(SaveManager.gold)
	if amount > 0:
		SoundManager.play_pickup_gold()


## draw_under_node: если задан (например умирающий враг), подбор вставляется в того же родителя
## раньше по списку детей — рисуется под ним (анимация смерти поверх монет).
func spawn_gold_pickup_at(world_pos: Vector2, amount: int, draw_under_node: Node2D = null) -> void:
	call_deferred("_spawn_gold_pickup_at_impl", world_pos, amount, draw_under_node)


func _spawn_gold_pickup_at_impl(world_pos: Vector2, amount: int, draw_under_node: Node2D) -> void:
	var scene_root: Node = get_tree().current_scene
	if scene_root == null:
		return
	var p: Node = GOLD_PICKUP_SCENE.instantiate()
	if p == null:
		return
	p.set("gold_amount", maxi(0, amount))
	var parent: Node = scene_root
	var insert_index: int = -1
	if draw_under_node != null and is_instance_valid(draw_under_node) and draw_under_node.get_parent() != null:
		parent = draw_under_node.get_parent()
		insert_index = draw_under_node.get_index()
	parent.add_child(p)
	if insert_index >= 0:
		parent.move_child(p, insert_index)
	if p is Node2D:
		(p as Node2D).global_position = world_pos + Vector2(0, -14)


func spawn_meat_pickup_at(world_pos: Vector2, amount: int, draw_under_node: Node2D = null) -> void:
	call_deferred("_spawn_meat_pickup_at_impl", world_pos, amount, draw_under_node)


func _spawn_meat_pickup_at_impl(world_pos: Vector2, amount: int, draw_under_node: Node2D) -> void:
	var scene_root: Node = get_tree().current_scene
	if scene_root == null:
		return
	var p: Node = MEAT_PICKUP_SCENE.instantiate()
	if p == null:
		return
	p.set("meat_amount", maxi(0, amount))
	var parent: Node = scene_root
	var insert_index: int = -1
	if draw_under_node != null and is_instance_valid(draw_under_node) and draw_under_node.get_parent() != null:
		parent = draw_under_node.get_parent()
		insert_index = draw_under_node.get_index()
	parent.add_child(p)
	if insert_index >= 0:
		parent.move_child(p, insert_index)
	if p is Node2D:
		(p as Node2D).global_position = world_pos + Vector2(0, -14)


func spawn_wood_pickup_at(world_pos: Vector2, amount: int, draw_under_node: Node2D = null) -> void:
	call_deferred("_spawn_wood_pickup_at_impl", world_pos, amount, draw_under_node)


func _spawn_wood_pickup_at_impl(world_pos: Vector2, amount: int, draw_under_node: Node2D) -> void:
	var scene_root: Node = get_tree().current_scene
	if scene_root == null:
		return
	var p: Node = WOOD_PICKUP_SCENE.instantiate()
	if p == null:
		return
	p.set("wood_amount", maxi(0, amount))
	var parent: Node = scene_root
	var insert_index: int = -1
	if draw_under_node != null and is_instance_valid(draw_under_node) and draw_under_node.get_parent() != null:
		parent = draw_under_node.get_parent()
		insert_index = draw_under_node.get_index()
	parent.add_child(p)
	if insert_index >= 0:
		parent.move_child(p, insert_index)
	if p is Node2D:
		(p as Node2D).global_position = world_pos + Vector2(0, -14)


func spawn_ore_pickup_at(world_pos: Vector2, amount: int, draw_under_node: Node2D = null) -> void:
	call_deferred("_spawn_ore_pickup_at_impl", world_pos, amount, draw_under_node)


func _spawn_ore_pickup_at_impl(world_pos: Vector2, amount: int, draw_under_node: Node2D) -> void:
	var scene_root: Node = get_tree().current_scene
	if scene_root == null:
		return
	var p: Node = ORE_PICKUP_SCENE.instantiate()
	if p == null:
		return
	p.set("ore_amount", maxi(0, amount))
	var parent: Node = scene_root
	var insert_index: int = -1
	if draw_under_node != null and is_instance_valid(draw_under_node) and draw_under_node.get_parent() != null:
		parent = draw_under_node.get_parent()
		insert_index = draw_under_node.get_index()
	parent.add_child(p)
	if insert_index >= 0:
		parent.move_child(p, insert_index)
	if p is Node2D:
		(p as Node2D).global_position = world_pos + Vector2(0, -14)


## Осколки сердцевины после босса острова (story_island 1..5). Не режутся лимитом руды за поход.
func spawn_boss_ore_sparks_at(world_pos: Vector2, story_island: int, draw_under_node: Node2D = null) -> void:
	var count := BalanceConfig.get_boss_defeat_ore_spark_count(story_island)
	spawn_boss_ore_sparks_count_at(world_pos, count, draw_under_node)


## То же, что после босса (`boss_ore_spark`), но явное число осколков — например доля за очистку зоны у сундуков.
func spawn_boss_ore_sparks_count_at(world_pos: Vector2, spark_count: int, draw_under_node: Node2D = null) -> void:
	call_deferred("_spawn_boss_ore_sparks_count_impl", world_pos, spark_count, draw_under_node)


func _spawn_boss_ore_sparks_count_impl(world_pos: Vector2, spark_count: int, draw_under_node: Node2D) -> void:
	if spark_count <= 0:
		return
	var scene_root: Node = get_tree().current_scene
	if scene_root == null:
		return
	var parent: Node = scene_root
	var insert_index: int = -1
	if draw_under_node != null and is_instance_valid(draw_under_node) and draw_under_node.get_parent() != null:
		parent = draw_under_node.get_parent()
		insert_index = draw_under_node.get_index()
	for _spark_idx in range(spark_count):
		var spark: Node = BOSS_ORE_SPARK_SCENE.instantiate()
		if spark == null:
			continue
		parent.add_child(spark)
		if insert_index >= 0:
			parent.move_child(spark, insert_index)
		var ang := randf() * TAU
		var rad := randf_range(32.0, 128.0)
		var off := Vector2(cos(ang), sin(ang)) * rad
		if spark is Node2D:
			(spark as Node2D).global_position = world_pos + off + Vector2(0, -10)


## Максимум лучников + копейщиков по запасу мяса.
func get_max_warriors_allowed() -> int:
	return maxi(0, SaveManager.meat_count)


## Текущий размер отряда (сохранённые слоты + живой сюжетный юноша на базе, не в походе).
func get_squad_member_count() -> int:
	var n: int = SaveManager.archer_count + SaveManager.lancer_count + SaveManager.pawn_count
	if not StoryState.has_flag("worker_youth_dead"):
		if StoryState.has_flag("worker_youth_recruited") or StoryState.has_flag("worker_youth_works_on_base"):
			n += 1
	return n


func add_meat(amount: int) -> void:
	SaveManager.meat_count = maxi(0, SaveManager.meat_count + amount)
	Events.meat_changed.emit(SaveManager.meat_count)
	SaveManager.save_game()


func add_meat_volatile(amount: int) -> void:
	SaveManager.meat_count = maxi(0, SaveManager.meat_count + amount)
	Events.meat_changed.emit(SaveManager.meat_count)


func add_wood(amount: int) -> void:
	SaveManager.wood_count = maxi(0, SaveManager.wood_count + amount)
	Events.wood_changed.emit(SaveManager.wood_count)
	SaveManager.save_game()


func add_wood_volatile(amount: int) -> void:
	SaveManager.wood_count = maxi(0, SaveManager.wood_count + amount)
	Events.wood_changed.emit(SaveManager.wood_count)


func add_ore(amount: int) -> void:
	SaveManager.ore_count = maxi(0, SaveManager.ore_count + amount)
	Events.ore_changed.emit(SaveManager.ore_count)
	SaveManager.save_game()


func add_ore_volatile(amount: int) -> void:
	SaveManager.ore_count = maxi(0, SaveManager.ore_count + amount)
	Events.ore_changed.emit(SaveManager.ore_count)


func register_enemy_kill_for_playtest() -> void:
	playtest_kills_since_level_up += 1


func playtest_report_level_up(levels_gained: int) -> void:
	if not OS.is_debug_build() or levels_gained <= 0:
		return
	var k := playtest_kills_since_level_up
	playtest_kills_since_level_up = 0
	if levels_gained == 1:
		print("[Balance] Level up | kills since last level: ", k)
	else:
		var per := float(k) / float(levels_gained)
		print("[Balance] Level up x", levels_gained, " | kills in batch: ", k, " (~", snappedf(per, 0.1), " per level)")


func add_exp(amount: int) -> void:
	## Не вызывать gain_exp/level_up в том же стеке, что смерть врага от удара: иначе внутри
	## animation_finished атаки подменяется sprite_frames героя — нестабильно и краш AnimatedSprite2D (часто на мобильных).
	call_deferred("_deferred_apply_exp_to_player", amount, true)


func add_exp_volatile(amount: int) -> void:
	call_deferred("_deferred_apply_exp_to_player", amount, false)


func _deferred_apply_exp_to_player(amount: int, persist: bool) -> void:
	var player: Node = _find_player_node_in_current_scene()
	if player == null or not is_instance_valid(player) or not player.has_method("gain_exp"):
		return
	player.gain_exp(amount, persist)


func _resolve_spawn_position(scene: Node) -> Variant:
	if scene == null:
		return null
	var boat_pos := get_boat_tile_center_global(scene)
	if boat_pos != Vector2.ZERO:
		return boat_pos
	if scene.has_method("get_spawn_position"):
		var sp: Variant = scene.call("get_spawn_position")
		if sp is Vector2:
			return sp
	var v: Variant = scene.get("spawn_position")
	if v is Vector2:
		return v
	return null


func _find_player_node_in_current_scene() -> Node:
	var scene_root: Node = get_tree().current_scene
	if scene_root == null:
		return null
	for p in get_tree().get_nodes_in_group("player"):
		if p and is_instance_valid(p) and scene_root.is_ancestor_of(p):
			return p
	return null


func _finish_player_placement_after_scene_change(location: Events.LOCATION) -> void:
	var new_scene: Node = get_tree().current_scene
	if not new_scene:
		return
	
	if location == Events.LOCATION.MENU:
		return
	
	var ps: PackedScene = _get_player_scene()
	if ps == null:
		push_error("GameManager: missing player PackedScene")
		return
	current_scene_player = ps.instantiate() as Node
	if current_scene_player == null:
		return
	new_scene.add_child(current_scene_player)
	if current_scene_player.has_method("sync_from_save"):
		current_scene_player.sync_from_save()
	current_scene_player.visible = true
	current_scene_player.process_mode = Node.PROCESS_MODE_INHERIT
		
	if SaveManager.apply_resume_position_on_next_scene and int(location) == SaveManager.resume_game_location:
		current_scene_player.global_position = Vector2(SaveManager.resume_player_position_x, SaveManager.resume_player_position_y)
		SaveManager.apply_resume_position_on_next_scene = false
	else:
		var sp: Variant = _resolve_spawn_position(new_scene)
		if sp is Vector2:
			current_scene_player.global_position = sp as Vector2
		
	add_camera_to_player(current_scene_player)
		
	if current_scene_player.has_method("gain_exp"):
		current_scene_player.health = SaveManager.current_health
	if current_scene_player.has_method("reset_after_death_resume"):
		current_scene_player.reset_after_death_resume()
		
	_spawn_saved_archers(new_scene)
		
	SaveManager.resume_game_location = int(location)
	SaveManager.resume_player_position_x = current_scene_player.global_position.x
	SaveManager.resume_player_position_y = current_scene_player.global_position.y
	SaveManager.save_game()
	## После смены сцены снова применить FPS/физику/Y-sort (раньше только deferred при load — первые кадры могли быть «не те»).
	SaveManager.apply_window_and_engine_settings()
	PostFinaleWorld.apply_after_scene_loaded()
	_apply_world_ambience_layer(new_scene)

func _spawn_saved_archers(root: Node) -> void:
	if not current_scene_player or not is_instance_valid(current_scene_player):
		return
	var na: int = SaveManager.archer_count
	var nl: int = SaveManager.lancer_count
	var np: int = SaveManager.pawn_count
	## Рудокопы остаются только на базовом острове, в поход не переходят.
	if Events.current_location != Events.LOCATION.BASE:
		np = 0
	var ny: int = 0
	if not StoryState.has_flag("worker_youth_dead"):
		if Events.current_location == Events.LOCATION.BASE:
			if StoryState.has_flag("worker_youth_recruited") or StoryState.has_flag("worker_youth_works_on_base"):
				ny = 1
		else:
			## В поход — только если взят в отряд; «только работник базы» на островах не появляется.
			if StoryState.has_flag("worker_youth_recruited"):
				ny = 1
	var skip_youth_spawn := ny > 0 and _has_story_youth_under_scene(root)
	var effective_youth := 0 if skip_youth_spawn else ny
	var total: int = na + nl + np + effective_youth
	if total <= 0:
		return
	var base_pos: Vector2 = current_scene_player.global_position
	var avoid: Array[Vector2] = [base_pos]
	var positions := pick_archer_spawn_positions(root, total, avoid, ARCHER_MIN_SPAWN_SEPARATION)
	var archer_scene := _get_archer_scene()
	var lancer_scene := _get_lancer_scene()
	var pawn_scene := _get_pawn_scene()
	for i in range(na):
		if archer_scene == null:
			break
		var archer := archer_scene.instantiate() as Node2D
		if not archer:
			continue
		root.add_child(archer)
		if archer.has_method("apply_building_progression_from_manager"):
			archer.apply_building_progression_from_manager()
		if archer.has_method("apply_archery_modifiers_from_manager"):
			archer.apply_archery_modifiers_from_manager()
		if i < positions.size():
			archer.global_position = positions[i]
		archer.add_to_group("squad_member")
	for j in range(nl):
		if lancer_scene == null:
			break
		var lancer := lancer_scene.instantiate() as Node2D
		if not lancer:
			continue
		root.add_child(lancer)
		if lancer.has_method("apply_building_progression_from_manager"):
			lancer.apply_building_progression_from_manager()
		var idx: int = na + j
		if idx < positions.size():
			lancer.global_position = positions[idx]
		lancer.add_to_group("squad_member")
	for k in range(np):
		if pawn_scene == null:
			break
		var pawn := pawn_scene.instantiate() as Node2D
		if not pawn:
			continue
		root.add_child(pawn)
		if pawn.has_method("apply_building_progression_from_manager"):
			pawn.apply_building_progression_from_manager()
		var idx2: int = na + nl + k
		if idx2 < positions.size():
			pawn.global_position = positions[idx2]
		pawn.add_to_group("squad_member")
	if ny > 0 and not skip_youth_spawn:
		var yscene := _get_youth_worker_companion_scene()
		if yscene:
			var yw := yscene.instantiate() as Node2D
			if yw:
				root.add_child(yw)
				var idx_y: int = na + nl + np
				if idx_y < positions.size():
					yw.global_position = positions[idx_y]
				yw.add_to_group("squad_member")


func _has_story_youth_under_scene(root: Node) -> bool:
	for n in get_tree().get_nodes_in_group("story_youth_companion"):
		if is_instance_valid(n) and (n as Node).is_inside_tree() and root.is_ancestor_of(n as Node):
			return true
	return false


## После диалога без смены сцены: создать юношу на базе, если флаг уже есть, а юнита в дереве нет.
func ensure_youth_companion_on_base_scene() -> void:
	if Events.current_location != Events.LOCATION.BASE:
		return
	if StoryState.has_flag("worker_youth_dead"):
		return
	if not StoryState.has_flag("worker_youth_recruited") and not StoryState.has_flag("worker_youth_works_on_base"):
		return
	var root: Node = get_tree().current_scene
	if root == null:
		return
	if _has_story_youth_under_scene(root):
		return
	var player := current_scene_player
	if player == null or not is_instance_valid(player):
		player = _find_player_node_in_current_scene()
	if player == null:
		return
	var yscene := _get_youth_worker_companion_scene()
	if yscene == null:
		return
	var yw := yscene.instantiate() as Node2D
	if yw == null:
		return
	var avoid: Array[Vector2] = [player.global_position]
	for node in get_tree().get_nodes_in_group("ally"):
		if node is Node2D:
			avoid.append((node as Node2D).global_position)
	var positions := pick_archer_spawn_positions(root, 1, avoid, ARCHER_MIN_SPAWN_SEPARATION)
	root.add_child(yw)
	yw.add_to_group("squad_member")
	if positions.size() > 0:
		yw.global_position = positions[0]
	else:
		yw.global_position = player.global_position + Vector2(88.0, 0.0)


func _teleport_should_toggle_world_ambience(prev_loc: Events.LOCATION, nxt_loc: Events.LOCATION) -> bool:
	if prev_loc == nxt_loc:
		return false
	if prev_loc == Events.LOCATION.MENU or nxt_loc == Events.LOCATION.MENU:
		return false
	return true


## Полупрозрачный «ночной» тинт на игровой сцене (слой под HUD layer=5), без анимаций при загрузке.
func _apply_world_ambience_layer(scene_root: Node) -> void:
	if scene_root == null or not is_instance_valid(scene_root):
		return
	var old_layer: Node = scene_root.get_node_or_null("WorldAmbienceLayer")
	if old_layer != null:
		old_layer.queue_free()
	if not SaveManager.world_ambience_night:
		return
	var canvas := CanvasLayer.new()
	canvas.name = "WorldAmbienceLayer"
	canvas.layer = 4
	var rect := ColorRect.new()
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.color = Color(0.065, 0.085, 0.2, 0.52)
	canvas.add_child(rect)
	scene_root.add_child(canvas)


func _show_scene_transition_blocker() -> void:
	if _scene_transition_blocker_layer != null and is_instance_valid(_scene_transition_blocker_layer):
		return
	var layer := CanvasLayer.new()
	layer.layer = 1000
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	var rect := ColorRect.new()
	rect.color = Color.BLACK
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(rect)
	get_tree().root.add_child(layer)
	_scene_transition_blocker_layer = layer


func _hide_scene_transition_blocker() -> void:
	if _scene_transition_blocker_layer != null and is_instance_valid(_scene_transition_blocker_layer):
		_scene_transition_blocker_layer.queue_free()
	_scene_transition_blocker_layer = null


func add_camera_to_player(player: Node) -> void:
	var cam := player.get_node_or_null("Camera2D") as Camera2D
	if cam == null:
		cam = Camera2D.new()
		cam.name = "Camera2D"
		player.add_child(cam)
	cam.enabled = true
	cam.make_current()
	if cam.position_smoothing_enabled:
		cam.reset_smoothing()

func boss_kill():
	SaveManager.boss_kill += 1
	SaveManager.save_game()
	SoundManager.notify_adventure_music_progress()


## Сюжетный «остров зачищен» (один раз на остров), не зависит от числа мини-боссов с группой BOSS.
func on_story_island_boss_defeated(island_index: int) -> void:
	if island_index < 1 or island_index > 5:
		return
	var key := "story_island_%d_cleared" % island_index
	if StoryState.has_flag(key):
		return
	StoryState.set_flag(key, true)
	if island_index == 5:
		PostFinaleWorld.on_story_island_5_boss_won()
