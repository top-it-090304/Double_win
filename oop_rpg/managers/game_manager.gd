class_name GameManager
extends Node

static var player: Player = null
var current_room: String = ""
var player_experience: int = 0
var enemies_defeated: int = 0

func _ready() -> void:
    SignalBus.player_spawned.connect(_on_player_spawned)
    SignalBus.character_died.connect(_on_character_died)

func _on_player_spawned(new_player: Player) -> void:
    player = new_player
    print("GameManager: Игрок зарегистрирован")

func _on_character_died(character: CharacterBase) -> void:
    if character is Enemy:
        enemies_defeated += 1
        print("Врагов побеждено: ", enemies_defeated)

func gain_experience(amount: int) -> void:
    player_experience += amount
    SignalBus.experience_gained.emit(amount, player_experience)
