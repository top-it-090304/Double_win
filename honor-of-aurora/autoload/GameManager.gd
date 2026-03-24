extends Node

const GOLD_PICKUP_SCENE := preload("res://objects/resource_pickups/gold_pickup.tscn")
const MEAT_PICKUP_SCENE := preload("res://objects/resource_pickups/meat_pickup.tscn")

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


## Уровень оружейной на базе (0 = чёрная текстура … 4 = жёлтая). Влияет только на величину временных бафов.
func get_armory_building_tier() -> int:
	return SaveManager.get_building_tier("Barracks")


## Множитель силы бафа «перед походом» от прокачки здания Barracks.
func get_armory_prep_strength_multiplier() -> float:
	return 1.0 + ARMORY_TIER_BUFF_PER_LEVEL * float(get_armory_building_tier())


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
	if not GameplayFacade.try_spend_gold(BalanceConfig.get_armory_sword_buff_cost()):
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
	if not GameplayFacade.try_spend_gold(BalanceConfig.get_armory_shield_buff_cost()):
		return false
	armory_shield_prepared = true
	var mul := get_armory_prep_strength_multiplier()
	var delta := ARMORY_SHIELD_FACTOR_DELTA * mul
	armory_shield_damage_factor = maxf(ARMORY_SHIELD_FACTOR_MIN, armory_shield_damage_factor - delta)
	return true


func reset_armory_preparation() -> void:
	armory_attack_bonus = 0
	armory_shield_damage_factor = ARMORY_SHIELD_BASE_DAMAGE_FACTOR
	armory_sword_prepared = false
	armory_shield_prepared = false


func _ready() -> void:
	SaveManager.load_game()
	Events.sync_story_state_from_save()
	Events.location_changed.connect(handle_location_changed)

var _archer_scene: PackedScene
var _lancer_scene: PackedScene
var _pawn_scene: PackedScene

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

func handle_location_changed(new_location: Events.LOCATION):
	var prev_location := Events.current_location

	# Выход в меню (HUD): сохраняем сцену и позицию героя; герой в меню не создаётся — только UI.
	# После смерти resume уже задан (база, зона телепорта, 1 HP) — не перезаписывать.
	if new_location == Events.LOCATION.MENU:
		if SaveManager.death_resume_pending:
			SaveManager.death_resume_pending = false
		else:
			var player: Node = _find_player_node_in_current_scene()
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
		SaveManager.expedition_return_count += 1
		Events.pending_healer_dialogue_after_expedition = true
		Events.was_on_adventure_before_menu = false
		SaveManager.was_on_adventure_before_menu = false
		SaveManager.save_game()

	# Главное меню → база («Продолжить»): если до меню были на острове, считаем это возвратом с похода.
	if new_location == Events.LOCATION.BASE and prev_location == Events.LOCATION.MENU:
		if SaveManager.was_on_adventure_before_menu:
			reset_armory_preparation()
			SaveManager.expedition_return_count += 1
			Events.pending_healer_dialogue_after_expedition = true
			Events.was_on_adventure_before_menu = false
			SaveManager.was_on_adventure_before_menu = false
			SaveManager.save_game()

	Events.current_location = new_location
	var packed: Variant = _get_location_scene(new_location)
	if packed == null or not (packed is PackedScene):
		push_error("GameManager: no PackedScene for location %s" % new_location)
		return
	# Старый герой — дочерний узел текущей сцены; change_scene_to_packed освобождает дерево вместе с ним.
	current_scene_player = null
	var err := get_tree().change_scene_to_packed(packed as PackedScene)
	if err != OK:
		push_error("GameManager: change_scene_to_packed failed: %s" % err)
		return
	# Ожидание кадра: current_scene и дерево должны стабилизироваться (см. godot#86286).
	# Без этого _finish_player_placement часто видел пустую сцену — герой и камера не создавались.
	await get_tree().process_frame
	if get_tree().current_scene == null:
		await get_tree().process_frame
	_finish_player_placement_after_scene_change(new_location)
	# После загрузки базы монах применяет жетон (см. monk_base).
	if new_location == Events.LOCATION.BASE:
		call_deferred("_apply_pending_healer_dialogue_token_on_base")


func _apply_pending_healer_dialogue_token_on_base() -> void:
	get_tree().call_group("healer", "apply_pending_healer_dialogue_token")

func add_gold(amount: int):
	SaveManager.gold += amount
	Events.gold_changed.emit(SaveManager.gold)
	SaveManager.save_game()
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


## Максимум лучников + копейщиков по запасу мяса.
func get_max_warriors_allowed() -> int:
	return maxi(0, SaveManager.meat_count)


func add_meat(amount: int) -> void:
	SaveManager.meat_count = maxi(0, SaveManager.meat_count + amount)
	Events.meat_changed.emit(SaveManager.meat_count)
	SaveManager.save_game()


func add_wood(amount: int) -> void:
	SaveManager.wood_count = maxi(0, SaveManager.wood_count + amount)
	Events.wood_changed.emit(SaveManager.wood_count)
	SaveManager.save_game()


func add_ore(amount: int) -> void:
	SaveManager.ore_count = maxi(0, SaveManager.ore_count + amount)
	Events.ore_changed.emit(SaveManager.ore_count)
	SaveManager.save_game()


func add_exp(amount: int) -> void:
	var player: Node = _find_player_node_in_current_scene()
	if player and player.has_method("gain_exp"):
		player.gain_exp(amount)


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

func _spawn_saved_archers(root: Node) -> void:
	if not current_scene_player or not is_instance_valid(current_scene_player):
		return
	var na: int = SaveManager.archer_count
	var nl: int = SaveManager.lancer_count
	var np: int = SaveManager.pawn_count
	## Рудокопы остаются только на базовом острове, в поход не переходят.
	if Events.current_location != Events.LOCATION.BASE:
		np = 0
	var total: int = na + nl + np
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
		var idx2: int = na + nl + k
		if idx2 < positions.size():
			pawn.global_position = positions[idx2]
		pawn.add_to_group("squad_member")

func add_camera_to_player(player: Node) -> void:
	var cam := player.get_node_or_null("Camera2D") as Camera2D
	if cam == null:
		cam = Camera2D.new()
		cam.name = "Camera2D"
		player.add_child(cam)
	cam.enabled = true
	cam.make_current()

func boss_kill():
	SaveManager.boss_kill += 1
	SaveManager.save_game()


## Сюжетный «остров зачищен» (один раз на остров), не зависит от числа мини-боссов с группой BOSS.
func on_story_island_boss_defeated(island_index: int) -> void:
	if island_index < 1 or island_index > 5:
		return
	var key := "story_island_%d_cleared" % island_index
	if StoryState.has_flag(key):
		return
	StoryState.set_flag(key, true)
