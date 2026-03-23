extends Area2D
## Как ally/archer/Arrow/arrow.gd: Area2D слой arrow (16), _process, body_entered → урон и queue_free.
## У лучника стрела бьёт врагов (слой enemy); маска по умолчанию у Area2D = 1 — ок. Шаман бьёт героя/союзников:
## collision_mask = 14 (player|borderline|ally). У героя collision_mask должен включать слой arrow (16).

const SHAMAN_FRAMES := preload("res://enemies/shaman/shaman.tres")

@export var speed: float = 560.0
var damage: int = 30
var paralysis_duration: float = 1.5
var direction: Vector2 = Vector2.RIGHT

@onready var _flight_sprite: AnimatedSprite2D = $AnimatedSprite2D


func configure(dir: Vector2, dmg: int, paralyze: float) -> void:
	direction = dir.normalized()
	if direction.length() < 0.01:
		direction = Vector2.RIGHT
	damage = dmg
	paralysis_duration = paralyze
	rotation = direction.angle()


func _ready() -> void:
	collision_layer = 16
	collision_mask = 14
	body_entered.connect(_on_body_entered)
	if _flight_sprite and _flight_sprite.sprite_frames and _flight_sprite.sprite_frames.has_animation(&"flight"):
		_flight_sprite.play(&"flight")


func _process(delta: float) -> void:
	position += direction * speed * delta


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("enemy"):
		return
	if body is Node2D and body.is_in_group("character_unit") and not body.is_in_group("enemy"):
		GameplayFacade.try_apply_damage(body, damage)
		GameplayFacade.apply_paralysis(body, paralysis_duration)
	_spawn_explosion_fx(global_position)
	queue_free()


func _spawn_explosion_fx(p: Vector2) -> void:
	var e := Node2D.new()
	var s := AnimatedSprite2D.new()
	s.sprite_frames = SHAMAN_FRAMES
	s.play(&"explosion")
	e.add_child(s)
	e.global_position = p
	var root := get_tree().current_scene
	if root:
		root.add_child(e)
		s.animation_finished.connect(func(): e.queue_free(), CONNECT_ONE_SHOT)
