extends Node2D
## Случайно выбирает дочерние Marker2D и создаёт WorldChest на их позициях.
## У каждой точки стабильный id (остров + имя маркера), ярус лута роллится один раз и хранится в SaveManager.chest_rolled_tiers.

@export var chest_scene: PackedScene
@export_range(1, 5, 1) var island_index: int = 1
@export_range(0, 16, 1) var min_chests: int = 1
@export_range(0, 16, 1) var max_chests: int = 3
## Куда вешать инстансы (обычно родитель спавнера — корень острова). Если пусто — родитель этого узла.
@export var spawn_parent: Node2D


func _ready() -> void:
	if chest_scene == null:
		chest_scene = preload("res://objects/world/chest/world_chest.tscn")
	var parent: Node2D = spawn_parent
	if parent == null:
		parent = get_parent() as Node2D
	if parent == null:
		push_error("ChestSpawner: нужен Node2D-родитель или spawn_parent.")
		return
	var markers: Array[Marker2D] = []
	for c: Node in get_children():
		if c is Marker2D:
			markers.append(c as Marker2D)
	if markers.is_empty():
		return
	markers.shuffle()
	var lo: int = mini(min_chests, max_chests)
	var hi: int = maxi(min_chests, max_chests)
	var count: int = randi_range(lo, hi)
	count = mini(count, markers.size())
	for i: int in range(count):
		var m: Marker2D = markers[i]
		var chest: Node = chest_scene.instantiate()
		if chest == null:
			continue
		# Префикс islN_ — сброс при возврате на базу (SaveManager.reset_island_chest_progress_after_expedition).
		var slot_id: String = "isl%d_%s" % [island_index, str(m.name)]
		chest.set("chest_save_id", slot_id)
		chest.set("auto_roll_loot_tier", true)
		chest.set("island_for_loot_pool", island_index)
		parent.add_child(chest)
		if chest is Node2D:
			(chest as Node2D).global_position = m.global_position
