class_name Player
extends CharacterBase 

# === КОМПОНЕНТЫ ИГРОКА ===
@onready var input_handler: InputHandler = $InputHandler
@onready var camera: Camera2D = $Camera2D
@onready var attack_area: Area2D = $AttackArea
@onready var interaction_area: Area2D = $InteractionArea

# === ПЕРЕМЕННЫЕ ИГРОКА ===
var experience: int = 0
var level: int = 1
var coins: int = 0
var keys: int = 0
var inventory: Array = []

# === ЭКСПОРТИРУЕМЫЕ НАСТРОЙКИ ===
@export_category("Игрок")
@export var camera_zoom: float = 1.5
@export var interaction_range: float = 50.0

# === ИНИЦИАЛИЗАЦИЯ ===
func _ready() -> void:
	super._ready()
	
	# Регистрация в глобальных менеджерах
	GameManager.register_player(self)
	
	# Настройка камеры
	if camera:
		camera.zoom = Vector2(camera_zoom, camera_zoom)
		camera.make_current()
	
	# Настройка областей
	setup_areas()

func setup_areas() -> void:
	# Настройка области атаки
	if attack_area:
		var attack_shape = CircleShape2D.new()
		attack_shape.radius = 40.0
		attack_area.get_node("CollisionShape2D").shape = attack_shape
	
	# Настройка области взаимодействия
	if interaction_area:
		var interaction_shape = CircleShape2D.new()
		interaction_shape.radius = interaction_range
		interaction_area.get_node("CollisionShape2D").shape = interaction_shape

# === ОБРАБОТКА ФИЗИКИ ===
func _physics_process(delta: float) -> void:
	if not is_alive:
		return
	
	# Получаем ввод
	var input_vector = input_handler.get_movement_input()
	
	# Движение
	move(input_vector)
	
	# Управление состояниями
	if input_vector.length() > 0.1:
		if state_machine.current_state.name != "Move":
			state_machine.transition_to("Move")
	else:
		if state_machine.current_state.name == "Move":
			state_machine.transition_to("Idle")
	
	# Атака
	if Input.is_action_just_pressed("attack") and can_attack():
		perform_attack()
	
	# Взаимодействие
	if Input.is_action_just_pressed("interact"):
		try_interact()
	
	# Вызов родительской логики
	super._physics_process(delta)

# === АТАКА ===
func perform_attack() -> void:
	if not can_attack():
		return
	
	start_attack_cooldown()
	state_machine.transition_to("Attack")
	
	# Наносим урон всем врагам в области
	if attack_area:
		var enemies = attack_area.get_overlapping_bodies()
		for enemy in enemies:
			if enemy is Enemy and enemy.is_alive:
				enemy.take_damage(get_attack_damage(), self)

# === ВЗАИМОДЕЙСТВИЕ ===
func try_interact() -> void:
	if not interaction_area:
		return
	
	var interactables = interaction_area.get_overlapping_areas()
	for interactable in interactables:
		if interactable.has_method("interact"):
			interactable.interact(self)
			break

# === ОПЫТ И УРОВНИ ===
func gain_experience(amount: int) -> void:
	if amount <= 0:
		return
	
	experience += amount
	SignalBus.player_experience_gained.emit(amount, experience)
	
	# Проверка повышения уровня
	var required_exp = calculate_required_experience()
	if experience >= required_exp:
		level_up()

func level_up() -> void:
	level += 1
	max_health += 20
	current_health = max_health
	base_damage += 5
	
	SignalBus.player_level_up.emit(level)
	print("Уровень повышен! Теперь уровень ", level)

func calculate_required_experience() -> int:
	return level * 100  # Простая формула

# === ИНВЕНТАРЬ ===
func add_item(item: Resource) -> void:
	inventory.append(item)
	SignalBus.inventory_changed.emit(inventory)

func remove_item(item: Resource) -> bool:
	var index = inventory.find(item)
	if index != -1:
		inventory.remove_at(index)
		SignalBus.inventory_changed.emit(inventory)
		return true
	return false

func has_item(item_type: String) -> bool:
	for item in inventory:
		if item.get_class() == item_type:
			return true
	return false

# === АНИМАЦИИ ===
func update_sprite_direction() -> void:
	super.update_sprite_direction()
	
	if not animation_player:
		return
	
	# Выбор анимации в зависимости от направления
	if facing_direction.y > 0.5:
		animation_player.play("walk_down")
	elif facing_direction.y < -0.5:
		animation_player.play("walk_up")
	elif facing_direction.x != 0:
		animation_player.play("walk_side")
	elif state_machine.current_state.name == "Idle":
		animation_player.play("idle")

# === СМЕРТЬ ИГРОКА ===
func die() -> void:
	super.die()
	SignalBus.player_died.emit()
	
	# Перезагрузка сцены через 2 секунды
	await get_tree().create_timer(2.0).timeout
	get_tree().reload_current_scene()
