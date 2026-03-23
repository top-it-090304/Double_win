extends "res://enemies/enemy_base.gd"
## Дальний бой: на теле — attack; снаряд — отдельная сцена (как стрела у лучника). Попадание — урон и паралич (shaman_lightning_ball).

const LIGHTNING_BALL := preload("res://enemies/shaman/shaman_lightning_ball.tscn")

@export var projectile_scene: PackedScene = LIGHTNING_BALL
@export var projectile_spawn_delay: float = 0.48
@export var paralysis_duration: float = 1.5

var _projectile_spawn_timer: Timer
var _projectile_spawned_this_volley: bool = false
## Снимок на момент начала каста: снаряд не зависит от target/зон шамана после выстрела.
var _pending_shot_dir: Vector2 = Vector2.RIGHT
var _pending_shot_damage: int = 35
var _pending_shot_paralysis: float = 1.5


func _ready() -> void:
	super._ready()
	speed = 150.0
	health = 200
	attack_damage = 35
	enemy_level = 2
	detection_radius = 720.0
	attack_radius = 520.0
	detection_shape.shape.radius = detection_radius
	## AttackArea не используем для урона/попаданий — коллизия только у снаряда.
	attack_shape.shape.radius = 1.0
	attack_area.monitoring = false
	_projectile_spawn_timer = Timer.new()
	_projectile_spawn_timer.one_shot = true
	_projectile_spawn_timer.timeout.connect(_on_projectile_spawn_timer)
	add_child(_projectile_spawn_timer)


func _get_attack_animation_name() -> StringName:
	## Как у лучника: на теле — «замах» (attack), снаряд — отдельная сцена. Клип throw — три кадра шара из атласа снаряда на юните (не использовать).
	return &"attack"


func _aim_point_on_target(t: Node2D) -> Vector2:
	## Центр хитбокса (CollisionShape2D), а не origin тела — иначе луч в «иконку», мимо круга коллизии.
	if t == null or not is_instance_valid(t):
		return Vector2.ZERO
	var cs := t.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if cs != null and cs.shape != null:
		return cs.global_position
	return t.global_position


func _is_target_in_attack_range() -> bool:
	## Дальний бой: только дистанция до цели; AttackArea не определяет «попадание» и урон (урон только у shaman_lightning_ball).
	if target == null or not is_instance_valid(target):
		return false
	return global_position.distance_to(_aim_point_on_target(target)) <= attack_radius


func apply_damage() -> void:
	## Ближний/завершение атаки — без урона; урон наносит узел снаряда при коллизии.
	pass


func _on_attack_area_entered(body: Node) -> void:
	## Атака запускается из CHASE по дистанции, не по входу в зону AttackArea.
	pass


func _finish_hit_recovery() -> void:
	## База использует attack_area.overlaps_body — у шамана зона отключена; только дистанция каста.
	if state != State.HIT:
		return
	_select_target()
	if target:
		var in_cast_range := global_position.distance_to(_aim_point_on_target(target)) <= attack_radius
		state = State.ATTACK if in_cast_range and can_attack else State.CHASE if detection_area.overlaps_body(target) else State.PATROL
	else:
		state = State.PATROL


func start_attack() -> void:
	## Повторный вызов в том же кадре/пока уже кастуем — второй и третий таймеры снарядов (баг «три шара»).
	if state == State.ATTACK:
		return
	SoundManager.play_enemy_attack_swing()
	state = State.ATTACK
	can_attack = false
	_attack_damage_applied = true
	_projectile_spawned_this_volley = false
	if _projectile_spawn_timer:
		_projectile_spawn_timer.stop()
	if target and is_instance_valid(target):
		var dir := _dir_toward_target(_aim_point_on_target(target) - global_position)
		last_dir = dir
		_pending_shot_dir = dir
		anim.flip_h = dir.x < 0
	else:
		_pending_shot_dir = last_dir if last_dir.length() > 0.01 else Vector2.RIGHT
	_pending_shot_damage = attack_damage
	_pending_shot_paralysis = paralysis_duration
	var atk := _get_attack_animation_name()
	anim.play(atk)
	attack_cooldown_timer.start(attack_cooldown)
	_start_anim_safety(atk, 1.0)
	if _projectile_spawn_timer:
		_projectile_spawn_timer.wait_time = projectile_spawn_delay
		_projectile_spawn_timer.start()


func _on_projectile_spawn_timer() -> void:
	if _projectile_spawned_this_volley:
		return
	_spawn_lightning_ball()


func _spawn_lightning_ball() -> void:
	if not is_instance_valid(self) or state != State.ATTACK:
		return
	if _projectile_spawned_this_volley:
		return
	if projectile_scene == null:
		return
	var dir := _pending_shot_dir
	if dir.length() < 0.01:
		dir = Vector2.RIGHT
	dir = dir.normalized()
	var dmg := maxi(
		1,
		int(round(float(_pending_shot_damage) * BalanceConfig.get_enemy_outgoing_damage_vs_hero(enemy_level)))
	)
	var ball := projectile_scene.instantiate() as Node2D
	if ball == null:
		return
	ball.global_position = global_position + dir * 44.0
	get_tree().current_scene.add_child(ball)
	if ball.has_method("configure"):
		ball.call("configure", dir, dmg, _pending_shot_paralysis)
	_projectile_spawned_this_volley = true
