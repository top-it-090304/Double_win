extends Area2D
## Гарпун в полёте: как gnoll_bone — слой arrow (16), маска 14.
## Поворот: наконечник совпадает с direction. В текстуре ось гарпуна редко совпадает с +X (часто «по диагонали»).

@export var speed: float = 540.0
## Угол (рад) от оси +X текстуры до направления наконечника (CCW). Совпадает с +X = 0; вдоль +Y = PI/2; типичная диагональ в атласе ≈ PI/4.
@export var forward_angle_from_texture_x: float = PI * 0.25
var damage: int = 30
var direction: Vector2 = Vector2.RIGHT
var _slipper_motion_acc: float = 0.0

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D


func configure(dir: Vector2, dmg: int) -> void:
	direction = dir.normalized()
	if direction.length() < 0.01:
		direction = Vector2.RIGHT
	damage = dmg
	rotation = direction.angle() - forward_angle_from_texture_x + PI * 0.5


func _ready() -> void:
	collision_layer = 16
	collision_mask = 14
	body_entered.connect(_on_body_entered)
	if _sprite and _sprite.sprite_frames and _sprite.sprite_frames.has_animation(&"throw"):
		_sprite.play(&"throw")


func _process(delta: float) -> void:
	_slipper_motion_acc += delta
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if SlipperCombatBudget.should_defer_projectile_motion_frame(global_position, player, Engine.get_process_frames()):
		return
	var d := _slipper_motion_acc
	_slipper_motion_acc = 0.0
	position += direction * speed * d


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("enemy"):
		return
	if body is Node2D and body.is_in_group("character_unit") and not body.is_in_group("enemy"):
		GameplayFacade.try_apply_damage(body, damage)
	queue_free()
