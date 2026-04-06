extends Area2D

@export var speed = 900.0
@export var damage = 10

var direction = Vector2.RIGHT
var _slipper_motion_acc: float = 0.0

func _ready():
	rotation = direction.angle()
	
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	_slipper_motion_acc += delta
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if SlipperCombatBudget.should_defer_projectile_motion_frame(global_position, player, Engine.get_process_frames()):
		return
	var d := _slipper_motion_acc
	_slipper_motion_acc = 0.0
	position += direction * speed * d

func _on_body_entered(body: Node) -> void:
	GameplayFacade.try_apply_damage(body, damage)
	queue_free()
