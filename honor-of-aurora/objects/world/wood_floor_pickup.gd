extends Area2D
## Лежащее бревно: рабочий в фазе TO_LOG подбегает — коллизия вызывает `try_begin_wood_castle_run`.


func _ready() -> void:
	add_to_group("wood_floor_pickup")
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("ally_pawn"):
		return
	if body.has_method("try_begin_wood_castle_run"):
		(body as Object).call("try_begin_wood_castle_run", self)
