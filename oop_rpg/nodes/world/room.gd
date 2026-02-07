class_name Room
extends Node2D

@export var room_name: String = "Unnamed Room"
@export var next_room_path: String = ""

var enemies: Array = []
var is_cleared: bool = false

func _ready() -> void:
    collect_enemies()
    SignalBus.character_died.connect(_on_enemy_died)

func collect_enemies() -> void:
    enemies = []
    for child in get_children():
        if child is Enemy:
            enemies.append(child)

func _on_enemy_died(character: CharacterBase) -> void:
    if character in enemies:
        enemies.erase(character)
        if enemies.size() == 0:
            clear_room()

func clear_room() -> void:
    is_cleared = true
    SignalBus.room_cleared.emit(room_name)
    print("Комната ", room_name, " очищена!")
