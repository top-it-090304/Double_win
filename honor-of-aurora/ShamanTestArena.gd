extends Node2D
## Песочница: шаман vs герой с фиксированным HP, камера, WASD + Space (через MobileVirtualInput).
## Запуск: откройте `ShamanTestArena.tscn` → F6 (Play Scene).

const WORRIER := preload("res://ally/player/scenes/worrier_base.tscn")
const SHAMAN := preload("res://enemies/shaman/shaman.tscn")

@export var hero_max_hp: int = 100
@export var hero_spawn: Vector2 = Vector2(480, 460)
@export var shaman_spawn: Vector2 = Vector2(920, 460)

var _hero: CharacterBody2D
var _hint: Label


func _ready() -> void:
	IslandEncounterShared.attach_navigation_region(self)
	MobileVirtualInput.set_controls_visible(true)
	_setup_floor()
	_setup_hint()
	_spawn_hero()
	_spawn_shaman()
	await get_tree().process_frame
	_apply_test_hp()


func _setup_floor() -> void:
	var floor_body := StaticBody2D.new()
	floor_body.collision_layer = 4
	floor_body.position = Vector2(640, 520)
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(2000, 60)
	shape.shape = rect
	floor_body.add_child(shape)
	add_child(floor_body)


func _setup_hint() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 10
	_hint = Label.new()
	_hint.position = Vector2(16, 16)
	_hint.add_theme_font_size_override("font_size", 15)
	_hint.text = "Тест шамана\nWASD — движение  •  Space — атака\nОдин снаряд за каст; урон — при попадании шара."
	layer.add_child(_hint)
	add_child(layer)


func _spawn_hero() -> void:
	_hero = WORRIER.instantiate() as CharacterBody2D
	_hero.global_position = hero_spawn
	add_child(_hero)
	var cam := Camera2D.new()
	cam.enabled = true
	cam.position_smoothing_enabled = true
	cam.position_smoothing_speed = 8.0
	_hero.add_child(cam)


func _spawn_shaman() -> void:
	var s := SHAMAN.instantiate() as Node2D
	s.global_position = shaman_spawn
	add_child(s)
	if s.has_method("configure_for_island_tier"):
		s.call_deferred("configure_for_island_tier", 2)


func _apply_test_hp() -> void:
	if _hero == null:
		return
	var p: Node = _hero
	p.set("max_health", hero_max_hp)
	var hc: Node = p.get("health_component")
	if hc and hc.has_method("set_max_health"):
		hc.call("set_max_health", hero_max_hp)
		hc.call("set_current_health", hero_max_hp)


func _physics_process(_delta: float) -> void:
	if not MobileVirtualInput.enabled:
		return
	var d := Vector2.ZERO
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		d.x += 1.0
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		d.x -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		d.y += 1.0
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		d.y -= 1.0
	MobileVirtualInput.move_vector = d.normalized() if d.length_squared() > 0.0001 else Vector2.ZERO


func _unhandled_input(event: InputEvent) -> void:
	if not MobileVirtualInput.enabled:
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_SPACE:
		MobileVirtualInput.queue_attack()
