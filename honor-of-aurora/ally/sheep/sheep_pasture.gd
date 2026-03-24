extends Node2D
## Спавн овцы на пастбище и новая овца через `respawn_sec` после забоя.
## Если в сцене есть узел `sheep_zone` (Node2D), пастбище переносится в его точку, узел удаляется.
## Иначе — позиция этого узла SheepPasture в редакторе; опционально `align_to_wood_zone`.

@export var sheep_scene: PackedScene
@export var respawn_sec: float = 10.0
## Если true и нет `sheep_zone` — сместить к дереву / концу маршрута леса.
@export var align_to_wood_zone: bool = false

var _sheep: Node = null


func _ready() -> void:
	if sheep_scene == null:
		sheep_scene = preload("res://ally/sheep/base_sheep.tscn")
	call_deferred("_snap_and_spawn")


func _snap_and_spawn() -> void:
	if _consume_sheep_zone_node():
		pass
	elif align_to_wood_zone:
		_snap_to_wood_zone()
	_spawn_sheep()


## Демо-маркер: переносим пастбище в его координаты и убираем узел из дерева сцены.
func _consume_sheep_zone_node() -> bool:
	var root := get_tree().current_scene
	if root == null:
		return false
	var zone := root.find_child("sheep_zone", true, false)
	if zone == null or not is_instance_valid(zone):
		return false
	if zone is Node2D:
		global_position = (zone as Node2D).global_position
	zone.queue_free()
	return true


func _snap_to_wood_zone() -> void:
	var root := get_tree().current_scene
	if root == null:
		return
	var chop := root.find_child("WoodTreeChop", true, false) as Node2D
	if chop != null:
		global_position = chop.global_position
		return
	var nav := root.find_child("WorkerNavPath", true, false) as Node2D
	if nav == null:
		return
	var wood_path := nav.get_node_or_null("WorkerRoute2_wood") as Path2D
	if wood_path == null or wood_path.curve == null:
		return
	var c := wood_path.curve
	var n := c.get_point_count()
	if n < 1:
		return
	var local_pos: Vector2 = c.get_point_position(n - 1)
	global_position = wood_path.to_global(local_pos)


func _spawn_sheep() -> void:
	if sheep_scene == null:
		return
	var s: Node = sheep_scene.instantiate()
	_sheep = s
	add_child(s)
	if s is Node2D:
		(s as Node2D).global_position = global_position
	if s.has_signal("sheep_died"):
		s.sheep_died.connect(_on_sheep_died, CONNECT_ONE_SHOT)


func _on_sheep_died() -> void:
	_sheep = null
	var t := get_tree().create_timer(respawn_sec)
	t.timeout.connect(_spawn_sheep, CONNECT_ONE_SHOT)
