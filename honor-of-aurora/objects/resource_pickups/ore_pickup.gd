extends Area2D
## Подбор сердцевины на островах. Случайный вид из `Asets/Руда` на каждый спаун.

const _ICON_FALLBACK := preload("res://Asets/Руда/1.png")

@export var ore_amount: int = 1

@onready var _sprite: Sprite2D = get_node_or_null("Sprite2D") as Sprite2D
@onready var _shape: CollisionShape2D = $CollisionShape2D

var _ready_pickup: bool = false


func _ready() -> void:
	if _sprite:
		_sprite.visible = false
	call_deferred("_setup_after_physics")


func _setup_after_physics() -> void:
	collision_layer = 0
	collision_mask = 2
	monitoring = false
	if _shape:
		_shape.disabled = true
	body_entered.connect(_on_body_entered)
	if _sprite:
		_sprite.visible = true
		var tex: Texture2D = OreVariantLibrary.pick_random_ore_texture()
		if tex == null:
			tex = _ICON_FALLBACK
		_sprite.texture = tex
		var tw := float(tex.get_width())
		if tw > 1.0:
			var s := 56.0 / tw
			_sprite.scale = Vector2(s, s)
		var sc := _sprite.scale
		_sprite.scale = sc * 0.25
		var tw_anim := create_tween()
		tw_anim.tween_property(_sprite, "scale", sc, 0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		tw_anim.tween_callback(_finish_spawn_visual)
	else:
		_finish_spawn_visual()


func _finish_spawn_visual() -> void:
	_ready_pickup = true
	set_deferred(&"monitoring", true)
	if _shape:
		_shape.set_deferred(&"disabled", false)


func _on_body_entered(body: Node2D) -> void:
	if not _ready_pickup:
		return
	if not GameplayFacade.is_player_body(body):
		return
	if Events.is_adventure_location(Events.current_location):
		if not CrownSystem.can_collect_expedition_ore():
			queue_free()
			return
		CrownSystem.track_expedition_ore(ore_amount)
	GameManager.add_ore(ore_amount)
	queue_free()
