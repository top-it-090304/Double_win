class_name Player
extends CharacterBase

@onready var input_handler: InputHandler = $InputHandler

func _ready() -> void:
    super._ready()
    GameManager.player = self

func _physics_process(delta: float) -> void:
    if not is_alive:
        return
    var input_vector = input_handler.get_movement_vector()
    if input_vector.length() > 0:
        velocity = input_vector * speed
        move_and_slide()
        facing_direction = input_vector
        update_sprite_direction()
        if state_machine.current_state.name != "Move":
            state_machine.transition_to("Move")
    else:
        velocity = Vector2.ZERO
        if state_machine.current_state.name == "Move":
            state_machine.transition_to("Idle")
    if Input.is_action_just_pressed("attack"):
        state_machine.transition_to("Attack")

func update_sprite_direction() -> void:
    super.update_sprite_direction()
    if facing_direction.y > 0.5:
        animation_player.play("walk_down")
    elif facing_direction.y < -0.5:
        animation_player.play("walk_up")
    elif facing_direction.x != 0:
        animation_player.play("walk_side")
