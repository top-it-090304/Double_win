extends Area2D
## Кость гнолла: как shaman_lightning_ball / стрела — слой arrow (16), маска 14, без паралича.

@export var speed: float = 520.0
var damage: int = 25
var direction: Vector2 = Vector2.RIGHT

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D


func configure(dir: Vector2, dmg: int) -> void:
	direction = dir.normalized()
	if direction.length() < 0.01:
		direction = Vector2.RIGHT
	damage = dmg
	rotation = direction.angle()


func _ready() -> void:
	collision_layer = 16
	collision_mask = 14
	body_entered.connect(_on_body_entered)
	if _sprite and _sprite.sprite_frames and _sprite.sprite_frames.has_animation(&"throw"):
		_sprite.play(&"throw")


func _process(delta: float) -> void:
	position += direction * speed * delta


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("enemy"):
		return
	if body is Node2D and body.is_in_group("character_unit") and not body.is_in_group("enemy"):
		GameplayFacade.try_apply_damage(body, damage)
	queue_free()
