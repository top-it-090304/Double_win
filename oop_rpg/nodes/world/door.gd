class_name Door
extends Area2D

@export var target_room_path: String = ""
@export var spawn_point_name: String = "default"

func _ready() -> void:
    connect("body_entered", _on_body_entered)

func _on_body_entered(body: Node2D) -> void:
    if body is Player and target_room_path != "":
        SignalBus.room_changed.emit(get_parent().name if get_parent() else "", target_room_path)
        print("Игрок переходит в комнату: ", target_room_path)
