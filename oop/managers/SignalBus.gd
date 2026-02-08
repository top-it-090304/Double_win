extends Node

# === СИНГЛТОН ===
static var instance: SignalBus = null

# === СИГНАЛЫ ===
# Игрок
signal player_spawned(player: Node)
signal player_damaged(player: Node, amount: int, current_health: int)
signal player_died(player: Node)
signal experience_gained(amount: int, total: int)

# Враги
signal enemy_spawned(enemy: Node)
signal enemy_damaged(enemy: Node, amount: int)
signal enemy_died(enemy: Node, experience: int)

# Система урона
signal damage_dealt(attacker: Node, target: Node, amount: int)
signal critical_hit(attacker: Node, multiplier: float)

# Комнаты
signal room_loaded(room_name: String)
signal room_cleared(room_name: String)

# Игровые состояния
signal game_paused(is_paused: bool)
signal game_resumed

# === ИНИЦИАЛИЗАЦИЯ ===
func _ready():
	instance = self
	print("✅ SignalBus инициализирован как синглтон")

# === УТИЛИТЫ ===
func emit_player_spawned(player: Node):
	player_spawned.emit(player)
	print("SignalBus: Игрок заспавнен - ", player.name)

func emit_enemy_died(enemy: Node, experience: int):
	enemy_died.emit(enemy, experience)
	print("SignalBus: Враг умер - ", enemy.name, " опыт: ", experience)
