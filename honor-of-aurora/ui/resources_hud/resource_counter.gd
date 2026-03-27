extends NinePatchRect
## Единый HUD счётчик ресурсов: SaveManager + Events (одинаковая логика для золота, мяса, дерева, руды).
## resource_slot: 0 золото, 1 мясо, 2 дерево, 3 руда (int — надёжная сериализация в .tscn, без enum).

@export_range(0, 3) var resource_slot: int = 0

var _label: Label


func _ready() -> void:
	## Если в .tscn resource_slot был задан до script=, движок отбрасывает свойство — слот остаётся 0.
	## Тогда все инстансы ищут GoldLabel: только у золота он есть, остальные HUD не обновляются.
	if not _has_label_for_slot(resource_slot):
		resource_slot = _infer_slot_from_child_labels()
	_label = _resolve_label()
	match resource_slot:
		0:
			Events.gold_changed.connect(_on_value_changed)
		1:
			Events.meat_changed.connect(_on_value_changed)
		2:
			Events.wood_changed.connect(_on_value_changed)
		3:
			Events.ore_changed.connect(_on_value_changed)
		_:
			push_warning("resource_counter: resource_slot must be 0..3")
	call_deferred("_sync_initial_from_save")


func _has_label_for_slot(slot: int) -> bool:
	match slot:
		0:
			return has_node("GoldLabel")
		1:
			return has_node("MeatLabel")
		2:
			return has_node("WoodLabel")
		3:
			return has_node("OreLabel")
	return false


func _infer_slot_from_child_labels() -> int:
	if has_node("GoldLabel"):
		return 0
	if has_node("MeatLabel"):
		return 1
	if has_node("WoodLabel"):
		return 2
	if has_node("OreLabel"):
		return 3
	return 0


func _resolve_label() -> Label:
	match resource_slot:
		0:
			return get_node_or_null("GoldLabel") as Label
		1:
			return get_node_or_null("MeatLabel") as Label
		2:
			return get_node_or_null("WoodLabel") as Label
		3:
			return get_node_or_null("OreLabel") as Label
	return null


func _sync_initial_from_save() -> void:
	if _label == null:
		_label = _resolve_label()
	match resource_slot:
		0:
			_on_value_changed(SaveManager.gold)
		1:
			_on_value_changed(SaveManager.meat_count)
		2:
			_on_value_changed(SaveManager.wood_count)
		3:
			_on_value_changed(SaveManager.ore_count)


func _on_value_changed(new_value: int) -> void:
	if _label:
		_label.text = str(new_value)
