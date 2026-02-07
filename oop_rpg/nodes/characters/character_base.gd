class_name CharacterBase
extends CharacterBody2D

@export_category("Character Settings")
@export var max_health: int = 100
@export var speed: float = 300.0

@onready var state_machine: StateMachine = $StateMachine
@onready var health_system: HealthSystem = $HealthSystem
@onready var sprite: Sprite2D = $Sprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer

var current_health: int
var is_alive: bool = true
var facing_direction: Vector2 = Vector2.DOWN

func _ready() -> void:
    current_health = max_health
    if state_machine:
        state_machine.initialize(self)
    if health_system:
        health_system.initialize(max_health)

func _physics_process(delta: float) -> void:
    if not is_alive:
        return
    state_machine._physics_process(delta)

func take_damage(amount: int, source: Node = null) -> void:
    if not is_alive:
        return
    current_health = health_system.take_damage(amount)
    SignalBus.character_damaged.emit(self, amount, source)
    if current_health <= 0:
        die()

func die() -> void:
    is_alive = false
    state_machine.transition_to("Death")
    SignalBus.character_died.emit(self)

func move_towards(target_position: Vector2) -> void:
    var direction = (target_position - global_position).normalized()
    velocity = direction * speed
    move_and_slide()
    if direction.length() > 0:
        facing_direction = direction
        update_sprite_direction()

func update_sprite_direction() -> void:
    if facing_direction.x > 0:
        sprite.flip_h = false
    elif facing_direction.x < 0:
        sprite.flip_h = true
