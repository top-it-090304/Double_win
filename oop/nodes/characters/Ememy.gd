class_name Enemy
extends CharacterBase  

# === ЭКСПОРТИРУЕМЫЕ НАСТРОЙКИ AI ===
@export_category("AI Настройки")
@export var attack_range: float = 50.0
@export var chase_range: float = 200.0
@export var patrol_range: float = 100.0
@export var experience_value: int = 25
@export var gold_drop: int = 10
@export var item_drop_chance: float = 0.3

# === ВНУТРЕННИЕ ПЕРЕМЕННЫЕ ===
var target: Player = null
var patrol_points: Array = []
var current_patrol_index: int = 0
var spawn_position: Vector2
var drop_items: Array = []

# === ИНИЦИАЛИЗАЦИЯ ===
func _ready() -> void:
	super._ready()
	spawn_position = global_position
	setup_ai_components()
	generate_patrol_points()

func setup_ai_components() -> void:
	# Создаем область обнаружения если её нет
	if not has_node("DetectionArea"):
		var detection_area = Area2D.new()
		detection_area.name = "DetectionArea"
		var collision = CollisionShape2D.new()
		collision.shape = CircleShape2D.new()
		collision.shape.radius = chase_range
		detection_area.add_child(collision)
		add_child(detection_area)
		
		detection_area.body_entered.connect(_on_detection_area_body_entered)
		detection_area.body_exited.connect(_on_detection_area_body_exited)

func generate_patrol_points() -> void:
	patrol_points.clear()
	
	if patrol_range > 0:
		for i in range(4):
			var angle = i * PI / 2
			var point = spawn_position + Vector2(
				cos(angle) * patrol_range,
				sin(angle) * patrol_range
			)
			patrol_points.append(point)

# === AI ЛОГИКА ===
func _physics_process(delta: float) -> void:
	if not is_alive:
		return
	
	# Если есть цель - преследовать/атаковать
	if target and target.is_alive:
		handle_target_behavior()
	else:
		handle_patrol_behavior()
	
	super._physics_process(delta)

func handle_target_behavior() -> void:
	var distance_to_target = global_position.distance_to(target.global_position)
	
	if distance_to_target > chase_range:
		# Цель вышла за пределы преследования
		target = null
		state_machine.transition_to("Idle")
	elif distance_to_target > attack_range:
		# Преследование
		var direction = (target.global_position - global_position).normalized()
		move(direction)
		state_machine.transition_to("Move")
	else:
		# Атака
		velocity = Vector2.ZERO
		
		if can_attack():
			state_machine.transition_to("Attack")
			start_attack_cooldown()
			
			# Наносим урон
			if target:
				target.take_damage(get_attack_damage(), self)
		else:
			state_machine.transition_to("Idle")

func handle_patrol_behavior() -> void:
	if patrol_points.size() == 0:
		state_machine.transition_to("Idle")
		return
	
	var target_point = patrol_points[current_patrol_index]
	var distance = global_position.distance_to(target_point)
	
	if distance < 10.0:
		# Достигли точки патрулирования
		current_patrol_index = (current_patrol_index + 1) % patrol_points.size()
		target_point = patrol_points[current_patrol_index]
		
		# Ждем на точке
		await get_tree().create_timer(1.0).timeout
	
	# Движение к точке
	var direction = (target_point - global_position).normalized()
	move(direction)
	state_machine.transition_to("Move")

# === ОБРАБОТЧИКИ ОБЛАСТЕЙ ===
func _on_detection_area_body_entered(body: Node2D) -> void:
	if body is Player and body.is_alive:
		target = body
		SignalBus.enemy_detected_player.emit(self, target)

func _on_detection_area_body_exited(body: Node2D) -> void:
	if body == target:
		target = null
		SignalBus.enemy_lost_player.emit(self)

# === АТАКА ===
func attack() -> void:
	if target and target.is_alive and global_position.distance_to(target.global_position) <= attack_range:
		target.take_damage(get_attack_damage(), self)
		SignalBus.enemy_attacked.emit(self, target)

# === СМЕРТЬ ВРАГА ===
func die() -> void:
	super.die()
	
	# Награда за убийство
	if target:
		target.gain_experience(experience_value)
		target.coins += gold_drop
		SignalBus.enemy_died.emit(self, experience_value, gold_drop)
	
	# Выпадение лута
	drop_loot()
	
	# Удаление через время
	await get_tree().create_timer(1.5).timeout
	queue_free()

func drop_loot() -> void:
	# Выпадение золота
	if gold_drop > 0:
		spawn_gold(gold_drop)
	
	# Выпадение предметов
	if randf() < item_drop_chance and drop_items.size() > 0:
		var random_item = drop_items[randi() % drop_items.size()]
		spawn_item(random_item)

func spawn_gold(amount: int) -> void:
	# Здесь можно создать сцену монеты
	pass

func spawn_item(item: Resource) -> void:
	# Здесь можно создать сцену предмета
	pass

# === УТИЛИТЫ ===
func is_player_in_sight() -> bool:
	return target != null and target.is_alive

func get_distance_to_player() -> float:
	if not target:
		return INF
	return global_position.distance_to(target.global_position)
