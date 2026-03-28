extends CharacterBody2D
## Базовый класс боевых сущностей (HealthComponent в составе).

const HEALTH_NODE_NAME := "HealthComponent"
const _HealthComponentScript := preload("res://characters/components/health_component.gd")
const _WorldMiniHpBar := preload("res://ui/hp_bar/world_mini_hp_bar.gd")

## Мини HP-бар над головой (игрок, враги, союзники).
@export var show_mini_hp_bar: bool = true
@export var mini_hp_bar_offset: Vector2 = Vector2(0, -92)
## Мягкое отталкивание юнитов друг от друга (без роста коллайдера).
@export var unit_soft_separation_enabled: bool = true
@export_range(8.0, 120.0, 1.0) var unit_soft_separation_distance: float = 28.0
@export_range(0.0, 2.0, 0.01) var unit_soft_separation_strength: float = 0.42

var health_component: Node


func _ready() -> void:
	add_to_group("character_unit")
	add_to_group("y_sortable")
	_ensure_health_component()
	if show_mini_hp_bar:
		_setup_mini_hp_bar()


func _setup_mini_hp_bar() -> void:
	var bar: Control = _WorldMiniHpBar.new()
	add_child(bar)
	bar.setup(self)
	bar.position = mini_hp_bar_offset + Vector2(-bar.custom_minimum_size.x * 0.5, 0)


func _ensure_health_component() -> void:
	health_component = get_node_or_null(HEALTH_NODE_NAME)
	if health_component == null:
		health_component = _HealthComponentScript.new()
		health_component.name = HEALTH_NODE_NAME
		add_child(health_component)
	_configure_health_component()
	health_component.died.connect(_on_health_component_died)
	health_component.damage_applied.connect(_on_health_damage_applied)


func _configure_health_component() -> void:
	var hi: int = _get_initial_health()
	var hm: int = _get_initial_max_health()
	hm = maxi(hm, 1)
	hi = clampi(hi, 0, hm)
	health_component.max_health = hm
	health_component.current_health = hi
	health_component.health_changed.emit(health_component.current_health, health_component.max_health)


func _get_initial_health() -> int:
	return 100


func _get_initial_max_health() -> int:
	return _get_initial_health()


func _on_health_component_died() -> void:
	_handle_death()


func _handle_death() -> void:
	queue_free()


func _on_health_damage_applied(_amount: int) -> void:
	pass


func _modify_incoming_damage(amount: int) -> int:
	return amount


func take_damage(amount: Variant) -> void:
	var a: int = int(amount)
	if a == 0:
		return
	if a < 0:
		if health_component:
			health_component.heal(-a)
		return
	a = _modify_incoming_damage(a)
	if health_component:
		health_component.apply_damage(a)


func is_alive() -> bool:
	return health_component != null and health_component.current_health > 0


func is_health_full() -> bool:
	if health_component == null:
		return true
	return health_component.current_health >= health_component.max_health


func get_y_sort_bottom_y() -> float:
	## Нижний край по видимым спрайтам — см. YSortSpriteBounds; иначе коллайдер.
	var from_sprite_y := YSortSpriteBounds.max_global_y_from_descendants(self)
	if not is_nan(from_sprite_y):
		return from_sprite_y
	var cs := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if cs == null or cs.shape == null:
		return global_position.y
	if cs.shape is CircleShape2D:
		return cs.global_position.y + (cs.shape as CircleShape2D).radius
	if cs.shape is CapsuleShape2D:
		var sh := cs.shape as CapsuleShape2D
		return cs.global_position.y + sh.radius + sh.height * 0.5
	if cs.shape is RectangleShape2D:
		return cs.global_position.y + (cs.shape as RectangleShape2D).size.y * 0.5
	return cs.global_position.y


func _apply_soft_separation_to_velocity(delta: float) -> void:
	if not unit_soft_separation_enabled:
		return
	if unit_soft_separation_distance <= 0.0 or unit_soft_separation_strength <= 0.0:
		return
	var tree := get_tree()
	if tree == null:
		return
	var min_dist := unit_soft_separation_distance
	var min_dist_sq := min_dist * min_dist
	var push := Vector2.ZERO
	for other in tree.get_nodes_in_group("character_unit"):
		if other == self:
			continue
		if not (other is Node2D):
			continue
		var on := other as Node
		if on.has_method("is_alive") and not bool(on.call("is_alive")):
			continue
		var other_pos := (other as Node2D).global_position
		var delta_pos := global_position - other_pos
		var dist_sq := delta_pos.length_squared()
		if dist_sq >= min_dist_sq:
			continue
		var dist := sqrt(maxf(dist_sq, 0.0001))
		var dir := delta_pos / dist
		var weight := 1.0 - (dist / min_dist)
		push += dir * weight
	if push.length_squared() < 1e-6:
		return
	var speed_ref := maxf(80.0, velocity.length())
	velocity += push.normalized() * speed_ref * unit_soft_separation_strength * delta
