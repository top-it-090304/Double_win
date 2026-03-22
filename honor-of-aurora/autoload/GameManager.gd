extends Node

var current_scene_player: Node = null

func _ready() -> void:
	SaveManager.load_game()
	Events.sync_story_state_from_save()
	Events.location_changed.connect(handle_location_changed)

const ARCHER_SCENE := preload("res://ally/archer/arche_baser.tscn")
const ARCHER_SPAWN_SPACING := 80.0
const ARCHER_MIN_SPAWN_SEPARATION := 72.0

const _GROUND_TILE_LAYER_NAMES := ["floor_0", "floor_1", "floor_2", "bridge", "steps"]
const _ARCHER_LAND_SEARCH_RADIUS_CELLS := 48

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

const location_to_scene = {
	Events.LOCATION.BASE: preload("res://Game/Game_base_islad.tscn"),
	Events.LOCATION.LVL1: preload("res://Game/Game_level_1.tscn"),
	Events.LOCATION.LVL2: preload("res://Game/Game_level_2.tscn"),
	Events.LOCATION.LVL3: preload("res://Game/Game_level_3.tscn"),
	Events.LOCATION.LVL4: preload("res://Game/Game_level_4.tscn"),
	Events.LOCATION.LVL5: preload("res://Game/Game_level_5.tscn"),
	Events.LOCATION.MENU: preload("res://Game/Game_menu.tscn"),
}

func handle_location_changed(new_location: Events.LOCATION):
	var prev_location := Events.current_location

	# Выход в меню (HUD): сохраняем сцену и позицию героя; персонаж не попадает в сцену меню (см. teleport_player_to_scene).
	# После смерти resume уже задан (база, зона телепорта, 1 HP) — не перезаписывать.
	if new_location == Events.LOCATION.MENU:
		if SaveManager.death_resume_pending:
			SaveManager.death_resume_pending = false
		else:
			var player := get_tree().get_first_node_in_group("player")
			if player and is_instance_valid(player):
				SaveManager.current_health = player.health
				SaveManager.resume_game_location = int(prev_location)
				SaveManager.resume_player_position_x = player.global_position.x
				SaveManager.resume_player_position_y = player.global_position.y
			if Events.is_adventure_location(prev_location):
				Events.was_on_adventure_before_menu = true
				SaveManager.was_on_adventure_before_menu = true
		SaveManager.save_game()

	# Прямой телепорт: база ← остров.
	if new_location == Events.LOCATION.BASE and Events.is_adventure_location(prev_location):
		SaveManager.expedition_return_count += 1
		Events.pending_healer_dialogue_after_expedition = true
		Events.was_on_adventure_before_menu = false
		SaveManager.was_on_adventure_before_menu = false
		SaveManager.save_game()

	# Главное меню → база («Продолжить»): если до меню были на острове, считаем это возвратом с похода.
	if new_location == Events.LOCATION.BASE and prev_location == Events.LOCATION.MENU:
		if SaveManager.was_on_adventure_before_menu:
			SaveManager.expedition_return_count += 1
			Events.pending_healer_dialogue_after_expedition = true
			Events.was_on_adventure_before_menu = false
			SaveManager.was_on_adventure_before_menu = false
			SaveManager.save_game()

	Events.current_location = new_location
	teleport_player_to_scene(new_location)
	get_tree().change_scene_to_packed(location_to_scene.get(new_location))
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


func add_exp(amount: int):
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("gain_exp"):
		player.gain_exp(amount)

func teleport_player_to_scene(location: Events.LOCATION):
	var current_scene = get_tree().current_scene
	var player = get_tree().get_first_node_in_group("player")
	
	if player and is_instance_valid(player):
		var player_parent = player.get_parent()
		if player_parent:
			player_parent.remove_child(player)
		current_scene_player = player
	
	await get_tree().process_frame
	await get_tree().process_frame
	
	var new_scene = get_tree().current_scene
	if not new_scene:
		return
	
	if location == Events.LOCATION.MENU:
		# Герой остаётся под GameManager, не добавляется в сцену меню.
		if current_scene_player and is_instance_valid(current_scene_player):
			add_child(current_scene_player)
			current_scene_player.visible = false
			current_scene_player.process_mode = Node.PROCESS_MODE_DISABLED
			remove_camera_from_player(current_scene_player)
		return
	
	if current_scene_player and is_instance_valid(current_scene_player):
		new_scene.add_child(current_scene_player)
		current_scene_player.visible = true
		current_scene_player.process_mode = Node.PROCESS_MODE_INHERIT
		
		if "spawn_position" in new_scene:
			if SaveManager.apply_resume_position_on_next_scene and int(location) == SaveManager.resume_game_location:
				current_scene_player.global_position = Vector2(SaveManager.resume_player_position_x, SaveManager.resume_player_position_y)
				SaveManager.apply_resume_position_on_next_scene = false
			else:
				current_scene_player.global_position = new_scene.spawn_position
		
		add_camera_to_player(current_scene_player)
		
		if current_scene_player.has_method("set_health") or true:
			current_scene_player.health = SaveManager.current_health
		if current_scene_player.has_method("reset_after_death_resume"):
			current_scene_player.reset_after_death_resume()
		
		_spawn_saved_archers(new_scene)
		
		SaveManager.resume_game_location = int(location)
		SaveManager.resume_player_position_x = current_scene_player.global_position.x
		SaveManager.resume_player_position_y = current_scene_player.global_position.y
		SaveManager.save_game()

func _spawn_saved_archers(root: Node) -> void:
	var n: int = SaveManager.archer_count
	if n <= 0 or not current_scene_player or not is_instance_valid(current_scene_player):
		return
	var base_pos: Vector2 = current_scene_player.global_position
	var avoid: Array[Vector2] = [base_pos]
	var positions := pick_archer_spawn_positions(root, n, avoid, ARCHER_MIN_SPAWN_SEPARATION)
	for i in range(n):
		var archer := ARCHER_SCENE.instantiate() as Node2D
		if not archer:
			continue
		root.add_child(archer)
		if i < positions.size():
			archer.global_position = positions[i]

func add_camera_to_player(player: Node):
	var camera = player.get_node_or_null("Camera2D")
	if not camera:
		camera = Camera2D.new()
		camera.name = "Camera2D"
		player.add_child(camera)
	camera.make_current()

func remove_camera_from_player(player: Node):
	var camera = player.get_node_or_null("Camera2D")
	if camera:
		camera.queue_free()

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
