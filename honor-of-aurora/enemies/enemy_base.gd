extends "res://characters/enemy_unit.gd"
## Базовый враг с патрулем, преследованием и рукопашной атакой.

enum State { PATROL, CHASE, ATTACK, DEATH, HIT, RECOVER, LEASH }
var state: State = State.PATROL

@onready var anim = $AnimatedSprite
@onready var detection_area = $DetectionArea
@onready var attack_area = $AttackArea
@onready var detection_shape = $DetectionArea/DetectionShape
@onready var attack_shape = $AttackArea/AttackShape
## Игровой уровень угрозы: награды и множитель статов (см. BalanceConfig).
@export var enemy_level: int = 1
## Доп. множитель золота/опыта (элита, мини-боссы без группы BOSS).
@export_range(0.25, 8.0, 0.05) var reward_mult: float = 1.0

@export var speed: float = 100.0
@export var attack_damage: int = 10
@export var attack_cooldown: float = 2.0
@export var patrol_change_time: float = 2.0
@export var attack_radius: float = 80.0
@export var detection_radius: float = 500.0

@export var use_navigation: bool = true
@export var leash_radius: float = 1400.0
## Маска для лучей обхода стен (без слоя врагов, чтобы не путать союзников/игрока с геометрией при желании задайте вручную).
@export var wall_probe_collision_mask: int = 30
@export var wall_probe_distance: float = 88.0
## Если >0 и враг в группе BOSS — один раз выставляет сюжетный флаг острова (1..5 = LVL1..LVL5) для boss_post_*.
@export var story_island: int = 0

var target: Node2D = null
var can_attack: bool = true
var last_dir: Vector2 = Vector2.DOWN
var patrol_dir: Vector2
var patrol_timer: float = 0.0
var attack_cooldown_timer: Timer
## Если animation_finished не пришёл (loop=true, баг движка, смена клипа) — не зависать в ATTACK/HIT.
var _anim_safety_timer: Timer
## Урон за один замах атаки применяется один раз (сигнал и таймер не дублируют).
var _attack_damage_applied: bool = false
var potential_targets: Array[Node2D] = []

var home_position: Vector2 = Vector2.ZERO
var encounter_zone: EncounterZone = null

var _nav_agent: NavigationAgent2D
var _stuck_frames: int = 0
var _recover_time: float = 0.0
var _recover_dir: Vector2 = Vector2.RIGHT
var _select_target_cd: float = 0.0

const _SEP_EPS := 1e-3
const _STUCK_THRESHOLD_FRAMES := 14
const _RECOVER_DURATION := 0.38
const _FAN_STEP := PI / 10.0
const _FAN_COUNT := 9
const _SELECT_TARGET_INTERVAL := 0.25
## Запас к радиусу зоны удара: хитбокс цели vs центр AttackArea (см. apply_damage; синхронно slipper_combat_budget._MELEE_EXTRA_REACH_PX).
const _MELEE_EXTRA_REACH_PX := 90.0


func _get_effective_melee_reach_px() -> float:
	var reach: float = attack_radius
	if attack_shape and attack_shape.shape is CircleShape2D:
		reach = (attack_shape.shape as CircleShape2D).radius
	if attack_shape:
		var gs: Vector2 = attack_shape.get_global_transform().get_scale().abs()
		reach *= maxf(gs.x, gs.y)
	return reach


func _aim_point_on_target_body(tgt: Node2D) -> Vector2:
	if tgt == null or not is_instance_valid(tgt):
		return Vector2.ZERO
	var aim: Vector2 = tgt.global_position
	var cs := tgt.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if cs != null and cs.shape != null:
		aim = cs.global_position
	return aim


func _is_target_within_melee_distance(tgt: Node2D) -> bool:
	if attack_area == null or not is_instance_valid(attack_area):
		return false
	var max_d: float = _get_effective_melee_reach_px() + _MELEE_EXTRA_REACH_PX
	var origin: Vector2 = attack_area.global_position
	var aim := _aim_point_on_target_body(tgt)
	return origin.distance_squared_to(aim) <= max_d * max_d


func _refresh_targets_after_leash() -> void:
	for body in detection_area.get_overlapping_bodies():
		if body == null or not is_instance_valid(body):
			continue
		if body is Node2D and (body.is_in_group("player") or body.is_in_group("ally")):
			if potential_targets.find(body) < 0:
				potential_targets.append(body)
	_select_target()
	if target and state == State.PATROL:
		state = State.CHASE


func assign_encounter_zone(zone: EncounterZone, spawn_pos: Vector2, leash: float) -> void:
	encounter_zone = zone
	home_position = spawn_pos
	leash_radius = leash
	set_meta("_encounter_zone_id", zone.zone_id)


func assign_ambient_spawn(spawn_pos: Vector2, leash: float) -> void:
	encounter_zone = null
	home_position = spawn_pos
	leash_radius = leash
	if has_meta("_encounter_zone_id"):
		remove_meta("_encounter_zone_id")


## Вызывается после базового баланса (call_deferred из зоны): приводит enemy_level к уровню острова.
func configure_for_island_tier(tier: int) -> void:
	if tier <= 0:
		return
	var old_lvl := enemy_level
	enemy_level = tier
	var m_old := BalanceConfig.get_enemy_stat_multiplier(old_lvl)
	var m_new := BalanceConfig.get_enemy_stat_multiplier(tier)
	if m_old > 0.0:
		health = maxi(1, int(round(float(health) * m_new / m_old)))
		attack_damage = maxi(1, int(round(float(attack_damage) * m_new / m_old)))
	if health_component:
		health_component.set_max_and_current(health)


func _dir_toward_target(delta_pos: Vector2) -> Vector2:
	if delta_pos.length() > _SEP_EPS:
		return delta_pos.normalized()
	if last_dir.length() > _SEP_EPS:
		return last_dir.normalized()
	return Vector2.RIGHT


func _away_from_target(delta_pos: Vector2) -> Vector2:
	if delta_pos.length() > _SEP_EPS:
		return -delta_pos.normalized()
	if last_dir.length() > _SEP_EPS:
		return -last_dir.normalized()
	if get_slide_collision_count() > 0:
		return get_slide_collision(0).get_normal()
	return Vector2.RIGHT.rotated(randf() * TAU)


func _ready() -> void:
	super._ready()
	if is_in_group(&"BOSS"):
		## Выше, чем у игрока/союзников (дефолт 1.0): при тесном контакте move_and_slide не сдвигает босса.
		collision_priority = 10.0
	detection_shape.shape.radius = detection_radius
	attack_shape.shape.radius = attack_radius

	detection_area.body_entered.connect(_on_detection_area_entered)
	detection_area.body_exited.connect(_on_detection_area_exited)
	attack_area.body_entered.connect(_on_attack_area_entered)
	anim.animation_finished.connect(_on_anim_finished)

	attack_cooldown_timer = Timer.new()
	attack_cooldown_timer.one_shot = true
	attack_cooldown_timer.timeout.connect(_on_attack_cooldown_timeout)
	add_child(attack_cooldown_timer)

	_anim_safety_timer = Timer.new()
	_anim_safety_timer.one_shot = true
	_anim_safety_timer.timeout.connect(_on_anim_safety_timeout)
	add_child(_anim_safety_timer)

	randomize()
	patrol_dir = Vector2.RIGHT.rotated(randf_range(0, TAU))
	home_position = global_position
	call_deferred("_setup_nav_agent")
	call_deferred("_apply_enemy_balance_stats")
	## Дочерние скрипты (bear, troll, …) задают attack_radius/detection_radius после super._ready();
	## без отложенной синхронизации коллайдеры Area2D остаются старыми — босс не попадает в «дистанцию атаки».
	call_deferred("_sync_attack_detection_shape_radii")


func _sync_attack_detection_shape_radii() -> void:
	if not is_instance_valid(self):
		return
	if _should_clamp_melee_attack_radius_to_sprite():
		_clamp_attack_radius_to_sprite_frame()
	if attack_shape and attack_shape.shape is CircleShape2D:
		(attack_shape.shape as CircleShape2D).radius = attack_radius
	if detection_shape and detection_shape.shape is CircleShape2D:
		(detection_shape.shape as CircleShape2D).radius = detection_radius


## Дальний бой: радиус «каста» на export не режем по спрайту (зона удара отключена).
func _should_clamp_melee_attack_radius_to_sprite() -> bool:
	if attack_area != null and is_instance_valid(attack_area) and not attack_area.monitoring:
		return false
	return true


func _pick_animation_for_sprite_size(sf: SpriteFrames) -> StringName:
	if sf == null:
		return &""
	if sf.has_animation(&"idle"):
		return &"idle"
	if sf.has_animation(&"run"):
		return &"run"
	var names: PackedStringArray = sf.get_animation_names()
	if names.size() > 0:
		return names[0]
	return &""


## Максимальный радиус ближней атаки: не больше половины меньшей стороны кадра спрайта (окружность вписана в прямоугольник текстуры).
## При ошибке чтения кадра возвращает -1.0 (ограничение не применяется).
func _melee_attack_radius_cap_from_sprite_px() -> float:
	if anim == null or not is_instance_valid(anim):
		return -1.0
	var sf: SpriteFrames = anim.sprite_frames
	if sf == null:
		return -1.0
	var anim_name: StringName = _pick_animation_for_sprite_size(sf)
	if String(anim_name).is_empty() or not sf.has_animation(anim_name):
		return -1.0
	var fc: int = sf.get_frame_count(anim_name)
	if fc <= 0:
		return -1.0
	var tex: Texture2D = sf.get_frame_texture(anim_name, 0)
	if tex == null:
		return -1.0
	var sz: Vector2 = tex.get_size()
	if sz.x <= 0.0 or sz.y <= 0.0:
		return -1.0
	var gs: Vector2 = anim.global_scale.abs()
	var w: float = sz.x * gs.x
	var h: float = sz.y * gs.y
	return minf(w, h) * 0.5


func _clamp_attack_radius_to_sprite_frame() -> void:
	var cap: float = _melee_attack_radius_cap_from_sprite_px()
	if cap <= 0.0:
		return
	var lo: float = minf(12.0, cap)
	attack_radius = clampf(attack_radius, lo, cap)


func _setup_nav_agent() -> void:
	## Босс: только прямое движение к цели — NavigationAgent2D даёт джиттер и боковой увод.
	if not use_navigation or is_in_group(&"BOSS"):
		return
	_nav_agent = NavigationAgent2D.new()
	_nav_agent.path_desired_distance = 22.0
	_nav_agent.target_desired_distance = 28.0
	_nav_agent.radius = 40.0
	_nav_agent.navigation_layers = 1
	_nav_agent.avoidance_enabled = false
	_nav_agent.neighbor_distance = 120.0
	_nav_agent.max_neighbors = 6
	add_child(_nav_agent)
	await get_tree().physics_frame
	if is_instance_valid(_nav_agent):
		SlipperCombatBudget.apply_enemy_navigation_agent_preset(_nav_agent)
		_nav_agent.target_position = global_position


func _sync_avoidance_to_state() -> void:
	if _nav_agent == null or not is_instance_valid(_nav_agent):
		return
	var need := state == State.CHASE or state == State.ATTACK
	if _nav_agent.avoidance_enabled != need:
		_nav_agent.avoidance_enabled = need


func _physics_process(delta):
	var previous_position := global_position
	_select_target_cd -= delta

	var player_node: Node2D = get_tree().get_first_node_in_group("player") as Node2D
	var slipper_heavy: bool = SlipperCombatBudget.should_run_heavy_ai_for_enemy(
		self,
		attack_radius,
		attack_area,
		player_node,
		Engine.get_physics_frames()
	)
	if state in [State.ATTACK, State.HIT, State.DEATH, State.LEASH, State.RECOVER]:
		slipper_heavy = true

	match state:
		State.PATROL:
			velocity = patrol_dir * speed
			patrol_timer += delta
			if patrol_timer >= patrol_change_time:
				patrol_timer = 0.0
				patrol_dir = Vector2.RIGHT.rotated(randf_range(0, TAU))
			if is_on_wall():
				patrol_dir = patrol_dir.rotated(randf_range(PI / 4, PI / 2))

		State.CHASE:
			if _select_target_cd <= 0.0:
				if slipper_heavy:
					_select_target()
					_select_target_cd = _SELECT_TARGET_INTERVAL
				else:
					_select_target_cd = 0.034
			if target and is_instance_valid(target):
				if global_position.distance_to(home_position) > leash_radius:
					target = null
					state = State.LEASH
					velocity = Vector2.ZERO
				elif _is_target_in_attack_range():
					velocity = Vector2.ZERO
					if can_attack:
						start_attack()
				else:
					if slipper_heavy:
						_apply_chase_velocity()
					else:
						_apply_chase_velocity_simple()
			else:
				state = State.PATROL

		State.LEASH:
			var to_home := home_position - global_position
			if to_home.length() < 48.0:
				state = State.PATROL
				velocity = Vector2.ZERO
				_refresh_targets_after_leash()
			else:
				var want_home := _dir_toward_target(to_home)
				if is_in_group(&"BOSS"):
					last_dir = want_home
					velocity = last_dir * speed * 0.95
				else:
					last_dir = _steer_with_wall_probes(want_home, home_position)
					velocity = last_dir * speed * 0.95

		State.RECOVER:
			_recover_time -= delta
			velocity = _recover_dir * speed * 0.85
			if _recover_time <= 0.0:
				state = State.CHASE if target and is_instance_valid(target) and detection_area.overlaps_body(target) else State.PATROL
				_stuck_frames = 0

		State.ATTACK, State.HIT, State.DEATH:
			velocity = Vector2.ZERO

	## Босс в погоне: без soft-sep (иначе радиальное отталкивание даёт лево/вправо вместо прямо к герою).
	if not (is_in_group(&"BOSS") and state == State.CHASE):
		if slipper_heavy:
			_apply_soft_separation_to_velocity(delta)
	move_and_slide()

	if use_navigation and _nav_agent and is_instance_valid(_nav_agent):
		SlipperCombatBudget.apply_enemy_navigation_agent_preset(_nav_agent)
		_nav_agent.velocity = velocity

	## Босс в погоне: без скольжения вдоль стены — оно уводит вбок от прямой к цели.
	if state in [State.CHASE, State.LEASH] and is_on_wall():
		if not (is_in_group(&"BOSS") and state == State.CHASE):
			_apply_wall_slide_velocity()
			move_and_slide()

	if state == State.CHASE and target and is_instance_valid(target) and slipper_heavy:
		var moved_distance := previous_position.distance_to(global_position)
		if _is_target_in_attack_range():
			_stuck_frames = 0
		elif not is_in_group(&"BOSS") and moved_distance < 0.55:
			_stuck_frames += 1
			if _stuck_frames >= _STUCK_THRESHOLD_FRAMES and get_slide_collision_count() > 0:
				var c := get_slide_collision(0)
				if c:
					var n: Vector2 = c.get_normal()
					var tangent := n.orthogonal().normalized()
					if tangent.dot(_dir_toward_target(target.global_position - global_position)) < 0.0:
						tangent = -tangent
					_recover_dir = tangent
					_recover_time = _RECOVER_DURATION
					state = State.RECOVER
					_stuck_frames = 0
		else:
			_stuck_frames = 0

		var to_target := target.global_position - global_position
		var min_distance := attack_radius * 0.4
		if not is_in_group(&"BOSS") and to_target.length() < min_distance and not _is_target_in_attack_range():
			var push_dir := _away_from_target(to_target)
			if push_dir.length() > _SEP_EPS:
				velocity = push_dir * speed * 0.35
				move_and_slide()

	_sync_avoidance_to_state()
	if slipper_heavy:
		update_animation()


func _apply_chase_velocity_simple() -> void:
	## SLIPPER / TASK-015: без навигации и лучей — только к цели (дальние скирмиши).
	if target == null or not is_instance_valid(target):
		return
	var toward := target.global_position - global_position
	last_dir = _dir_toward_target(toward)
	velocity = last_dir * speed


func _apply_chase_velocity() -> void:
	if target == null or not is_instance_valid(target):
		return
	## Босс: только вектор к герою — без навигации, лучей и «умного» обхода.
	if is_in_group(&"BOSS"):
		var toward := target.global_position - global_position
		last_dir = _dir_toward_target(toward)
		velocity = last_dir * speed
		return

	var toward := _snap_axis_aligned_2d(target.global_position - global_position)
	var base_dir := _dir_toward_target(toward)

	if use_navigation and _nav_agent:
		var nav_player: Node2D = get_tree().get_first_node_in_group("player") as Node2D
		if SlipperCombatBudget.should_push_nav_target_to_player_this_physics_frame(
			self,
			attack_radius,
			attack_area,
			nav_player,
			Engine.get_physics_frames()
		):
			_nav_agent.target_position = target.global_position
		if not _nav_agent.is_navigation_finished():
			var next_pos := _nav_agent.get_next_path_position()
			var seg := _snap_axis_aligned_2d(next_pos - global_position)
			if seg.length() >= 14.0:
				var nav_dir := seg.normalized()
				if not _wall_ray_blocked(nav_dir):
					last_dir = nav_dir
					velocity = last_dir * speed
					return
				last_dir = _steer_with_wall_probes(nav_dir, target.global_position)
				velocity = last_dir * speed
				return
			elif seg.length() >= _SEP_EPS:
				base_dir = seg.normalized()
		else:
			var next_pos2 := _nav_agent.get_next_path_position()
			var seg2 := _snap_axis_aligned_2d(next_pos2 - global_position)
			if seg2.length() >= _SEP_EPS:
				base_dir = seg2.normalized()

	last_dir = _steer_with_wall_probes(base_dir, target.global_position)
	velocity = last_dir * speed


func _steer_with_wall_probes(desired_dir: Vector2, goal_global: Vector2) -> Vector2:
	if desired_dir.length() < _SEP_EPS:
		desired_dir = Vector2.RIGHT
	desired_dir = desired_dir.normalized()
	var to_goal := _snap_axis_aligned_2d(goal_global - global_position)
	var goal_hint := to_goal.normalized() if to_goal.length() > _SEP_EPS else desired_dir
	var space := get_world_2d().direct_space_state
	var my_rid := get_rid()

	if not _wall_ray_blocked_fast(desired_dir, space, my_rid):
		return desired_dir

	var best_dir := desired_dir
	var best_dot := -2.0
	for i in range(1, _FAN_COUNT + 1):
		for sgn in [-1.0, 1.0]:
			var d := desired_dir.rotated(sgn * _FAN_STEP * float(i))
			if not _wall_ray_blocked_fast(d, space, my_rid):
				var dot: float = d.dot(goal_hint)
				if dot > best_dot:
					best_dot = dot
					best_dir = d

	if best_dot > -1.5:
		return best_dir.normalized()

	for i in range(1, _FAN_COUNT + 1):
		for sgn in [-1.0, 1.0]:
			var d2 := desired_dir.rotated(sgn * _FAN_STEP * float(i))
			if not _wall_ray_blocked_fast(d2, space, my_rid):
				return d2.normalized()

	return desired_dir


func _wall_ray_blocked(dir: Vector2) -> bool:
	return _wall_ray_blocked_fast(dir, get_world_2d().direct_space_state, get_rid())


func _wall_ray_blocked_fast(dir: Vector2, space: PhysicsDirectSpaceState2D, my_rid: RID) -> bool:
	if dir.length_squared() < _SEP_EPS:
		return true
	var d := dir.normalized()
	var from := global_position + d * 6.0
	var to := from + d * wall_probe_distance
	var q := PhysicsRayQueryParameters2D.create(from, to)
	q.collision_mask = wall_probe_collision_mask
	q.exclude = [my_rid]
	var hit := space.intersect_ray(q)
	return hit.size() > 0


func _apply_wall_slide_velocity() -> void:
	if get_slide_collision_count() == 0:
		return
	var n: Vector2 = get_slide_collision(0).get_normal()
	var goal_dir := Vector2.ZERO
	if state == State.CHASE and target and is_instance_valid(target):
		goal_dir = _snap_axis_aligned_2d(target.global_position - global_position)
	elif state == State.LEASH:
		goal_dir = _snap_axis_aligned_2d(home_position - global_position)
	if goal_dir.length() < _SEP_EPS:
		return
	goal_dir = goal_dir.normalized()
	var along := goal_dir.slide(n)
	if along.length() > 0.12:
		velocity = along.normalized() * speed
	else:
		var tang := n.orthogonal().normalized()
		if tang.dot(goal_dir) < 0.0:
			tang = -tang
		velocity = tang * speed * 0.85


func _on_detection_area_entered(body):
	if body == null or not is_instance_valid(body):
		return
	if body is Node2D and (body.is_in_group("player") or body.is_in_group("ally")):
		potential_targets.append(body)
		_select_target()
		if state not in [State.ATTACK, State.DEATH, State.HIT]:
			state = State.CHASE


func _on_detection_area_exited(body):
	if body == null or not is_instance_valid(body):
		return
	if body is Node2D:
		potential_targets.erase(body)
		if body == target:
			target = null
		if potential_targets.is_empty() and state == State.CHASE:
			state = State.PATROL


func _on_attack_area_entered(body):
	if body == null or not is_instance_valid(body):
		return
	if body == target and can_attack and state not in [State.ATTACK, State.DEATH, State.HIT]:
		if body is Node2D and _is_target_within_melee_distance(body as Node2D):
			start_attack()


## Ближний бой: цель в зоне AttackArea. Переопределить для дальнего боя (шаман).
## overlaps_body на GLES/Wayland может быть истинным «на весь экран» — дублируем границу по дистанции (как в apply_damage).
func _is_target_in_attack_range() -> bool:
	if target == null or not is_instance_valid(target):
		return false
	if attack_area == null or not is_instance_valid(attack_area):
		return false
	if not _is_target_within_melee_distance(target):
		return false
	return attack_area.overlaps_body(target)


func _get_attack_animation_name() -> StringName:
	return &"attack"


func _get_enemy_sfx_kind() -> StringName:
	var sp: Script = get_script() as Script
	if sp == null:
		return &"default"
	return SoundManager.infer_enemy_sfx_kind_from_script_path(sp.resource_path)


func start_attack():
	SoundManager.play_enemy_attack_swing_for(_get_enemy_sfx_kind())
	state = State.ATTACK
	can_attack = false
	_attack_damage_applied = false
	if target and is_instance_valid(target):
		var dir = _dir_toward_target(target.global_position - global_position)
		last_dir = dir
		anim.flip_h = dir.x < 0
	var atk_anim := _get_attack_animation_name()
	if anim and is_instance_valid(anim):
		anim.play(atk_anim)
	attack_cooldown_timer.start(attack_cooldown)
	_start_anim_safety(atk_anim, 0.95)


func apply_damage():
	if target == null or not is_instance_valid(target):
		return
	if not (target is Node2D):
		return
	if attack_area == null or not is_instance_valid(attack_area):
		return
	if not attack_area.overlaps_body(target):
		return
	if not _is_target_within_melee_distance(target as Node2D):
		return
	var amt: int = attack_damage
	if target.is_in_group("character_unit") and not target.is_in_group("enemy"):
		amt = maxi(
			1,
			int(round(float(attack_damage) * BalanceConfig.get_enemy_outgoing_damage_vs_hero(enemy_level)))
		)
	GameplayFacade.try_apply_damage(target, amt)


func _on_anim_finished():
	if anim == null or not is_instance_valid(anim):
		return
	var an: StringName = anim.animation
	## Нельзя останавливать _anim_safety_timer на каждом animation_finished: любой «чужой»
	## клип (idle/run с loop=false, гонка движка) гасит таймер и оставляет врага в ATTACK/HIT навсегда.
	if an == &"attack" or an == &"throw":
		if _anim_safety_timer and state == State.ATTACK:
			_anim_safety_timer.stop()
		_finish_attack_phase()
	elif an == &"hit":
		if _anim_safety_timer and state == State.HIT:
			_anim_safety_timer.stop()
		_finish_hit_recovery()


func _finish_attack_phase() -> void:
	if state != State.ATTACK:
		return
	if not _attack_damage_applied:
		apply_damage()
		_attack_damage_applied = true
	_select_target()
	state = State.CHASE if target and is_instance_valid(target) and detection_area and is_instance_valid(detection_area) and detection_area.overlaps_body(target) else State.PATROL


func _finish_hit_recovery() -> void:
	if state != State.HIT:
		return
	_select_target()
	if target and is_instance_valid(target) and attack_area and is_instance_valid(attack_area) and detection_area and is_instance_valid(detection_area):
		state = State.ATTACK if _is_target_in_attack_range() and can_attack else State.CHASE if detection_area.overlaps_body(target) else State.PATROL
	else:
		state = State.PATROL


func _estimate_anim_duration_seconds(anim_name: StringName) -> float:
	if anim == null or not is_instance_valid(anim):
		return 0.75
	var sf: SpriteFrames = anim.sprite_frames as SpriteFrames
	if sf == null or not sf.has_animation(anim_name):
		return 0.75
	var n: int = sf.get_frame_count(anim_name)
	var spd: float = 5.0
	if sf.has_method("get_animation_speed"):
		var s: Variant = sf.get_animation_speed(anim_name)
		if s is float or s is int:
			spd = float(s)
	spd = maxf(spd, 0.01)
	# Один цикл; при loop=true animation_finished не приходит — этого времени достаточно, чтобы выйти из стейта.
	var dur: float = float(n) / spd
	return clampf(dur + 0.08, 0.18, 2.4)


func _start_anim_safety(anim_name: StringName, fallback_sec: float) -> void:
	if _anim_safety_timer == null:
		return
	_anim_safety_timer.stop()
	var w := fallback_sec
	if anim and is_instance_valid(anim) and anim.sprite_frames and anim.sprite_frames.has_animation(anim_name):
		w = _estimate_anim_duration_seconds(anim_name)
	_anim_safety_timer.wait_time = w
	_anim_safety_timer.start()


func _on_anim_safety_timeout() -> void:
	if state == State.ATTACK:
		_finish_attack_phase()
	elif state == State.HIT:
		_finish_hit_recovery()


func _on_attack_cooldown_timeout():
	can_attack = true


func update_animation():
	if anim == null or not is_instance_valid(anim):
		return
	if state in [State.PATROL, State.CHASE, State.LEASH, State.RECOVER]:
		if velocity.length() > 0:
			anim.play("run")
			if velocity.x != 0:
				anim.flip_h = velocity.x < 0
		else:
			anim.play("idle")


func _apply_enemy_balance_stats() -> void:
	if not is_instance_valid(self):
		return
	var mult := BalanceConfig.get_enemy_stat_multiplier(enemy_level)
	var hp_mult := BalanceConfig.get_enemy_hp_global_mult()
	health = maxi(1, int(round(float(health) * mult * hp_mult)))
	attack_damage = maxi(1, int(round(float(attack_damage) * mult)))
	if health_component:
		health_component.set_max_and_current(health)


func _modify_incoming_damage(amount: int) -> int:
	if amount <= 0:
		return amount
	var factor := BalanceConfig.get_incoming_damage_factor_vs_enemy(enemy_level)
	return maxi(1, int(round(float(amount) * factor)))


func _on_health_damage_applied(amount: int) -> void:
	SoundManager.play_enemy_hit_for(_get_enemy_sfx_kind())
	show_damage_number(amount)
	if health_component == null or health_component.current_health <= 0:
		return
	if state != State.DEATH and state != State.HIT and anim.sprite_frames and anim.sprite_frames.has_animation("hit"):
		if _anim_safety_timer:
			_anim_safety_timer.stop()
		state = State.HIT
		anim.play("hit")
		_start_anim_safety(&"hit", 0.72)


func _handle_death() -> void:
	die()


func die():
	if encounter_zone and is_instance_valid(encounter_zone):
		encounter_zone.notify_enemy_removed(self)

	if not is_in_group("BOSS"):
		SoundManager.play_death()
	GameManager.register_enemy_kill_for_playtest()
	var hero_lv: int = SaveManager.current_level
	var is_boss := is_in_group("BOSS")
	var rain_mul: float = RainSystem.get_monster_kill_reward_multiplier()
	var xp_reward := int(round(float(BalanceConfig.get_exp_reward(enemy_level, hero_lv, is_boss)) * reward_mult * rain_mul))
	GameManager.add_exp(xp_reward)
	state = State.DEATH
	if _anim_safety_timer:
		_anim_safety_timer.stop()
	## Иначе при смерти во время attack/hit сигнал animation_finished от прерванного клипа
	## завершает await до проигрыша dead — враг исчезает мгновенно (см. companion_unit._die).
	if anim.sprite_frames and anim.sprite_frames.has_animation(&"dead"):
		anim.stop()
		anim.play(&"dead")

	if is_in_group("BOSS"):
		## Сначала сюжетные флаги и финал (ветер), затем счётчик — иначе музыка тира 5 успевает начаться до глушения.
		if story_island > 0:
			GameManager.on_story_island_boss_defeated(story_island)
		GameManager.boss_kill()
		if story_island >= 1 and story_island <= 5:
			var spark_n: int = BalanceConfig.get_boss_defeat_ore_spark_count(story_island)
			spark_n = maxi(0, int(round(float(spark_n) * rain_mul)))
			GameManager.spawn_boss_ore_sparks_count_at(global_position, spark_n, self)

	var body_col := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if body_col:
		body_col.set_deferred("disabled", true)
	var gold_amt := int(round(float(BalanceConfig.get_gold_reward(enemy_level, is_boss)) * reward_mult * rain_mul))
	if gold_amt > 0:
		GameManager.spawn_gold_pickup_at(global_position, gold_amt, self)
	if anim.sprite_frames and anim.sprite_frames.has_animation(&"dead"):
		await anim.animation_finished
	queue_free()


func show_damage_number(amount: int) -> void:
	GameplayFacade.spawn_damage_number(self, amount, Vector2(-26, -80))


func _select_target() -> void:
	potential_targets = potential_targets.filter(func(t): return is_instance_valid(t) and detection_area.overlaps_body(t))
	if potential_targets.is_empty():
		target = null
		return

	var best: Node2D = null
	var best_dist := INF
	for t in potential_targets:
		if t == null or not is_instance_valid(t):
			continue
		var d := global_position.distance_to(t.global_position)
		if d < best_dist:
			best_dist = d
			best = t
	target = best
