extends CharacterBody2D
## Овца на базе: бродит / стоит в idle; рабочий в режиме мяса подходит и режет ножом → M_Spawn + дроп мяса.

signal sheep_died

const TEX_IDLE := preload("res://Asets/Unit_pack/Terrain/Resources/Meat/Sheep/Sheep_Idle.png")
const TEX_MOVE := preload("res://Asets/Unit_pack/Terrain/Resources/Meat/Sheep/Sheep_Move.png")
const TEX_M_SPAWN := preload("res://Asets/Environment/Resources/Resources/M_Spawn.png")

const _FRAME_COLS := 7
const _FRAME_W := 128
const _SPAWN_START_COL := 1

@export var wander_speed: float = 52.0
@export var idle_time_min: float = 1.1
@export var idle_time_max: float = 3.2
@export var run_time_min: float = 0.7
@export var run_time_max: float = 2.0

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D

enum _Wander { IDLE, RUN }
var _wander: _Wander = _Wander.IDLE
var _phase_timer: float = 0.0
var _run_dir: Vector2 = Vector2.RIGHT
var _dying: bool = false
var _idle_frames: int = 8
var _move_frames: int = 8


func _ready() -> void:
	add_to_group("base_sheep")
	var sf := _sprite.sprite_frames
	if sf != null and sf.has_animation(&"idle") and sf.has_animation(&"run"):
		if _sprite.animation != &"idle":
			_sprite.play(&"idle")
	else:
		_idle_frames = _infer_frame_count(TEX_IDLE)
		_move_frames = _infer_frame_count(TEX_MOVE)
		_build_run_idle_frames()
	randomize()
	_phase_timer = randf_range(idle_time_min, idle_time_max)
	_wander = _Wander.IDLE


func _infer_frame_count(tex: Texture2D) -> int:
	var w := tex.get_width()
	var h := tex.get_height()
	if h < 8 or w < 32:
		return 1
	## Один ряд кадров: чаще всего квадратные ячейки (высота = ширина кадра).
	if w >= h and w % h == 0:
		return w / h
	## Типичные ширины кадра в пиксель-арте (как в Unit_pack).
	for fw in [128, 96, 80, 64, 48, 32]:
		if fw > 0 and w % fw == 0:
			var n: int = w / fw
			if n >= 1:
				return n
	return 1


func _build_run_idle_frames() -> void:
	var sf := SpriteFrames.new()
	if sf.has_animation(&"default"):
		sf.remove_animation(&"default")
	sf.add_animation(&"idle")
	sf.set_animation_loop(&"idle", true)
	## Пиксель-арт: 6–8 FPS выглядит естественнее, чем 10–12.
	_add_strip_frames(sf, &"idle", TEX_IDLE, _idle_frames, 6.0)
	sf.add_animation(&"run")
	sf.set_animation_loop(&"run", true)
	_add_strip_frames(sf, &"run", TEX_MOVE, _move_frames, 7.0)
	_sprite.sprite_frames = sf
	_sprite.play(&"idle")


func _add_strip_frames(sf: SpriteFrames, anim: StringName, tex: Texture2D, frame_count: int, fps: float) -> void:
	var w := tex.get_width()
	var th := tex.get_height()
	frame_count = maxi(1, frame_count)
	var fw: int = w / frame_count
	if fw < 1:
		fw = 1
	## Не выходим за ширину листа (если число кадров всё же не кратно ширине).
	var max_frames: int = w / fw
	frame_count = mini(frame_count, max_frames)
	var dur := 1.0 / maxf(0.01, fps)
	for i in range(frame_count):
		var at := AtlasTexture.new()
		at.atlas = tex
		at.region = Rect2(i * fw, 0, fw, th)
		sf.add_frame(anim, at, dur)


func is_alive_for_meat() -> bool:
	return not _dying


func is_calm_for_slaughter() -> bool:
	if _dying:
		return false
	return _wander == _Wander.IDLE and _phase_timer > 0.18


func _physics_process(delta: float) -> void:
	if Events.current_location != Events.LOCATION.BASE:
		return
	if _dying:
		return
	_check_slaughter()
	if _dying:
		return
	_phase_timer -= delta
	match _wander:
		_Wander.IDLE:
			velocity = Vector2.ZERO
			if _sprite.animation != &"idle":
				_sprite.play(&"idle")
			if _phase_timer <= 0.0:
				_wander = _Wander.RUN
				_run_dir = Vector2.RIGHT.rotated(randf() * TAU)
				_phase_timer = randf_range(run_time_min, run_time_max)
		_Wander.RUN:
			velocity = _run_dir * wander_speed
			if _sprite.animation != &"run":
				_sprite.play(&"run")
			_sprite.flip_h = velocity.x < 0.0
			if _phase_timer <= 0.0:
				_wander = _Wander.IDLE
				_phase_timer = randf_range(idle_time_min, idle_time_max)
	move_and_slide()


func _check_slaughter() -> void:
	if not is_calm_for_slaughter():
		return
	for pawn in get_tree().get_nodes_in_group("ally_pawn"):
		if not pawn is Node2D:
			continue
		if not pawn.has_method("get_worker_job_name") or pawn.get_worker_job_name() != "meat":
			continue
		var n2: Node2D = pawn as Node2D
		if global_position.distance_to(n2.global_position) > 54.0:
			continue
		var spr := n2.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
		if spr == null or spr.animation != &"interact_knife":
			continue
		_begin_death_sequence()
		return


func _begin_death_sequence() -> void:
	_dying = true
	velocity = Vector2.ZERO
	set_physics_process(false)
	GameManager.spawn_meat_pickup_at(global_position, 1, self)
	_build_m_spawn_frames()
	if _sprite.sprite_frames.has_animation(&"m_spawn"):
		if not _sprite.animation_finished.is_connected(_on_m_spawn_finished):
			_sprite.animation_finished.connect(_on_m_spawn_finished)
		_sprite.play(&"m_spawn")
	else:
		_finish_death()


func _build_m_spawn_frames() -> void:
	var tw: int = TEX_M_SPAWN.get_width()
	var th: int = TEX_M_SPAWN.get_height()
	var sf := SpriteFrames.new()
	if sf.has_animation(&"default"):
		sf.remove_animation(&"default")
	sf.add_animation(&"m_spawn")
	sf.set_animation_loop(&"m_spawn", false)
	var dur := 1.0 / 8.0
	for i in range(_SPAWN_START_COL, _FRAME_COLS):
		var at := AtlasTexture.new()
		at.atlas = TEX_M_SPAWN
		at.region = Rect2(i * _FRAME_W, 0, _FRAME_W, th)
		sf.add_frame(&"m_spawn", at, dur)
	_sprite.sprite_frames = sf


func _on_m_spawn_finished() -> void:
	if _sprite.animation != &"m_spawn":
		return
	_finish_death()


func _finish_death() -> void:
	sheep_died.emit()
	queue_free()
