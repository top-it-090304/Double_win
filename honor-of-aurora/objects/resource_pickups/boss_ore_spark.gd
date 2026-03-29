extends Area2D
## Осколок сердцевины после босса / зачистки зоны. Случайный вид из `Asets/Руда`.
## Не учитывается в лимите добычи руды за поход.
## В большом радиусе притягивается к герою, чтобы не оставаться в недосягаемых точках.

const _ICON_FALLBACK := preload("res://Asets/Руда/1.png")

@export var ore_amount: int = 1
## На каком расстоянии от героя осколок начинает подтягиваться.
@export var magnet_radius: float = 640.0
## Целевая скорость у края зоны (пикс/с); фактическая нарастает постепенно.
@export var magnet_speed_near_edge: float = 55.0
## Целевая скорость у героя (пикс/с).
@export var magnet_speed_near_hero: float = 300.0
## Насколько быстро набирается скорость к цели (пикс/с²).
@export var magnet_acceleration: float = 180.0
## Затухание инерции вне зоны притяжения (пикс/с²).
@export var magnet_deceleration: float = 400.0

var _pull_velocity: Vector2 = Vector2.ZERO

@onready var _sprite: Sprite2D = get_node_or_null("Sprite2D") as Sprite2D


func _ready() -> void:
	set_physics_process(true)
	collision_layer = 0
	collision_mask = 2
	monitoring = true
	body_entered.connect(_on_body_entered)
	if _sprite:
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


func _resolve_player_node2d(tree: SceneTree) -> Node2D:
	var cached: Node = GameManager.current_scene_player
	if cached is Node2D and is_instance_valid(cached):
		var p2d := cached as Node2D
		if p2d.is_inside_tree():
			return p2d
	return tree.get_first_node_in_group("player") as Node2D


func _physics_process(delta: float) -> void:
	var tree := get_tree()
	if tree == null or tree.paused:
		return
	var player := _resolve_player_node2d(tree)
	if player == null:
		return
	var to_hero := player.global_position - global_position
	var dist_sq := to_hero.length_squared()
	var r := magnet_radius
	var r_sq := r * r
	if dist_sq > r_sq:
		_pull_velocity = _pull_velocity.move_toward(Vector2.ZERO, magnet_deceleration * delta)
		if _pull_velocity.length_squared() > 0.0001:
			global_position += _pull_velocity * delta
		return
	if dist_sq < 1.0:
		return
	var dist := sqrt(dist_sq)
	var inward := 1.0 - (dist / r)
	var target_speed := lerpf(magnet_speed_near_edge, magnet_speed_near_hero, pow(inward, 1.65))
	var desired_vel: Vector2 = (to_hero / dist) * target_speed
	_pull_velocity = _pull_velocity.move_toward(desired_vel, magnet_acceleration * delta)
	global_position += _pull_velocity * delta


func _on_body_entered(body: Node2D) -> void:
	if not GameplayFacade.is_player_body(body):
		return
	GameManager.add_ore(ore_amount)
	queue_free()
