extends Control
## Окно отладки (F3): только UI. Логика — debug/debug_menu_actions.gd → те же API, что геймплей (GameManager).

const _ActionsScript := preload("res://debug/debug_menu_actions.gd")

const GOLD_ADD := 1000
const WOOD_ADD := 500
const MEAT_ADD := 50
const ORE_ADD := 25
const HP_ADD := 50
const DAMAGE_ADD := 10
const EXP_ADD := 5000
const SPEED_ADD := 80.0

var _actions: RefCounted


func _ready() -> void:
	_actions = _ActionsScript.new()
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
	_actions.grant_gold(GOLD_ADD)


func _on_wood_pressed() -> void:
	SoundManager.play_ui_button()
	_actions.grant_wood(WOOD_ADD)


func _on_meat_pressed() -> void:
	SoundManager.play_ui_button()
	_actions.grant_meat(MEAT_ADD)


func _on_ore_pressed() -> void:
	SoundManager.play_ui_button()
	_actions.grant_ore(ORE_ADD)


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
	_actions.grant_exp(EXP_ADD)


func _on_reset_deaths_pressed() -> void:
	SoundManager.play_ui_button()
	_actions.reset_death_count()


func _on_clear_enemies_pressed() -> void:
	SoundManager.play_ui_button()
	for n in get_tree().get_nodes_in_group("enemy"):
		if is_instance_valid(n) and n.has_method("take_damage"):
			n.take_damage(999999)


func _on_speed_pressed() -> void:
	SoundManager.play_ui_button()
	_actions.add_hero_speed_bonus(SPEED_ADD)


func _on_reset_like_new_game_pressed() -> void:
	SoundManager.play_ui_button()
	_actions.apply_progress_reset_like_new_game()
