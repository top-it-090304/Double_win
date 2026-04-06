extends Area2D
## Сундук в мире: удар (attack) в зоне, как у зданий. Лут по loot_tier, однократно по chest_save_id.

## Уникальный id. Для сброса после возврата с острова на базу используйте вид islN_имя (как у ChestSpawner).
@export var chest_save_id: String = ""
## Ярус лута и спрайта 0..5 (= ChestVisual.TIER_1 … TIER_6). Игнорируется, если включён auto_roll_loot_tier (кроме уже сохранённого ролла).
@export_range(0, 5, 1) var loot_tier: int = 0
## Случайный ярус из пула острова (см. ChestIslandConfig), один раз на chest_save_id — дальше хранится в сохранении.
@export var auto_roll_loot_tier: bool = false
## Остров 1..5 для пула наград (если не use_current_location_for_island).
@export_range(1, 5, 1) var island_for_loot_pool: int = 1
## Взять номер острова из Events.current_location после загрузки сцены (удобно для ручных сундуков на карте острова).
@export var use_current_location_for_island: bool = false
## Записки в порядке приоритета: первая ещё не найденная в сохранении выдаётся при открытии.
@export var lore_note_candidates: PackedStringArray = PackedStringArray()
## Если кандидаты исчерпаны или пусты — шанс случайной записки из ChestLoreLibrary.
@export_range(0.0, 1.0, 0.01) var bonus_random_lore_chance: float = 0.12
## Только записка / пустой лут ресурсов (например сюжетный сундук в меню).
@export var suppress_resource_loot: bool = false

var _visual: ChestVisual = null


func _ready() -> void:
	add_to_group("world_chest_zone")
	_apply_loot_tier_from_save_or_roll()
	_find_visual()
	_apply_saved_visual_state()


func _find_visual() -> void:
	_visual = null
	for c: Node in get_children():
		if c is ChestVisual:
			_visual = c as ChestVisual
			break
	if _visual:
		_visual.set_tier(clampi(loot_tier, 0, 5) as ChestVisual.ChestTier)


func _apply_saved_visual_state() -> void:
	if _visual == null:
		return
	var id := _effective_chest_id()
	if id.is_empty():
		return
	if SaveManager.is_chest_opened(id):
		_apply_opened_visual({})


func _effective_chest_id() -> String:
	return String(chest_save_id).strip_edges()


func is_player_in_open_range(player: Node2D) -> bool:
	if player == null or not is_instance_valid(player):
		return false
	if not GameplayFacade.is_player_body(player):
		return false
	if overlaps_body(player):
		return true
	return global_position.distance_to(player.global_position) <= 78.0


func is_unopened_chest() -> bool:
	var id := _effective_chest_id()
	if id.is_empty():
		return false
	return not SaveManager.is_chest_opened(id)


func _apply_loot_tier_from_save_or_roll() -> void:
	if not auto_roll_loot_tier:
		return
	var id := _effective_chest_id()
	if id.is_empty():
		return
	var saved: int = SaveManager.get_saved_chest_loot_tier(id)
	if SaveManager.is_chest_opened(id):
		if saved >= 0:
			loot_tier = saved
		return
	if saved >= 0:
		loot_tier = saved
		return
	var isl: int = island_for_loot_pool
	if use_current_location_for_island:
		isl = ChestIslandConfig.island_from_location(Events.current_location)
	var rolled: int = ChestIslandConfig.roll_loot_tier_for_island(isl)
	SaveManager.save_chest_loot_tier_roll(id, rolled)
	loot_tier = rolled
	SaveManager.request_save_game_deferred()


## Как у building_menu_zone: открытие по «атаке» внутри области.
func try_open_chest_if_player_inside() -> bool:
	if DialogueManager.is_active():
		return false
	if SquadCombatState.is_engaged():
		return false
	var id := _effective_chest_id()
	if id.is_empty():
		push_warning("WorldChest: задайте chest_save_id на %s" % get_path())
		return false
	var tree := get_tree()
	var player := tree.get_first_node_in_group("player") as Node2D
	if player == null or not is_instance_valid(player):
		return false
	if not GameplayFacade.is_player_body(player):
		return false
	if not is_player_in_open_range(player):
		return false
	if SaveManager.is_chest_opened(id):
		return false
	var loot: Dictionary
	if suppress_resource_loot:
		loot = {"gold": 0, "wood": 0, "meat": 0, "ore": 0}
	else:
		loot = ChestLootRules.roll_resources(loot_tier)
	var lore_id := _resolve_lore_note()
	if not lore_id.is_empty():
		loot["lore_note_id"] = lore_id
	else:
		loot["lore_note_id"] = ""
	_apply_loot_to_save(loot)
	SaveManager.mark_chest_opened(id)
	if not lore_id.is_empty():
		SaveManager.mark_lore_note_found(lore_id)
	SaveManager.save_game(true)
	_apply_opened_visual(loot)
	_show_feedback(loot)
	_play_loot_sound(loot)
	Events.chest_opened.emit(id, loot)
	return true


func _resolve_lore_note() -> String:
	for note_id: String in lore_note_candidates:
		var s := String(note_id).strip_edges()
		if s.is_empty():
			continue
		if not SaveManager.has_lore_note(s):
			return s
	return ChestLootRules.roll_bonus_lore_note(bonus_random_lore_chance)


func _apply_loot_to_save(loot: Dictionary) -> void:
	var g: int = maxi(0, int(loot.get("gold", 0)))
	var w: int = maxi(0, int(loot.get("wood", 0)))
	var m: int = maxi(0, int(loot.get("meat", 0)))
	var o: int = maxi(0, int(loot.get("ore", 0)))
	if g > 0:
		GameManager.add_gold_volatile(g)
	if w > 0:
		GameManager.add_wood_volatile(w)
	if m > 0:
		GameManager.add_meat_volatile(m)
	if o > 0:
		GameManager.add_ore_volatile(o)


func _play_loot_sound(loot: Dictionary) -> void:
	var g: int = maxi(0, int(loot.get("gold", 0)))
	if g > 0:
		return
	var w: int = maxi(0, int(loot.get("wood", 0)))
	var m: int = maxi(0, int(loot.get("meat", 0)))
	var o: int = maxi(0, int(loot.get("ore", 0)))
	if w + m + o > 0:
		SoundManager.play_ui_button()


func _apply_opened_visual(loot: Dictionary) -> void:
	if _visual == null:
		return
	var ore: int = maxi(0, int(loot.get("ore", 0)))
	var gold: int = maxi(0, int(loot.get("gold", 0)))
	if ore >= 2:
		_visual.show_open_gems_overflow()
	elif ore > 0:
		_visual.show_open_gems()
	elif gold >= 40:
		_visual.show_open_gold_overflow()
	elif gold > 0:
		_visual.show_open_gold()
	else:
		_visual.show_open_empty()


func _show_feedback(loot: Dictionary) -> void:
	ChestLootUi.show_loot_panel(get_tree(), loot)
