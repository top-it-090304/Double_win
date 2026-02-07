class_name Enemy
extends CharacterBase

@export_category("AI Settings")
@export var attack_range: float = 50.0
@export var detection_range: float = 200.0
@export var experience_reward: int = 10

var target: Player = null
var is_attacking: bool = false

func _ready() -> void:
    super._ready()
    SignalBus.player_spawned.connect(_on_player_spawned)
    target = GameManager.player

func _physics_process(delta: float) -> void:
    if not is_alive or not target:
        return
    var distance_to_target = global_position.distance_to(target.global_position)
    if distance_to_target < detection_range and distance_to_target > attack_range:
        if state_machine.current_state.name != "Move":
            state_machine.transition_to("Move")
        move_towards(target.global_position)
    elif distance_to_target <= attack_range:
        if state_machine.current_state.name != "Attack":
            state_machine.transition_to("Attack")
            start_attack_sequence()
    else:
        if state_machine.current_state.name != "Idle":
            state_machine.transition_to("Idle")

func start_attack_sequence() -> void:
    is_attacking = true
    velocity = Vector2.ZERO
    await get_tree().create_timer(0.3).timeout
    if target and global_position.distance_to(target.global_position) <= attack_range:
        target.take_damage(damage, self)
    await get_tree().create_timer(0.7).timeout
    is_attacking = false

func _on_player_spawned(player: Player) -> void:
    target = player

func die() -> void:
    super.die()
    if target:
        target.gain_experience(experience_reward)
    await get_tree().create_timer(1.0).timeout
    queue_free()
