extends CharacterBody2D
## Базовый класс боевых сущностей (HealthComponent в составе).

const HEALTH_NODE_NAME := "HealthComponent"
const _HealthComponentScript := preload("res://characters/components/health_component.gd")
const _WorldMiniHpBar := preload("res://ui/hp_bar/world_mini_hp_bar.gd")

## Мини HP-бар над головой (игрок, враги, союзники).
@export var show_mini_hp_bar: bool = true
@export var mini_hp_bar_offset: Vector2 = Vector2(0, -92)

var health_component: Node


func _ready() -> void:
	add_to_group("character_unit")
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
