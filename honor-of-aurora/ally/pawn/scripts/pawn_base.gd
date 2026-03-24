extends "res://characters/companion_unit.gd"

## Рудокоп на базе: бежит к шахте (камень рядом — молот), к деревьям (топор), к шахте (кирка); не «болтается».
## На острове — нож в бою и короткий «сбор».

enum BaseTaskKind { MINE, TREE, ROCK }

enum BaseTool { PICKAXE, AXE, HAMMER, WOOD }

enum ShiftPhase { COOLDOWN, MOVE, WORK }

## 0 — камень у шахты (молот), 1 — деревья, 2 — забой киркой у шахты.
var _shift_seq: int = 0
var _shift_phase: ShiftPhase = ShiftPhase.COOLDOWN
var _shift_cd: float = 0.0
var _shift_target: Vector2 = Vector2.ZERO
var _shift_move_timer: float = 0.0
var _current_shift_kind: BaseTaskKind = BaseTaskKind.MINE

var _base_visual_tool: BaseTool = BaseTool.PICKAXE
var _base_work_playing: bool = false
var _base_work_site: Vector2 = Vector2.ZERO

var _pawn_cosmetic_busy: bool = false
var _scavenge_cd: float = 0.0

@export var shift_work_reach_px: float = 46.0
@export var shift_move_timeout_sec: float = 11.0
@export var rock_ring_min_px: float = 40.0
@export var rock_ring_max_px: float = 112.0


func _ready() -> void:
	speed = 120.0
	super._ready()
	_shift_cd = randf_range(0.4, 1.6)
	_scavenge_cd = randf_range(5.0, 11.0)
	add_to_group("ally_pawn")


func _capture_base_patrol_spawn_after_placed() -> void:
	super._capture_base_patrol_spawn_after_placed()
	var mc := _get_tilemap_layer_center_by_name(&"mine")
	if mc != Vector2.ZERO:
		_base_patrol_spawn = mc


func _get_tilemap_layer_center_by_name(layer_name: StringName) -> Vector2:
	var scene := get_tree().current_scene
	if scene == null:
		return Vector2.ZERO
	var tm := scene.find_child(String(layer_name), true, false) as TileMapLayer
	if tm == null:
		return Vector2.ZERO
	var cells := tm.get_used_cells()
	if cells.is_empty():
		return Vector2.ZERO
	var ts := Vector2(64, 64)
	if tm.tile_set:
		ts = Vector2(tm.tile_set.tile_size)
	var acc := Vector2.ZERO
	for c in cells:
		var local := tm.map_to_local(c) + ts * 0.5
		acc += tm.to_global(local)
	return acc / float(cells.size())


func _get_marker_global(group: StringName) -> Vector2:
	var n := get_tree().get_first_node_in_group(String(group)) as Node2D
	if n != null and is_instance_valid(n):
		return n.global_position
	return Vector2.ZERO


func _get_site_for_task(kind: BaseTaskKind) -> Vector2:
	match kind:
		BaseTaskKind.MINE:
			return _get_tilemap_layer_center_by_name(&"mine")
		BaseTaskKind.TREE:
			var t := _get_tilemap_layer_center_by_name(&"trees")
			if t != Vector2.ZERO:
				return t
			return _get_marker_global(&"worker_tree_site")
		BaseTaskKind.ROCK:
			var r := _get_tilemap_layer_center_by_name(&"rocks")
			if r != Vector2.ZERO:
				return r
			return _get_marker_global(&"worker_rock_site")
	return Vector2.ZERO


func _rock_spot_near_mine(mine_center: Vector2) -> Vector2:
	var ang := randf() * TAU
	var rad := randf_range(rock_ring_min_px, rock_ring_max_px)
	return mine_center + Vector2(cos(ang), sin(ang)) * rad


func _set_tool_for_task(kind: BaseTaskKind) -> void:
	match kind:
		BaseTaskKind.MINE:
			_base_visual_tool = BaseTool.PICKAXE
		BaseTaskKind.TREE:
			_base_visual_tool = BaseTool.AXE
		BaseTaskKind.ROCK:
			_base_visual_tool = BaseTool.HAMMER


func _interact_anim_for_task(kind: BaseTaskKind) -> StringName:
	match kind:
		BaseTaskKind.MINE:
			return &"interact_pickaxe"
		BaseTaskKind.TREE:
			return &"interact_axe"
		BaseTaskKind.ROCK:
			return &"interact_hammer"
	return &"interact_pickaxe"


func _idle_anim() -> StringName:
	if Events.current_location == Events.LOCATION.BASE:
		match _base_visual_tool:
			BaseTool.AXE:
				return &"idle_axe"
			BaseTool.HAMMER:
				return &"idle_hammer"
			BaseTool.WOOD:
				return &"idle_wood"
			_:
				return &"idle_pickaxe"
	return &"idle_knife"


func _run_anim() -> StringName:
	if Events.current_location == Events.LOCATION.BASE:
		match _base_visual_tool:
			BaseTool.AXE:
				return &"run_axe"
			BaseTool.HAMMER:
				return &"run_hammer"
			BaseTool.WOOD:
				return &"run_wood"
			_:
				return &"run_pickaxe"
	return &"run_knife"


func _get_melee_hit_reach() -> float:
	return 58.0


func _get_melee_hit_radius() -> float:
	return 20.0


func _attack_anim_for_direction(_dir: Vector2) -> StringName:
	return &"interact_knife"


func _interrupt_base_shift() -> void:
	_base_work_playing = false
	_shift_phase = ShiftPhase.COOLDOWN
	_shift_cd = 0.6
	_shift_move_timer = 0.0


func _process_follow_custom(delta: float) -> bool:
	var enemy := _nearest_enemy_in_attack_area()
	if enemy and _attack_cd <= 0.0 and attack_area:
		_interrupt_base_shift()
		_pawn_cosmetic_busy = false
		return false
	if state != State.FOLLOW:
		return false
	if SquadOrders.mode == SquadOrders.Mode.HOLD:
		return false
	if Events.current_location == Events.LOCATION.BASE:
		return _process_base_shift_fsm(delta)
	if Events.is_adventure_location(Events.current_location):
		return _process_island_scavenge(delta)
	return false


func _process_base_shift_fsm(delta: float) -> bool:
	match _shift_phase:
		ShiftPhase.COOLDOWN:
			_shift_cd -= delta
			if _shift_cd > 0.0:
				velocity = Vector2.ZERO
				_base_visual_tool = BaseTool.PICKAXE
				_play_idle()
				return true
			_shift_try_start_move()
			return true
		ShiftPhase.MOVE:
			var to := _shift_target - global_position
			if to.length() <= shift_work_reach_px:
				_shift_begin_work()
				return true
			velocity = to.normalized() * speed
			_face_velocity(velocity)
			_play_run()
			_shift_move_timer += delta
			if _shift_move_timer >= shift_move_timeout_sec:
				_interrupt_base_shift()
				_shift_cd = 2.0
			return true
		ShiftPhase.WORK:
			if _base_work_playing:
				velocity = Vector2.ZERO
				_face_work_site(_base_work_site)
				return true
			velocity = Vector2.ZERO
			_play_idle()
			return true
	return false


func _shift_try_start_move() -> void:
	var mine_center := _get_tilemap_layer_center_by_name(&"mine")
	for k in range(3):
		var slot: int = (_shift_seq + k) % 3
		var kind: BaseTaskKind = BaseTaskKind.MINE
		var target: Vector2 = Vector2.ZERO
		match slot:
			0:
				if mine_center == Vector2.ZERO:
					continue
				kind = BaseTaskKind.ROCK
				target = _rock_spot_near_mine(mine_center)
			1:
				target = _get_site_for_task(BaseTaskKind.TREE)
				if target == Vector2.ZERO:
					continue
				kind = BaseTaskKind.TREE
			2:
				if mine_center == Vector2.ZERO:
					continue
				kind = BaseTaskKind.MINE
				target = mine_center
		_current_shift_kind = kind
		_shift_target = target
		_base_work_site = target
		_set_tool_for_task(kind)
		_shift_phase = ShiftPhase.MOVE
		_shift_move_timer = 0.0
		return
	_shift_phase = ShiftPhase.COOLDOWN
	_shift_cd = 4.0


func _shift_begin_work() -> void:
	var anim := _interact_anim_for_task(_current_shift_kind)
	if sprite == null or sprite.sprite_frames == null or not sprite.sprite_frames.has_animation(anim):
		_interrupt_base_shift()
		_shift_cd = 2.0
		return
	_shift_phase = ShiftPhase.WORK
	_base_work_playing = true
	_base_work_site = _shift_target
	sprite.play(anim)


func _face_work_site(site: Vector2) -> void:
	if site == Vector2.ZERO or sprite == null:
		return
	var dx := site.x - global_position.x
	if absf(dx) > 2.0:
		sprite.flip_h = dx < 0.0


func _process_island_scavenge(delta: float) -> bool:
	if _pawn_cosmetic_busy:
		velocity = Vector2.ZERO
		return true
	_scavenge_cd -= delta
	if _scavenge_cd > 0.0:
		return false
	if player == null or not is_instance_valid(player):
		return false
	if player is CharacterBody2D and (player as CharacterBody2D).velocity.length() > 38.0:
		_scavenge_cd = 2.0
		return false
	if global_position.distance_to(player.global_position) > 230.0:
		_scavenge_cd = 2.5
		return false
	_pawn_cosmetic_busy = true
	_scavenge_cd = randf_range(14.0, 24.0)
	var anims: Array[StringName] = [&"interact_hammer", &"interact_axe", &"interact_pickaxe"]
	var pick: StringName = anims[randi() % anims.size()]
	if sprite and sprite.sprite_frames:
		if sprite.sprite_frames.has_animation(pick):
			sprite.play(pick)
		elif sprite.sprite_frames.has_animation(&"interact_hammer"):
			sprite.play(&"interact_hammer")
		else:
			_pawn_cosmetic_busy = false
			return false
	return true


func _on_sprite_animation_finished() -> void:
	if _pawn_cosmetic_busy:
		_pawn_cosmetic_busy = false
		_play_idle()
		return
	if _base_work_playing:
		_base_work_playing = false
		_shift_seq = (_shift_seq + 1) % 3
		_shift_phase = ShiftPhase.COOLDOWN
		_shift_cd = randf_range(1.2, 2.8)
		_base_visual_tool = BaseTool.PICKAXE
		_base_work_site = Vector2.ZERO
		_play_idle()
		return
	super._on_sprite_animation_finished()
