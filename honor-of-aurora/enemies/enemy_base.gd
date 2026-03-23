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
@export var attack_radius: float = 100.0
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
var potential_targets: Array[Node2D] = []

var home_position: Vector2 = Vector2.ZERO
var encounter_zone: EncounterZone = null

var _nav_agent: NavigationAgent2D
var _stuck_frames: int = 0
var _recover_time: float = 0.0
var _recover_dir: Vector2 = Vector2.RIGHT

const _SEP_EPS := 1e-3
const _STUCK_THRESHOLD_FRAMES := 14
const _RECOVER_DURATION := 0.38
const _FAN_STEP := PI / 10.0
const _FAN_COUNT := 9


func _refresh_targets_after_leash() -> void:
	for body in detection_area.get_overlapping_bodies():
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

	randomize()
	patrol_dir = Vector2.RIGHT.rotated(randf_range(0, TAU))
	home_position = global_position
	call_deferred("_setup_nav_agent")
	call_deferred("_apply_enemy_balance_stats")


func _setup_nav_agent() -> void:
	if not use_navigation:
		return
	_nav_agent = NavigationAgent2D.new()
	_nav_agent.path_desired_distance = 28.0
	_nav_agent.target_desired_distance = 36.0
	_nav_agent.radius = 40.0
	_nav_agent.navigation_layers = 1
	_nav_agent.avoidance_enabled = false
	add_child(_nav_agent)
	await get_tree().physics_frame
	if is_instance_valid(_nav_agent):
		_nav_agent.target_position = global_position


func _physics_process(delta):
	var previous_position := global_position

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
			_select_target()
			if target and is_instance_valid(target):
				if global_position.distance_to(home_position) > leash_radius:
					target = null
					state = State.LEASH
					velocity = Vector2.ZERO
				elif attack_area.overlaps_body(target):
					velocity = Vector2.ZERO
					if can_attack:
						start_attack()
				else:
					_apply_chase_velocity()
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

	move_and_slide()

	if state in [State.CHASE, State.LEASH] and is_on_wall():
		_apply_wall_slide_velocity()
		move_and_slide()

	if state == State.CHASE and target and is_instance_valid(target):
		var moved_distance := previous_position.distance_to(global_position)
		if attack_area.overlaps_body(target):
			_stuck_frames = 0
		elif moved_distance < 0.55:
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
		if to_target.length() < min_distance and not attack_area.overlaps_body(target):
			var push_dir := _away_from_target(to_target)
			if push_dir.length() > _SEP_EPS:
				velocity = push_dir * speed * 0.35
				move_and_slide()

	update_animation()


func _apply_chase_velocity() -> void:
	if target == null or not is_instance_valid(target):
		return
	var toward := target.global_position - global_position
	var base_dir := _dir_toward_target(toward)

	if use_navigation and _nav_agent:
		_nav_agent.target_position = target.global_position
		var next_pos := _nav_agent.get_next_path_position()
		var seg := next_pos - global_position
		if seg.length() >= _SEP_EPS:
			base_dir = seg.normalized()

	last_dir = _steer_with_wall_probes(base_dir, target.global_position)
	velocity = last_dir * speed


func _steer_with_wall_probes(desired_dir: Vector2, goal_global: Vector2) -> Vector2:
	if desired_dir.length() < _SEP_EPS:
		desired_dir = Vector2.RIGHT
	desired_dir = desired_dir.normalized()
	var to_goal := goal_global - global_position
	var goal_hint := to_goal.normalized() if to_goal.length() > _SEP_EPS else desired_dir

	if not _wall_ray_blocked(desired_dir):
		return desired_dir

	var best_dir := desired_dir
	var best_dot := -2.0
	for i in range(1, _FAN_COUNT + 1):
		for sgn in [-1.0, 1.0]:
			var d := desired_dir.rotated(sgn * _FAN_STEP * float(i))
			if not _wall_ray_blocked(d):
				var dot: float = d.dot(goal_hint)
				if dot > best_dot:
					best_dot = dot
					best_dir = d

	if best_dot > -1.5:
		return best_dir.normalized()

	for i in range(1, _FAN_COUNT + 1):
		for sgn in [-1.0, 1.0]:
			var d2 := desired_dir.rotated(sgn * _FAN_STEP * float(i))
			if not _wall_ray_blocked(d2):
				return d2.normalized()

	return desired_dir


func _wall_ray_blocked(dir: Vector2) -> bool:
	if dir.length() < _SEP_EPS:
		return true
	var space := get_world_2d().direct_space_state
	var d := dir.normalized()
	var from := global_position + d * 6.0
	var to := from + d * wall_probe_distance
	var q := PhysicsRayQueryParameters2D.create(from, to)
	q.collision_mask = wall_probe_collision_mask
	q.exclude = [get_rid()]
	var hit := space.intersect_ray(q)
	return hit.size() > 0


func _apply_wall_slide_velocity() -> void:
	if get_slide_collision_count() == 0:
		return
	var n: Vector2 = get_slide_collision(0).get_normal()
	var goal_dir := Vector2.ZERO
	if state == State.CHASE and target and is_instance_valid(target):
		goal_dir = target.global_position - global_position
	elif state == State.LEASH:
		goal_dir = home_position - global_position
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
	if body is Node2D and (body.is_in_group("player") or body.is_in_group("ally")):
		potential_targets.append(body)
		_select_target()
		if state not in [State.ATTACK, State.DEATH, State.HIT]:
			state = State.CHASE


func _on_detection_area_exited(body):
	if body is Node2D:
		potential_targets.erase(body)
		if body == target:
			target = null
		if potential_targets.is_empty() and state == State.CHASE:
			state = State.PATROL


func _on_attack_area_entered(body):
	if body == target and can_attack and state not in [State.ATTACK, State.DEATH, State.HIT]:
		start_attack()


func start_attack():
	SoundManager.play_enemy_attack_swing()
	state = State.ATTACK
	can_attack = false
	if target:
		var dir = _dir_toward_target(target.global_position - global_position)
		last_dir = dir
		anim.flip_h = dir.x < 0
	anim.play("attack")
	attack_cooldown_timer.start(attack_cooldown)


func apply_damage():
	if target and attack_area.overlaps_body(target):
		GameplayFacade.try_apply_damage(target, attack_damage)


func _on_anim_finished():
	match anim.animation:
		"attack":
			apply_damage()
			_select_target()
			state = State.CHASE if target and detection_area.overlaps_body(target) else State.PATROL
		"hit":
			_select_target()
			if target:
				state = State.ATTACK if attack_area.overlaps_body(target) and can_attack else State.CHASE if detection_area.overlaps_body(target) else State.PATROL
			else:
				state = State.PATROL


func _on_attack_cooldown_timeout():
	can_attack = true


func update_animation():
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
	health = maxi(1, int(round(float(health) * mult)))
	attack_damage = maxi(1, int(round(float(attack_damage) * mult)))
	if health_component:
		health_component.set_max_and_current(health)


func _modify_incoming_damage(amount: int) -> int:
	if amount <= 0:
		return amount
	var factor := BalanceConfig.get_incoming_damage_factor_vs_enemy(enemy_level)
	return maxi(1, int(round(float(amount) * factor)))


func _on_health_damage_applied(amount: int) -> void:
	SoundManager.play_enemy_hit()
	show_damage_number(amount)
	if health_component == null or health_component.current_health <= 0:
		return
	if state != State.DEATH and state != State.HIT and anim.sprite_frames.has_animation("hit"):
		state = State.HIT
		anim.play("hit")


func _handle_death() -> void:
	die()


func die():
	if encounter_zone and is_instance_valid(encounter_zone):
		encounter_zone.notify_enemy_removed(self)

	if is_in_group("BOSS"):
		SoundManager.play_boss_defeat()
	else:
		SoundManager.play_death()
	var hero_lv := SaveManager.current_level
	var is_boss := is_in_group("BOSS")
	var xp_reward := int(round(float(BalanceConfig.get_exp_reward(enemy_level, hero_lv, is_boss)) * reward_mult))
	GameManager.add_exp(xp_reward)
	state = State.DEATH
	anim.play("dead")

	if is_in_group("BOSS"):
		GameManager.boss_kill()
		if story_island > 0:
			GameManager.on_story_island_boss_defeated(story_island)

	$CollisionShape2D.set_deferred("disabled", true)
	await anim.animation_finished
	var gold_amt := int(round(float(BalanceConfig.get_gold_reward(enemy_level, is_boss)) * reward_mult))
	GameManager.add_gold(gold_amt)
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
		if not t:
			continue
		var d := global_position.distance_to(t.global_position)
		if d < best_dist:
			best_dist = d
			best = t
	target = best
