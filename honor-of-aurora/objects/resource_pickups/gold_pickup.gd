extends Area2D
## Подбор золота после G_Spawn → G_Idle; начисление при касании игрока.

const TEX_SPAWN := preload("res://Asets/Environment/Resources/Resources/G_Spawn.png")
const TEX_IDLE := preload("res://Asets/Environment/Resources/Resources/G_Idle.png")

const SPAWN_FRAME_COUNT := 6

@export var gold_amount: int = 1

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var _shape: CollisionShape2D = $CollisionShape2D

var _ready_pickup: bool = false


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	monitoring = false
	if _shape:
		_shape.disabled = true
	body_entered.connect(_on_body_entered)
	_build_frames()
	if _sprite and _sprite.sprite_frames:
		_sprite.animation_finished.connect(_on_anim_finished)
		_sprite.play(&"spawn")


func _build_frames() -> void:
	var sf := SpriteFrames.new()
	sf.add_animation(&"spawn")
	sf.set_animation_loop(&"spawn", false)
	var tw: int = TEX_SPAWN.get_width()
	var th: int = TEX_SPAWN.get_height()
	var fw: int = tw / SPAWN_FRAME_COUNT
	var dur := 1.0 / 12.0
	for i in range(SPAWN_FRAME_COUNT):
		var at := AtlasTexture.new()
		at.atlas = TEX_SPAWN
		at.region = Rect2(i * fw, 0, fw, th)
		sf.add_frame(&"spawn", at, dur)
	sf.add_animation(&"idle")
	sf.set_animation_loop(&"idle", true)
	sf.add_frame(&"idle", TEX_IDLE, 1.0)
	_sprite.sprite_frames = sf


func _on_anim_finished() -> void:
	if _sprite == null or not is_instance_valid(_sprite):
		return
	if _sprite.animation == &"spawn":
		_sprite.play(&"idle")
		_ready_pickup = true
		monitoring = true
		if _shape:
			_shape.disabled = false


func _on_body_entered(body: Node2D) -> void:
	if not _ready_pickup:
		return
	if not GameplayFacade.is_player_body(body):
		return
	GameManager.add_gold(gold_amount)
	queue_free()
