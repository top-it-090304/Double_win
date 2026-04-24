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

## Разделённый на все инстансы кэш массива "character_unit" на один физкадр.
## Без него каждый юнит в _physics_process аллоцирует свою копию (N вызовов get_nodes_in_group на кадр → N² работы).
static var _shared_units_frame: int = -1
static var _shared_units: Array = []
## Общий кэш узла "player" на физкадр — одинаково полезен врагам, рабочим и союзникам.
static var _shared_player_frame: int = -1
static var _shared_player: Node2D = null
## Флаг «в сцене есть BOSS» на физкадр: если нет — целиком пропускаем boss-sep для всех юнитов (обычный случай).
static var _shared_has_boss_frame: int = -1
static var _shared_has_boss: bool = false

var health_component: Node
## Кэш группы: is_in_group() внутри строка-поиска не копеечный в горячем O(N²) цикле soft-sep.
## Ленивая инициализация: дочерние классы делают add_to_group("enemy"/"BOSS") в собственных _ready после super._ready(),
## поэтому считываем при первом запросе (call_deferred гарантирует, что add_to_group уже отработал).
var _group_flags_inited: bool = false
var _is_enemy_cached: bool = false
var _is_boss_cached: bool = false


func _ensure_group_flags() -> void:
	if _group_flags_inited:
		return
	_group_flags_inited = true
	_is_enemy_cached = is_in_group(&"enemy")
	_is_boss_cached = is_in_group(&"BOSS")


static func _get_shared_units(tree: SceneTree) -> Array:
	var f := Engine.get_physics_frames()
	if f == _shared_units_frame:
		return _shared_units
	_shared_units_frame = f
	_shared_units = tree.get_nodes_in_group(&"character_unit") if tree != null else []
	return _shared_units


static func _scene_has_boss_this_frame(units: Array) -> bool:
	var f := Engine.get_physics_frames()
	if f == _shared_has_boss_frame:
		return _shared_has_boss
	_shared_has_boss_frame = f
	_shared_has_boss = false
	for u in units:
		if u != null and is_instance_valid(u) and u is Node and (u as Node).is_in_group(&"BOSS"):
			_shared_has_boss = true
			break
	return _shared_has_boss


static func get_cached_player_for_physics_frame(tree: SceneTree) -> Node2D:
	var f := Engine.get_physics_frames()
	if f == _shared_player_frame and _shared_player != null and is_instance_valid(_shared_player):
		return _shared_player
	_shared_player_frame = f
	_shared_player = null
	if tree != null:
		_shared_player = tree.get_first_node_in_group(&"player") as Node2D
	return _shared_player


func _ready() -> void:
	## Плавное положение между шагами физики (важно при 30 Hz physics и 60 Hz экрана).
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_ON
	## Чуть больше дефолта — меньше «проталкивания» в коллизию при тесном контакте с боссом.
	safe_margin = maxf(safe_margin, 0.12)
	add_to_group("character_unit")
	add_to_group("y_sortable")
	## Группы "enemy"/"BOSS" добавляются дочерними _ready — считываем на следующем кадре.
	call_deferred("_ensure_group_flags")
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
	call_deferred(&"queue_free")


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


## Убирает шум по «почти нулевой» оси (float, навигация), чтобы не дрожал знак и направление не флипалось кадр за кадром.
func _snap_axis_aligned_2d(v: Vector2) -> Vector2:
	if v.length_squared() < 1e-12:
		return v
	var ax := absf(v.x)
	var ay := absf(v.y)
	if ax < ay * 0.08 and ay > 1e-6:
		return Vector2(0.0, v.y)
	if ay < ax * 0.08 and ax > 1e-6:
		return Vector2(v.x, 0.0)
	return v


func _apply_soft_separation_to_velocity(delta: float) -> void:
	if not unit_soft_separation_enabled:
		return
	var tree := get_tree()
	if tree == null:
		return
	## Один список на кадр физики, общий для всех юнитов — см. _get_shared_units.
	var units := _get_shared_units(tree)
	if units.size() < 2:
		return
	_ensure_group_flags()
	## SLIPPER-специфично: далеко от героя юнит всё равно не виден, soft-sep визуально не нужен.
	## Экономит весь O(N) внутренний цикл для каждого дальнего врага/союзника.
	var is_slipper := PerformancePreset.is_slipper_mode(SaveManager)
	if is_slipper and not _is_boss_cached:
		var p := get_cached_player_for_physics_frame(tree)
		if p != null and is_instance_valid(p):
			var d_sq := global_position.distance_squared_to(p.global_position)
			## 1100 px ≈ за пределами типового экрана Аврора в SLIPPER viewport (понижение разрешения).
			if d_sq > 1100.0 * 1100.0:
				return
	## Сначала: жёсткое разведение с боссом (и для врагов — иначе залипание у крупного коллайдера).
	## Если BOSS-ов в сцене нет (обычный случай) — целиком пропускаем boss-sep: экономит N итераций на юнит.
	if _scene_has_boss_this_frame(units):
		_apply_boss_radius_separation(delta, units)
	if _is_enemy_cached:
		return
	if unit_soft_separation_distance <= 0.0 or unit_soft_separation_strength <= 0.0:
		return
	## Стаггер по instance_id: не-боссовое soft-sep для player/ally запускаем раз в K физкадров,
	## сила×K компенсирует реже применение. На слабом железе экономит O(N²) на "тяжёлых" кадрах.
	var stagger_k: int = 3 if PerformancePreset.is_slipper_mode(SaveManager) else 2
	var phase_ok := ((Engine.get_physics_frames() + (int(get_instance_id()) & 0xFFF)) % stagger_k) == 0
	if not phase_ok:
		return
	var push := Vector2.ZERO
	var my_pos := global_position
	var my_r := _soft_sep_body_radius(self)
	for other in units:
		if other == self or other == null or not is_instance_valid(other):
			continue
		if not (other is Node2D):
			continue
		var other_node := other as Node
		## Между врагом и не-врагом — только коллизия CharacterBody2D. Дополнительное отталкивание
		## суммируется с разрешением контактов и при боссах/толпе даёт взаимное гашение и «залипание».
		if _is_enemy_cached != other_node.is_in_group(&"enemy"):
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
	## stagger_k выше — компенсация за более редкое применение.
	velocity += push.normalized() * speed_ref * unit_soft_separation_strength * delta * float(stagger_k)


func _apply_boss_radius_separation(delta: float, units: Array) -> void:
	if units.size() < 2:
		return
	_ensure_group_flags()
	var self_boss := _is_boss_cached
	var my_pos := global_position
	var my_r := _soft_sep_body_radius(self)
	var push := Vector2.ZERO
	for other in units:
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
		var delta_pos := _snap_axis_aligned_2d(my_pos - other_n.global_position)
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
