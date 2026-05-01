extends "res://characters/player_character.gd"
## Игрок-воин: PlayerCharacter + мобильный ввод, щит, прогрессия героя.

enum State { IDLE, RUN, ATTACK, SHIELD, DEATH }
var state: State = State.IDLE
var last_dir: Vector2 = Vector2.DOWN
var health_bar: TextureProgressBar
var level: int = 1
var exp: int = 0


@export var speed: float = 250.0
@export var max_health: int = 120
@export var attack_damage: int = 90

var attack_anim_speed_scale: float = 1.0
var move_anim_speed_scale: float = 1.0

@onready var attack_area = $AttackArea
@onready var anim = $AnimatedSprite2D
@onready var effect_sprite = $EffectSprite

signal health_changed(current_health)

## Текущее HP (зеркало HealthComponent для совместимости и UI).
var health: int:
	get:
		return health_component.current_health if health_component else 0
	set(value):
		if health_component:
			health_component.set_current_health(int(value))

var attack_index = 0
var _player_ready: bool = false
var _footstep_cooldown: float = 0.0
## После закрытия окна приказов отряду: игнорировать attack несколько кадров (ЛКМ с UI попадает в игру).
var _squad_ui_attack_suppress_sec: float = 0.0
## Отладка: не писать HP в SaveManager при heal / level up без сохранения.
var _suppress_health_save: bool = false
## Направление молнии шамана: блокирует движение и атаки.
var _paralysis_time: float = 0.0


func _player_input_frozen() -> bool:
	return DialogueManager.is_active() or PostFinaleWorld.player_movement_locked


## Не вызывать play() каждый physics-кадр: в части конфигураций движка это сбрасывает кадр и даёт мерцание / «залипание» на первых фреймах.
func _play_move_loop(anim_name: StringName) -> void:
	if anim == null:
		return
	anim.speed_scale = move_anim_speed_scale
	if anim.animation != anim_name:
		anim.play(anim_name)


func _ready() -> void:
	if effect_sprite:
		effect_sprite.visible = false
	super._ready()
	## В Godot 4.5+ можно задать anim.process_callback = IDLE, чтобы не привязывать кадры к physics_tick.
	## В 4.4 этого API нет — плавность даёт common/physics_interpolation и пресеты FPS/физики.
	level = SaveManager.current_level
	exp = SaveManager.current_exp
	_apply_hero_tier_for_level(level)
	_sync_health_after_tier()
	_refresh_health_bar_ui()
	anim.animation_finished.connect(_on_anim_finished)
	health_changed.connect(_on_health_changed)
	if health_component:
		health_component.health_changed.connect(_on_health_component_health_changed)
	_player_ready = true
	_ensure_attack_action_has_default_events()
	if attack_area:
		attack_area.monitoring = true
	if not Events.squad_orders_menu_closed.is_connected(_on_squad_orders_menu_closed):
		Events.squad_orders_menu_closed.connect(_on_squad_orders_menu_closed)


func _ensure_attack_action_has_default_events() -> void:
	if not InputMap.has_action("attack"):
		InputMap.add_action("attack")
	if not InputMap.action_get_events("attack").is_empty():
		return
	var mb := InputEventMouseButton.new()
	mb.button_index = MOUSE_BUTTON_LEFT
	InputMap.action_add_event("attack", mb)
	var k := InputEventKey.new()
	k.keycode = KEY_SPACE
	InputMap.action_add_event("attack", k)


func _apply_save_health_to_component() -> void:
	if health_component == null:
		return
	health_component.set_max_health(max_health)
	var h: int = SaveManager.current_health
	if h <= 1 and max_health > 1 and not SaveManager.resume_from_death:
		h = max_health
		SaveManager.current_health = h
	health_component.set_current_health(mini(h, max_health))


func _sync_health_after_tier() -> void:
	_apply_save_health_to_component()


func _clear_resume_from_death_if_needed() -> void:
	if SaveManager.current_health > 1:
		SaveManager.resume_from_death = false


func _on_health_component_health_changed(current: int, _maximum: int) -> void:
	health_changed.emit(current)
	if health_bar != null and is_instance_valid(health_bar):
		health_bar.value = current
		health_bar.max_value = max_health


func _enter_tree() -> void:
	if _player_ready:
		call_deferred("_refresh_health_bar_ui")


func _refresh_health_bar_ui() -> void:
	var tree := get_tree()
	if tree == null:
		return
	var bar_node := tree.get_first_node_in_group("player_health_bar")
	if bar_node is TextureProgressBar:
		health_bar = bar_node
	if health_bar:
		health_bar.max_value = max_health
		health_bar.value = health


func apply_armory_attack_bonus_from_manager() -> void:
	_apply_hero_tier_for_level(level)


## Пересчитать скорость/макс. HP с учётом SaveManager.hero_*_bonus (после правок в отладке).
func apply_hero_stat_bonuses_from_save() -> void:
	_apply_hero_tier_for_level(level)
	_refresh_health_bar_ui()


## Отладка: +к макс. HP (сохраняется), полоска заполняется до нового максимума.
func debug_add_max_hp_and_fill(amount: int) -> void:
	if amount <= 0:
		return
	SaveManager.hero_max_health_bonus += amount
	_apply_hero_tier_for_level(level)
	if health_component:
		health_component.set_current_health(max_health)
	SaveManager.current_health = health_component.current_health if health_component else 0
	_clear_resume_from_death_if_needed()
	SaveManager.request_save_game_deferred()
	_refresh_health_bar_ui()
	health_changed.emit(health)


## Текущее HP = макс. (сохранение на диск).
func fill_health_to_max_persistent() -> void:
	if health_component == null:
		return
	_apply_hero_tier_for_level(level)
	health_component.set_current_health(max_health)
	SaveManager.current_health = max_health
	_clear_resume_from_death_if_needed()
	SaveManager.request_save_game_deferred()
	_refresh_health_bar_ui()
	health_changed.emit(health)


func sync_from_save() -> void:
	level = SaveManager.current_level
	exp = SaveManager.current_exp
	_apply_hero_tier_for_level(level)
	_apply_save_health_to_component()
	_refresh_health_bar_ui()


func _physics_process(delta):
	var dir = Vector2.ZERO
	
	if state == State.DEATH:
		move_and_slide()
		return

	## Диалог: мир не на паузе, но герой стоит в idle без движения и ударов.
	if _player_input_frozen():
		velocity = Vector2.ZERO
		state = State.IDLE
		_play_move_loop(&"idle")
		move_and_slide()
		return
	
	if _squad_ui_attack_suppress_sec > 0.0:
		_squad_ui_attack_suppress_sec = maxf(0.0, _squad_ui_attack_suppress_sec - delta)

	if _paralysis_time > 0.0:
		_paralysis_time = maxf(0.0, _paralysis_time - delta)
		if state == State.SHIELD:
			back_to_movement()
		state = State.IDLE
		velocity = Vector2.ZERO
		_play_move_loop(&"idle")
		move_and_slide()
		return
	
	if state not in [State.ATTACK, State.SHIELD]:
		if not _player_input_frozen():
			if MobileVirtualInput.enabled:
				dir = MobileVirtualInput.move_vector
			## Дополнительно к сенсору: WASD / стрелки (действия move_* задаёт GameManager при старте).
			var kb := Input.get_vector("move_left", "move_right", "move_up", "move_down")
			if kb.length_squared() > 0.0001:
				dir = kb
	
	if dir != Vector2.ZERO:
		last_dir = dir
		velocity = dir * speed
	else:
		velocity = Vector2.ZERO
	_apply_soft_separation_to_velocity(delta)
	var saved_velocity := velocity
	move_and_slide()
	
	if state not in [State.ATTACK, State.SHIELD]:
		state = State.RUN if velocity.length() > 0 else State.IDLE
	
	if state == State.RUN and velocity.length() > 0.5:
		_footstep_cooldown -= delta
		if _footstep_cooldown <= 0.0:
			SoundManager.play_footstep()
			_footstep_cooldown = randf_range(0.28, 0.42)
	else:
		_footstep_cooldown = 0.0
	
	var attack_just := false
	if _player_input_frozen():
		attack_just = false
	elif ChestLootUi.is_chest_popup_open():
		attack_just = false
	elif MobileVirtualInput.enabled:
		attack_just = MobileVirtualInput.has_attack_pending()
		if MobileVirtualInput.shield_held and state != State.SHIELD:
			MobileVirtualInput.consume_attack()
			SoundManager.play_shield_raise()
			change_state(State.SHIELD)
	else:
		attack_just = Input.is_action_just_pressed("attack")

	if _squad_ui_attack_suppress_sec > 0.0:
		attack_just = false

	if attack_just and state not in [State.ATTACK, State.SHIELD]:
		## Сюжетный рабочий: набор в отряд / меню приказов по удару (интро и периодика — только из зоны).
		if _try_story_priority_instead_of_attack():
			if MobileVirtualInput.enabled:
				MobileVirtualInput.consume_attack()
			return
		## Как у монаха: взаимодействие с отрядом — без анимации удара, только окно приказов.
		if not _try_squad_orders_instead_of_attack():
			if _try_healer_interact_instead_of_attack():
				if MobileVirtualInput.enabled:
					MobileVirtualInput.consume_attack()
				return
			if _try_world_chest_instead_of_attack():
				if MobileVirtualInput.enabled:
					MobileVirtualInput.consume_attack()
				return
			if _try_building_menu_instead_of_attack():
				if MobileVirtualInput.enabled:
					MobileVirtualInput.consume_attack()
				return
			if MobileVirtualInput.enabled:
				MobileVirtualInput.consume_attack()
			_try_auto_target_easy()
			change_state(State.ATTACK)

	if state == State.SHIELD:
		if _player_input_frozen():
			back_to_movement()
		elif MobileVirtualInput.enabled:
			if not MobileVirtualInput.shield_held:
				back_to_movement()
		else:
			back_to_movement()
	
	update_anim()

func change_state(new_state: State):
	if state == new_state: return
	state = new_state
	
	match state:
		State.ATTACK:
			SoundManager.play_attack_swing()
			var anim_name = "attack_1"
			if abs(last_dir.y) > abs(last_dir.x):
				anim_name = "attack_1" if last_dir.y > 0 else "attack_2"
			else:
				attack_index = (attack_index + 1) % 2
				anim_name = "attack_1" if attack_index == 0 else "attack_2"
			
			anim.flip_h = last_dir.x < 0 or last_dir.y > 0
			anim.speed_scale = attack_anim_speed_scale
			anim.play(anim_name)
		
		State.SHIELD:
			velocity = Vector2.ZERO
			anim.speed_scale = move_anim_speed_scale
			if Haptics != null:
				Haptics.pulse_light()
			if anim.sprite_frames and anim.sprite_frames.has_animation("shield"):
				anim.play("shield")
			else:
				back_to_movement()

func _on_anim_finished():
	if state == State.ATTACK:
		## Сначала выйти из ATTACK, потом урон/смерть врага — меньше реентерабельности с add_exp (см. GameManager).
		back_to_movement()
		apply_damage()

func back_to_movement():
	state = State.RUN if velocity.length() > 0 else State.IDLE
	anim.speed_scale = move_anim_speed_scale

func update_anim():
	match state:
		State.IDLE:
			_play_move_loop(&"idle")
		State.RUN:
			_play_move_loop(&"run")
			if velocity.x != 0:
				anim.flip_h = velocity.x < 0
		State.DEATH:
			anim.speed_scale = move_anim_speed_scale
			if anim.animation != &"dead":
				anim.play(&"dead")

func take_damage(amount: Variant) -> void:
	var a: int = int(amount)
	if a < 0:
		if health_component:
			health_component.heal(-a)
		return
	if a > 0:
		var brk: float = BalanceConfig.get_armor_broken_incoming_damage_mult(CrownSystem.get_armor_durability())
		if brk > 1.0:
			a = maxi(1, int(round(float(a) * brk)))
	var shield_factor: float = minf(0.95, GameManager.armory_shield_damage_factor + CrownSystem.get_armor_block_penalty())
	shield_factor = clampf(shield_factor, 0.0, 1.0)
	var final_damage: int = int(a * shield_factor) if state == State.SHIELD else a
	if state == State.SHIELD:
		SoundManager.play_shield_block()
	else:
		SoundManager.play_player_hurt()
		## Вибрация: на Android Input.vibrate_handheld даёт нативный вылет на части устройств (даже call_deferred).
		if SaveManager.haptic_enabled and final_damage > 0 and OS.get_name() == "iOS":
			call_deferred("_play_hurt_haptic_safe")
	if health_component:
		health_component.apply_damage(final_damage)
	if a > 0:
		CrownSystem.apply_armor_wear_on_hit_taken()
	show_damage_number(final_damage)


func _play_hurt_haptic_safe() -> void:
	if not SaveManager.haptic_enabled or not is_instance_valid(self) or not is_inside_tree():
		return
	if OS.get_name() != "iOS":
		return
	Input.vibrate_handheld(32)


func _handle_death() -> void:
	die()


func die():
	SaveManager.death_count += 1
	if EasyHints != null:
		EasyHints.notify_player_death(int(Events.current_location))
	SoundManager.play_death()
	state = State.DEATH
	velocity = Vector2.ZERO
	anim.speed_scale = move_anim_speed_scale
	anim.play("dead")
	await anim.animation_finished
	SaveManager.configure_death_resume_to_base_teleport()
	GameManager.defer_location_changed(Events.LOCATION.MENU)


func reset_after_death_resume() -> void:
	state = State.IDLE
	velocity = Vector2.ZERO
	if health_component:
		health_component.set_current_health(mini(SaveManager.current_health, max_health))
	health_changed.emit(health)
	SaveManager.current_health = health_component.current_health if health_component else 0
	if anim:
		anim.speed_scale = move_anim_speed_scale
		anim.play("idle")
	_refresh_health_bar_ui()
	
func _on_squad_orders_menu_closed() -> void:
	_squad_ui_attack_suppress_sec = maxf(_squad_ui_attack_suppress_sec, 0.35)


func _try_story_priority_instead_of_attack() -> bool:
	if _player_input_frozen():
		return false
	if SquadCombatState.is_engaged():
		return false
	for body in attack_area.get_overlapping_bodies():
		if body == null or not is_instance_valid(body):
			continue
		if body.has_method("try_open_priority_story_dialog"):
			if body.try_open_priority_story_dialog():
				return true
	return false


func _try_squad_orders_instead_of_attack() -> bool:
	if _player_input_frozen():
		return false
	if SquadCombatState.is_engaged():
		return false
	for body in attack_area.get_overlapping_bodies():
		if body == null or not is_instance_valid(body):
			continue
		if body.is_in_group("squad_member"):
			if body.has_method("is_pawn_in_ore_mine") and body.is_pawn_in_ore_mine():
				continue
			var hud: Node = GameplayFacade.get_hud(get_tree())
			if hud and hud.has_method("try_open_squad_orders_menu"):
				return hud.try_open_squad_orders_menu(body as Node2D)
	return false


func _try_healer_interact_instead_of_attack() -> bool:
	if _player_input_frozen():
		return false
	for node in get_tree().get_nodes_in_group("healer"):
		if node.has_method("try_open_interact_dialog"):
			if node.try_open_interact_dialog():
				return true
	## Юноша-рабочий: то же, что выше по приоритету; дублирующий проход на случай порядка групп.
	for node in get_tree().get_nodes_in_group("dock_youth_interact"):
		if node.has_method("try_open_interact_dialog"):
			if node.try_open_interact_dialog():
				return true
	for node in get_tree().get_nodes_in_group("veteran_npc"):
		if node.has_method("try_open_interact_dialog"):
			if node.try_open_interact_dialog():
				return true
	return false


func _try_world_chest_instead_of_attack() -> bool:
	if _player_input_frozen():
		return false
	if SquadCombatState.is_engaged_near_player():
		return false
	var tree := get_tree()
	var player := tree.get_first_node_in_group("player") as Node2D
	if player == null or not is_instance_valid(player):
		return false
	var best: Node = null
	var best_d2: float = INF
	for node in tree.get_nodes_in_group("world_chest_zone"):
		if not node.has_method("is_player_in_open_range"):
			continue
		if not bool(node.call("is_player_in_open_range", player)):
			continue
		if node.has_method("is_unopened_chest") and not bool(node.call("is_unopened_chest")):
			continue
		var n2 := node as Node2D
		if n2 == null:
			continue
		var d2: float = player.global_position.distance_squared_to(n2.global_position)
		if d2 < best_d2:
			best_d2 = d2
			best = node
	if best == null:
		return false
	return bool(best.call("try_open_chest_if_player_inside"))


func _try_building_menu_instead_of_attack() -> bool:
	if _player_input_frozen():
		return false
	for node in get_tree().get_nodes_in_group("building_menu_zone"):
		if node.has_method("try_open_menu_if_player_inside"):
			if node.try_open_menu_if_player_inside():
				return true
	return false


func apply_damage():
	if attack_area == null or not is_instance_valid(attack_area):
		return
	var hit_any := false
	for body in attack_area.get_overlapping_bodies():
		if body == null or not is_instance_valid(body):
			continue
		if body.is_in_group("enemy") or body.is_in_group("base_sheep"):
			GameplayFacade.try_apply_damage(body, attack_damage)
			hit_any = true
	if hit_any and Haptics != null:
		Haptics.pulse_medium()


## Авто-цель ближайшего врага в attack_area: только на «Лёгком». Меняет last_dir, чтобы
## анимация удара и его направление пошли в нужного противника. Радиус и физика боя не меняются.
func _try_auto_target_easy() -> void:
	if DifficultyConfig == null or not DifficultyConfig.is_easy():
		return
	if attack_area == null or not is_instance_valid(attack_area):
		return
	var best_body: Node2D = null
	var best_d_sq: float = INF
	for body in attack_area.get_overlapping_bodies():
		if body == null or not is_instance_valid(body):
			continue
		if not body.is_in_group("enemy"):
			continue
		if body is Node2D:
			var d_sq: float = (body as Node2D).global_position.distance_squared_to(global_position)
			if d_sq < best_d_sq:
				best_d_sq = d_sq
				best_body = body as Node2D
	if best_body == null:
		return
	## Контекстный онбординг: первый замеченный «красный» враг (уровень выше героя) — показать тост.
	if EasyHints != null and "enemy_level" in best_body:
		var hero_lv := int(SaveManager.current_level)
		var enemy_lv := int(best_body.get("enemy_level"))
		if enemy_lv > hero_lv:
			EasyHints.notify_red_enemy_seen()
	var to_target: Vector2 = best_body.global_position - global_position
	if to_target.length_squared() < 0.001:
		return
	last_dir = to_target.normalized()

func show_damage_number(amount: int) -> void:
	GameplayFacade.spawn_damage_number(self, amount, Vector2(-26, -120))

func heal(amount: int, persist: bool = true) -> void:
	if not persist:
		_suppress_health_save = true
	if health_component:
		health_component.heal(amount)
	if persist:
		SaveManager.current_health = health_component.current_health if health_component else 0
		_clear_resume_from_death_if_needed()
		SaveManager.request_save_game_deferred()
	health_changed.emit(health)
	if not persist:
		_suppress_health_save = false


func fill_health_volatile() -> void:
	if health_component == null:
		return
	_suppress_health_save = true
	health_component.set_current_health(max_health)
	health_changed.emit(health)
	_suppress_health_save = false

func play_heal_effect():
	if effect_sprite.sprite_frames.has_animation("heal_effect"):
		effect_sprite.visible = true
		effect_sprite.flip_h = anim.flip_h
		effect_sprite.play("heal_effect")
		await effect_sprite.animation_finished
		effect_sprite.visible = false


func play_level_up_effect():
	if not effect_sprite or not effect_sprite.sprite_frames.has_animation("level_up"):
		return
	effect_sprite.visible = true
	effect_sprite.flip_h = anim.flip_h
	effect_sprite.play("level_up")
	await effect_sprite.animation_finished
	effect_sprite.visible = false

func _on_health_changed(_current_health):
	if _suppress_health_save:
		return
	SaveManager.current_health = health_component.current_health if health_component else 0
	_clear_resume_from_death_if_needed()
	SaveManager.request_save_game_deferred()
	_update_low_hp_warning()


## UX: при HP <= 30% (но >0) — короткий бип-сигнал и контекстная подсказка про привал.
## Сигнал даётся один раз за «вход в зону низкого HP», следующий — только после восстановления.
var _low_hp_zone_armed: bool = true

func _update_low_hp_warning() -> void:
	if health_component == null:
		return
	var cur := int(health_component.current_health)
	var maxv := int(max_health)
	if maxv <= 0:
		return
	var ratio := float(cur) / float(maxv)
	if cur > 0 and ratio <= 0.3:
		if _low_hp_zone_armed:
			_low_hp_zone_armed = false
			if SoundManager and SoundManager.has_method("play_ui_button"):
				SoundManager.play_ui_button()
			if EasyHints != null:
				EasyHints.notify_low_hp()
	elif ratio >= 0.55:
		_low_hp_zone_armed = true
	
func apply_paralysis(duration_sec: float) -> void:
	_paralysis_time = maxf(_paralysis_time, duration_sec)


func gain_exp(amount: int, persist: bool = true):
	if not persist:
		_suppress_health_save = true
	exp += amount

	var levels_gained := 0
	while level < BalanceConfig.MAX_HERO_LEVEL:
		var need: int = get_exp_to_next_level()
		if need <= 0 or exp < need:
			break
		exp -= need
		level += 1
		levels_gained += 1
		level_up(persist)

	if levels_gained > 0:
		GameManager.playtest_report_level_up(levels_gained)

	if level >= BalanceConfig.MAX_HERO_LEVEL:
		exp = 0

	if persist:
		SaveManager.current_level = level
		SaveManager.current_exp = exp
		SaveManager.request_save_game_deferred()
	if not persist:
		_suppress_health_save = false


func get_exp_to_next_level() -> int:
	return BalanceConfig.get_exp_to_next_level(level)


func level_up(persist: bool = true):
	_apply_hero_tier_for_level(level)
	if health_component:
		health_component.set_current_health(max_health)
	if persist:
		SaveManager.current_health = health_component.current_health if health_component else 0
		_clear_resume_from_death_if_needed()
	_refresh_health_bar_ui()
	SoundManager.play_level_up()
	play_level_up_effect()


func _apply_hero_tier_for_level(hero_level: int) -> void:
	var tier := HeroProgression.get_tier_for_level(hero_level)
	anim.sprite_frames = tier.sprite_frames
	speed = (
		tier.speed
		+ SaveManager.hero_speed_bonus
		+ BalanceConfig.get_crown_combat_speed_bonus(SaveManager.ore_sent_to_crown_total)
	)
	max_health = (
		tier.max_health
		+ SaveManager.hero_max_health_bonus
		+ BalanceConfig.get_crown_combat_hp_bonus(SaveManager.ore_sent_to_crown_total)
	)
	max_health = int(round(float(max_health) * GameManager.get_monastery_hp_multiplier()))
	var crown_dmg := BalanceConfig.get_crown_combat_hero_damage_mult(SaveManager.ore_sent_to_crown_total)
	attack_damage = maxi(1, int(round(float(tier.attack_damage + GameManager.armory_attack_bonus) * crown_dmg)))
	attack_anim_speed_scale = tier.attack_anim_speed_scale
	move_anim_speed_scale = tier.move_anim_speed_scale
	if health_component:
		health_component.set_max_health(max_health)
		health_component.set_current_health(mini(health_component.current_health, max_health))
	if state != State.DEATH:
		anim.speed_scale = move_anim_speed_scale
		if state == State.ATTACK:
			anim.speed_scale = attack_anim_speed_scale
		elif state == State.SHIELD:
			if anim.sprite_frames and anim.sprite_frames.has_animation("shield"):
				anim.play("shield")
			else:
				back_to_movement()
		elif state in [State.IDLE, State.RUN]:
			update_anim()
