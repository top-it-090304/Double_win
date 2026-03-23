extends Area2D

@export var speed = 900.0
@export var damage = 10

var direction = Vector2.RIGHT

func _ready():
	rotation = direction.angle()
	
	body_entered.connect(_on_body_entered)

func _process(delta):
	position += direction * speed * delta

func _on_body_entered(body: Node) -> void:
	GameplayFacade.try_apply_damage(body, damage)
	queue_free()
