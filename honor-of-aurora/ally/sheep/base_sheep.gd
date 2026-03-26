extends CharacterBody2D
## Овца на базе: бродит (idle / move), получает урон, при смерти — `meat_show_up` → `meat_idle`, подбор мяса игроком или рабочим (pawn).

signal sheep_died

const ANIM_IDLE := &"idle"
const ANIM_MOVE := &"move"
const ANIM_MEAT_SHOW := &"meat_show_up"
const ANIM_MEAT_IDLE := &"meat_idle"

enum _Phase { IDLE, RUN }
enum _Life { ALIVE, DYING, MEAT_PICKUP }

@export var max_health: int = 40
@export var wander_speed: float = 64.0
@export var idle_time_min: float = 1.0
@export var idle_time_max: float = 3.2
@export var run_time_min: float = 0.6
@export var run_time_max: float = 2.2
@export var meat_amount: int = 1

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var _meat_area: Area2D = $MeatPickupArea

var _life: _Life = _Life.ALIVE
var _phase: _Phase = _Phase.IDLE
var _phase_timer: float = 0.0
var _run_dir: Vector2 = Vector2.RIGHT
var _health: int = 0
var _last_anim: StringName = &""


func _ready() -> void:
	add_to_group("base_sheep")
	add_to_group("sheep_resource")
	_health = max_health
	randomize()
	_phase_timer = randf_range(idle_time_min, idle_time_max)
	_phase = _Phase.IDLE
	if not _validate_sprite_frames():
		return
	_force_play(ANIM_IDLE)
	if _meat_area:
		_meat_area.monitoring = false
		_meat_area.body_entered.connect(_on_meat_body_entered)


func _validate_sprite_frames() -> bool:
	if _sprite == null or _sprite.sprite_frames == null:
		push_error("BaseSheep: назначьте SpriteFrames на AnimatedSprite2D (анимации: idle, move, meat_show_up, meat_idle).")
		return false
	var sf := _sprite.sprite_frames
	for a in [ANIM_IDLE, ANIM_MOVE, ANIM_MEAT_SHOW, ANIM_MEAT_IDLE]:
		if not sf.has_animation(a):
			push_error("BaseSheep: в SpriteFrames нет анимации '%s'." % String(a))
			return false
	sf.set_animation_loop(ANIM_MEAT_SHOW, false)
	sf.set_animation_loop(ANIM_MEAT_IDLE, true)
	return true


func is_alive_for_meat() -> bool:
	return _life == _Life.ALIVE


func take_damage(amount: Variant) -> void:
	if _life != _Life.ALIVE:
		return
	var a: int = maxi(0, int(amount))
	if a <= 0:
		return
	_health -= a
	if _health <= 0:
		_begin_death()


func _begin_death() -> void:
	if _life != _Life.ALIVE:
		return
	_life = _Life.DYING
	velocity = Vector2.ZERO
	sheep_died.emit()
	_last_anim = &""
	_force_play(ANIM_MEAT_SHOW)
	if _sprite:
		_sprite.animation_finished.connect(_on_meat_show_finished, CONNECT_ONE_SHOT)


func _on_meat_show_finished() -> void:
	if _life != _Life.DYING:
		return
	_life = _Life.MEAT_PICKUP
	_last_anim = &""
	_force_play(ANIM_MEAT_IDLE)
	if _meat_area:
		_meat_area.monitoring = true


func _force_play(anim: StringName) -> void:
	_last_anim = anim
	if _sprite and _sprite.sprite_frames and _sprite.sprite_frames.has_animation(anim):
		_sprite.play(anim)


func _physics_process(delta: float) -> void:
	if Events.current_location != Events.LOCATION.BASE:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	if _life != _Life.ALIVE:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	_phase_timer -= delta
	match _phase:
		_Phase.IDLE:
			velocity = Vector2.ZERO
			if _last_anim != ANIM_IDLE:
				_force_play(ANIM_IDLE)
			if _phase_timer <= 0.0:
				_phase = _Phase.RUN
				_run_dir = Vector2.RIGHT.rotated(randf() * TAU)
				_phase_timer = randf_range(run_time_min, run_time_max)
		_Phase.RUN:
			velocity = _run_dir * wander_speed
			if _last_anim != ANIM_MOVE:
				_force_play(ANIM_MOVE)
			if _sprite:
				_sprite.flip_h = velocity.x < 0.0
			if _phase_timer <= 0.0:
				_phase = _Phase.IDLE
				_phase_timer = randf_range(idle_time_min, idle_time_max)
	move_and_slide()


func _on_meat_body_entered(body: Node2D) -> void:
	if _life != _Life.MEAT_PICKUP:
		return
	if not GameplayFacade.is_player_body(body) and not body.is_in_group("ally_pawn"):
		return
	GameManager.add_meat(meat_amount)
	queue_free()
