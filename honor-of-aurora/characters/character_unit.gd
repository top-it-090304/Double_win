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

## Отталкивание от босса (группа BOSS): сильнее отряда, целевой зазор ≈ сумма радиусов + padding.
const BOSS_SOFT_SEP_PADDING_PX := 26.0
const BOSS_SOFT_SEP_STRENGTH := 4.2
const BOSS_SOFT_SEP_SPEED_REF_MIN := 180.0

var health_component: Node


func _ready() -> void:
	## Плавное положение между шагами физики (важно при 30 Hz physics и 60 Hz экрана).
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_ON
	## Чуть больше дефолта — меньше «проталкивания» в коллизию при тесном контакте с боссом.
	safe_margin = maxf(safe_margin, 0.12)
	add_to_group("character_unit")
	add_to_group("y_sortable")
	_ensure_health_component()
	if show_mini_hp_bar:
		var cb := Callable(self, "_on_events_location_changed_mini_hp")
		if not Events.location_changed.is_connected(cb):
			Events.location_changed.connect(cb)
		call_deferred("_sync_mini_hp_bar_visibility")
	call_deferred("_cache_y_sort_offset")


func _exit_tree() -> void:
	var cb := Callable(self, "_on_events_location_changed_mini_hp")
	if Events.location_changed.is_connected(cb):
		Events.location_changed.disconnect(cb)


func _on_events_location_changed_mini_hp(_loc: Events.LOCATION) -> void:
	_sync_mini_hp_bar_visibility()


func _sync_mini_hp_bar_visibility() -> void:
	if not show_mini_hp_bar:
		return
	if Events.current_location == Events.LOCATION.BASE:
		_remove_mini_hp_bar_if_any()
		return
	if _has_mini_hp_bar_child():
		return
	_setup_mini_hp_bar()


func _has_mini_hp_bar_child() -> bool:
	for c in get_children():
		if c is Control and c.get_script() == _WorldMiniHpBar:
			return true
	return false


func _remove_mini_hp_bar_if_any() -> void:
	for c in get_children():
		if c is Control and c.get_script() == _WorldMiniHpBar:
			c.queue_free()


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


var _cached_y_sort_offset: float = NAN


func _cache_y_sort_offset() -> void:
	var from_sprite_y := YSortSpriteBounds.max_global_y_from_descendants(self)
	if not is_nan(from_sprite_y):
		_cached_y_sort_offset = from_sprite_y - global_position.y
		return
	var cs := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if cs == null or cs.shape == null:
		_cached_y_sort_offset = 0.0
		return
	var cs_local_y := cs.position.y
	if cs.shape is CircleShape2D:
		_cached_y_sort_offset = cs_local_y + (cs.shape as CircleShape2D).radius
	elif cs.shape is CapsuleShape2D:
		var sh := cs.shape as CapsuleShape2D
		_cached_y_sort_offset = cs_local_y + sh.radius + sh.height * 0.5
	elif cs.shape is RectangleShape2D:
		_cached_y_sort_offset = cs_local_y + (cs.shape as RectangleShape2D).size.y * 0.5
	else:
		_cached_y_sort_offset = cs_local_y


func get_y_sort_bottom_y() -> float:
	if is_nan(_cached_y_sort_offset):
		_cache_y_sort_offset()
	return global_position.y + _cached_y_sort_offset


func _soft_sep_body_radius(node: Node2D) -> float:
	## Кэш на узле: радиус основного CollisionShape2D (круг/капсула/прямоугольник).
	if not is_instance_valid(node):
		return 14.0
	if node.has_meta("_soft_sep_radius"):
		return float(node.get_meta("_soft_sep_radius"))
	var r := 14.0
	var cs := node.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if cs != null and cs.shape is CircleShape2D:
		r = (cs.shape as CircleShape2D).radius
	elif cs != null and cs.shape is CapsuleShape2D:
		var cap := cs.shape as CapsuleShape2D
		r = maxf(cap.radius, cap.height * 0.5 + cap.radius)
	elif cs != null and cs.shape is RectangleShape2D:
		var s := (cs.shape as RectangleShape2D).size
		r = maxf(s.x, s.y) * 0.5
	node.set_meta("_soft_sep_radius", r)
	return r


func _apply_soft_separation_to_velocity(delta: float) -> void:
	if not unit_soft_separation_enabled:
		return
	var tree := get_tree()
	if tree == null:
		return
	## Сначала: жёсткое разведение с боссом (и для врагов — иначе залипание у крупного коллайдера).
	_apply_boss_radius_separation(delta, tree)
	if is_in_group("enemy"):
		return
	if unit_soft_separation_distance <= 0.0 or unit_soft_separation_strength <= 0.0:
		return
	if tree.get_node_count_in_group(&"character_unit") < 2:
		return
	var push := Vector2.ZERO
	var my_pos := global_position
	var my_r := _soft_sep_body_radius(self)
	for other in tree.get_nodes_in_group("character_unit"):
		if other == self or other == null or not is_instance_valid(other):
			continue
		if not (other is Node2D):
			continue
		var other_node := other as Node
		## Между врагом и не-врагом — только коллизия CharacterBody2D. Дополнительное отталкивание
		## суммируется с разрешением контактов и при боссах/толпе даёт взаимное гашение и «залипание».
		if is_in_group("enemy") != other_node.is_in_group("enemy"):
			continue
		var other_n := other as Node2D
		var min_dist := maxf(unit_soft_separation_distance, my_r + _soft_sep_body_radius(other_n))
		var min_dist_sq := min_dist * min_dist
		var delta_pos := my_pos - other_n.global_position
		var dist_sq := delta_pos.length_squared()
		## Полное совпадение центров: без искусственного направления сила = 0 и «залипание».
		if dist_sq < 1e-8:
			var seed := int(get_instance_id()) ^ int(other_n.get_instance_id())
			delta_pos = Vector2.RIGHT.rotated(float(seed % 997) * TAU / 997.0) * 0.02
			dist_sq = delta_pos.length_squared()
		if dist_sq >= min_dist_sq:
			continue
		var inv_dist := 1.0 / sqrt(dist_sq)
		var weight := 1.0 - (1.0 / (inv_dist * min_dist))
		push += delta_pos * (inv_dist * weight)
	if push.length_squared() < 1e-6:
		return
	var speed_ref := maxf(80.0, velocity.length())
	velocity += push.normalized() * speed_ref * unit_soft_separation_strength * delta


func _apply_boss_radius_separation(delta: float, tree: SceneTree) -> void:
	if tree.get_node_count_in_group(&"character_unit") < 2:
		return
	var self_boss := is_in_group("BOSS")
	var my_pos := global_position
	var my_r := _soft_sep_body_radius(self)
	var push := Vector2.ZERO
	for other in tree.get_nodes_in_group("character_unit"):
		if other == self or other == null or not is_instance_valid(other):
			continue
		if not (other is Node2D):
			continue
		var other_node := other as Node
		var other_boss := other_node.is_in_group("BOSS")
		if not self_boss and not other_boss:
			continue
		if self_boss and other_boss:
			continue
		var other_n := other as Node2D
		var other_r := _soft_sep_body_radius(other_n)
		var min_dist := my_r + other_r + BOSS_SOFT_SEP_PADDING_PX
		var min_dist_sq := min_dist * min_dist
		var delta_pos := my_pos - other_n.global_position
		var dist_sq := delta_pos.length_squared()
		if dist_sq >= min_dist_sq:
			continue
		if dist_sq < 1e-8:
			var seed := int(get_instance_id()) ^ int(other_n.get_instance_id())
			delta_pos = Vector2.RIGHT.rotated(float(seed % 997) * TAU / 997.0) * 0.02
			dist_sq = delta_pos.length_squared()
		var inv_dist := 1.0 / sqrt(dist_sq)
		var weight := 1.0 - (1.0 / (inv_dist * min_dist))
		push += delta_pos * (inv_dist * weight)
	if push.length_squared() < 1e-6:
		return
	var speed_ref := maxf(BOSS_SOFT_SEP_SPEED_REF_MIN, velocity.length())
	velocity += push.normalized() * speed_ref * BOSS_SOFT_SEP_STRENGTH * delta
