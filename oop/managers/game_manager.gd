class_name GameManager
extends Node

# === СТАТИЧЕСКИЕ ПЕРЕМЕННЫЕ ===
static var player: Node = null
static var current_room: String = ""
static var player_experience: int = 0
static var player_level: int = 1
static var enemies_defeated: int = 0
static var is_paused: bool = false

# === СТАТИЧЕСКИЕ МЕТОДЫ (доступны отовсюду) ===
static func register_player(new_player: Node) -> void:
	player = new_player
	print("GameState: Игрок зарегистрирован - ", player.name)

static func gain_experience(amount: int) -> void:
	player_experience += amount
	SignalBus.experience_changed.emit(player_experience)
	
	# Проверка повышения уровня
	var exp_needed = player_level * 100
	while player_experience >= exp_needed:
		player_experience -= exp_needed
		player_level += 1
		SignalBus.level_up.emit(player_level)
		exp_needed = player_level * 100

static func take_damage(amount: int) -> void:
	if player and player.has_method("take_damage"):
		player.call("take_damage", amount)

static func heal_player(amount: int) -> void:
	if player and player.has_method("heal"):
		player.call("heal", amount)

static func get_player_position() -> Vector2:
	if player:
		return player.global_position
	return Vector2.ZERO

static func pause_game() -> void:
	is_paused = true
	Engine.time_scale = 0.0
	SignalBus.game_paused.emit(true)

static func resume_game() -> void:
	is_paused = false
	Engine.time_scale = 1.0
	SignalBus.game_paused.emit(false)

# === МЕТОДЫ ЭКЗЕМПЛЯРА (для Autoload) ===
func _ready() -> void:
	print("GameState готов")
	
	# Подключаемся к сигналам
	SignalBus.player_registered.connect(_on_player_registered)
	SignalBus.enemy_died.connect(_on_enemy_died)

func _on_player_registered(player_node: Node) -> void:
	player = player_node

func _on_enemy_died(enemy: Node, experience: int) -> void:
	enemies_defeated += 1
	gain_experience(experience)
