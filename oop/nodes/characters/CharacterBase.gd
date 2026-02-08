class_name CharacterBase
extends CharacterBody2D  # ⬅ НАСЛЕДУЕМ ОТ CharacterBody2D!

# === ЭКСПОРТИРУЕМЫЕ ПЕРЕМЕННЫЕ ===
@export_category("Основные характеристики")
@export var max_health: int = 100
@export var speed: float = 300.0
@export var acceleration: float = 1500.0
@export var friction: float = 1200.0

@export_category("Боевые характеристики")
@export var base_damage: int = 10
@export var attack_cooldown: float = 1.0
@export var knockback_force: float = 200.0

# === ССЫЛКИ НА КОМПОНЕНТЫ ===
@onready var state_machine: StateMachine = $StateMachine
@onready var sprite: Sprite2D = $Sprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

# === ВНУТРЕННИЕ ПЕРЕМЕННЫЕ ===
var current_health: int
var is_alive: bool = true
var facing_direction: Vector2 = Vector2.RIGHT
var current_attack_cooldown: float = 0.0
var knockback_vector: Vector2 = Vector2.ZERO

# === СИГНАЛЫ ===
signal health_changed(new_health, max_health)
signal died
signal took_damage(amount, source)
signal attack_started
signal attack_finished

# === ОСНОВНЫЕ МЕТОДЫ ===
func _ready() -> void:
	current_health = max_health
	if state_machine:
		state_machine.initialize(self)

func _physics_process(delta: float) -> void:
	if not is_alive:
		return
	
	# Обновляем таймеры
	if current_attack_cooldown > 0:
		current_attack_cooldown -= delta
	
	# Применяем отталкивание
	apply_knockback(delta)
	
	# Обновляем состояние
	if state_machine:
		state_machine.update(delta)
	
	move_and_slide()

# === БОЕВАЯ СИСТЕМА ===
func take_damage(amount: int, source: Node = null) -> void:
	if not is_alive or amount <= 0:
		return
	
	current_health = max(current_health - amount, 0)
	health_changed.emit(current_health, max_health)
	took_damage.emit(amount, source)
	
	# Применяем отталкивание
	if source and source.global_position:
		var knockback_dir = (global_position - source.global_position).normalized()
		apply_instant_knockback(knockback_dir * knockback_force)
	
	# Переход в состояние получения урона
	if state_machine and state_machine.current_state.name != "Hurt":
		state_machine.transition_to("Hurt")
	
	# Смерть
	if current_health <= 0:
		die()

func die() -> void:
	is_alive = false
	if state_machine:
		state_machine.transition_to("Death")
	else:
		animation_player.play("death")
		await animation_player.animation_finished
		queue_free()
	
	died.emit()

# === ДВИЖЕНИЕ И ФИЗИКА ===
func move(direction: Vector2) -> void:
	if not is_alive or current_attack_cooldown > 0:
		return
	
	if direction.length() > 0.1:
		# Ускорение в направлении
		velocity = velocity.move_toward(
			direction.normalized() * speed,
			acceleration * get_physics_process_delta_time()
		)
		
		# Обновляем направление взгляда
		if direction.x != 0:
			facing_direction = direction
			update_sprite_direction()
	else:
		# Торможение
		velocity = velocity.move_toward(
			Vector2.ZERO,
			friction * get_physics_process_delta_time()
		)

func apply_knockback(delta: float) -> void:
	if knockback_vector.length() > 0:
		velocity = knockback_vector
		knockback_vector = knockback_vector.move_toward(
			Vector2.ZERO,
			friction * delta * 2.0
		)

func apply_instant_knockback(force: Vector2) -> void:
	knockback_vector = force

# === АНИМАЦИИ И ВНЕШНИЙ ВИД ===
func update_sprite_direction() -> void:
	if facing_direction.x > 0:
		sprite.flip_h = false
	elif facing_direction.x < 0:
		sprite.flip_h = true

func play_animation(anim_name: String) -> void:
	if animation_player and animation_player.has_animation(anim_name):
		animation_player.play(anim_name)

# === УТИЛИТЫ ===
func can_attack() -> bool:
	return is_alive and current_attack_cooldown <= 0

func start_attack_cooldown() -> void:
	current_attack_cooldown = attack_cooldown

func get_attack_damage() -> int:
	return base_damage
