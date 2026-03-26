extends Control
## Окно отладки (F3): читы для тестирования. Стиль как у меню замка.

const GOLD_ADD := 1000
const WOOD_ADD := 500
const MEAT_ADD := 50
const ORE_ADD := 25
const HP_ADD := 50
const DAMAGE_ADD := 10
const EXP_ADD := 5000
const SPEED_ADD := 80.0


func _ready() -> void:
	theme = GameUITheme.create_theme()
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process_input(true)


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		_close_debug()
		get_viewport().set_input_as_handled()


func _get_hero() -> Node:
	return get_tree().get_first_node_in_group("player")


func _close_debug() -> void:
	var hud := GameplayFacade.get_hud(get_tree())
	if hud and hud.has_method("hide_debug_menu"):
		hud.hide_debug_menu()


func _on_back_pressed() -> void:
	SoundManager.play_ui_button()
	_close_debug()


func _on_gold_pressed() -> void:
	SoundManager.play_ui_button()
	GameManager.add_gold_volatile(GOLD_ADD)


func _on_wood_pressed() -> void:
	SoundManager.play_ui_button()
	GameManager.add_wood_volatile(WOOD_ADD)


func _on_meat_pressed() -> void:
	SoundManager.play_ui_button()
	GameManager.add_meat_volatile(MEAT_ADD)


func _on_ore_pressed() -> void:
	SoundManager.play_ui_button()
	GameManager.add_ore_volatile(ORE_ADD)


func _on_hp_pressed() -> void:
	SoundManager.play_ui_button()
	var p := _get_hero()
	if p == null:
		return
	if p.has_method("debug_add_max_hp_and_fill"):
		p.debug_add_max_hp_and_fill(HP_ADD)


func _on_damage_pressed() -> void:
	SoundManager.play_ui_button()
	var p := _get_hero()
	if p == null:
		return
	if p.has_method("gain_exp"):
		p.attack_damage += DAMAGE_ADD


func _on_level_pressed() -> void:
	SoundManager.play_ui_button()
	var p := _get_hero()
	if p == null:
		return
	if p.level >= BalanceConfig.MAX_HERO_LEVEL:
		return
	if p.has_method("gain_exp") and p.has_method("get_exp_to_next_level"):
		p.gain_exp(p.get_exp_to_next_level(), true)


func _on_exp_pressed() -> void:
	SoundManager.play_ui_button()
	GameManager.add_exp(EXP_ADD)


func _on_reset_deaths_pressed() -> void:
	SoundManager.play_ui_button()
	SaveManager.death_count = 0


func _on_clear_enemies_pressed() -> void:
	SoundManager.play_ui_button()
	for n in get_tree().get_nodes_in_group("enemy"):
		if is_instance_valid(n) and n.has_method("take_damage"):
			n.take_damage(999999)


func _on_speed_pressed() -> void:
	SoundManager.play_ui_button()
	SaveManager.hero_speed_bonus += SPEED_ADD
	var p := _get_hero()
	if p != null and p.has_method("apply_hero_stat_bonuses_from_save"):
		p.apply_hero_stat_bonuses_from_save()
	SaveManager.save_game()


func _on_reset_like_new_game_pressed() -> void:
	SoundManager.play_ui_button()
	SaveManager.reset_data()
	GameManager.reset_armory_preparation()
	Events.gold_changed.emit(SaveManager.gold)
	Events.ore_changed.emit(SaveManager.ore_count)
	Events.sync_story_state_from_save()
	var p := _get_hero()
	if p != null and p.has_method("sync_from_save"):
		p.sync_from_save()
	if p != null and p.has_method("apply_armory_attack_bonus_from_manager"):
		p.apply_armory_attack_bonus_from_manager()
