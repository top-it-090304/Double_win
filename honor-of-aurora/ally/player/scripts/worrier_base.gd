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
@export var enemy_separation_factor: float = 0.55

var attack_anim_speed_scale: float = 1.0
var move_anim_speed_scale: float = 1.0

@onready var attack_area = $AttackArea
@onready var anim = $AnimatedSprite2D
@onready var effect_sprite = $EffectSprite
@onready var collision_shape = $CollisionShape2D

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


func _ready() -> void:
	if effect_sprite:
		effect_sprite.visible = false
	super._ready()
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
	if health_bar:
		health_bar.value = current
		health_bar.max_value = max_health


func _enter_tree() -> void:
	if _player_ready:
		call_deferred("_refresh_health_bar_ui")


func _refresh_health_bar_ui() -> void:
	var bar_node = get_tree().get_first_node_in_group("player_health_bar")
	if bar_node is TextureProgressBar:
		health_bar = bar_node
	if health_bar:
		health_bar.max_value = max_health
		health_bar.value = health


func apply_armory_attack_bonus_from_manager() -> void:
	_apply_hero_tier_for_level(level)


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
	
	if state not in [State.ATTACK, State.SHIELD]:
		if MobileVirtualInput.enabled:
			dir = MobileVirtualInput.move_vector
	
	if dir != Vector2.ZERO:
		last_dir = dir
		velocity = dir * speed
	else:
		velocity = Vector2.ZERO
	var saved_velocity := velocity
	move_and_slide()
	_separate_from_overlapping_enemies()
	velocity = saved_velocity
	
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
	if DialogueManager.is_active():
		attack_just = false
	elif MobileVirtualInput.enabled:
		attack_just = MobileVirtualInput.consume_attack()
		if MobileVirtualInput.shield_held and state != State.SHIELD:
			SoundManager.play_shield_raise()
			change_state(State.SHIELD)

	if attack_just and state not in [State.ATTACK, State.SHIELD]:
		change_state(State.ATTACK)

	if state == State.SHIELD:
		if DialogueManager.is_active():
			back_to_movement()
		elif MobileVirtualInput.enabled:
			if not MobileVirtualInput.shield_held:
				back_to_movement()
		else:
			back_to_movement()
	
	update_anim()

func _separate_from_overlapping_enemies() -> void:
	if not collision_shape or not collision_shape.shape:
		return
	var space := get_world_2d().direct_space_state
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = collision_shape.shape
	query.transform = collision_shape.global_transform
	query.collision_mask = 1
	query.collide_with_bodies = true
	query.collide_with_areas = false
	query.exclude = [get_rid()]
	var hits := space.intersect_shape(query, 16)
	if hits.is_empty():
		return
	var push := Vector2.ZERO
	for hit in hits:
		var other: Node2D = hit.get("collider")
		if other == null or not other.is_in_group("enemy"):
			continue
		var away := global_position - other.global_position
		if away.length_squared() < 1e-6:
			away = Vector2(-last_dir.y, last_dir.x) if last_dir.length_squared() > 1e-6 else Vector2.RIGHT
		push += away.normalized()
	if push.length_squared() < 1e-8:
		return
	velocity = push.normalized() * speed * enemy_separation_factor
	move_and_slide()

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
			if anim.sprite_frames.has_animation("shield"):
				anim.play("shield")
			else:
				back_to_movement()

func _on_anim_finished():
	if state == State.ATTACK:
		apply_damage()
		back_to_movement()

func back_to_movement():
	state = State.RUN if velocity.length() > 0 else State.IDLE
	anim.speed_scale = move_anim_speed_scale

func update_anim():
	match state:
		State.IDLE:
			anim.speed_scale = move_anim_speed_scale
			anim.play("idle")
		State.RUN:
			anim.speed_scale = move_anim_speed_scale
			anim.play("run")
			if velocity.x != 0:
				anim.flip_h = velocity.x < 0
		State.DEATH:
			anim.speed_scale = move_anim_speed_scale
			anim.play("dead")

func take_damage(amount: Variant) -> void:
	var a: int = int(amount)
	if a < 0:
		if health_component:
			health_component.heal(-a)
		return
	var shield_factor: float = GameManager.armory_shield_damage_factor
	var final_damage: int = int(a * shield_factor) if state == State.SHIELD else a
	if state == State.SHIELD:
		SoundManager.play_shield_block()
	else:
		SoundManager.play_player_hurt()
	if health_component:
		health_component.apply_damage(final_damage)
	show_damage_number(final_damage)


func _handle_death() -> void:
	die()


func die():
	SaveManager.death_count += 1
	SoundManager.play_death()
	state = State.DEATH
	velocity = Vector2.ZERO
	anim.speed_scale = move_anim_speed_scale
	anim.play("dead")
	await anim.animation_finished
	SaveManager.configure_death_resume_to_base_teleport()
	Events.location_changed.emit(Events.LOCATION.MENU)


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
	
func apply_damage():
	for body in attack_area.get_overlapping_bodies():
		if body.is_in_group("enemy"):
			GameplayFacade.try_apply_damage(body, attack_damage)

func show_damage_number(amount: int) -> void:
	GameplayFacade.spawn_damage_number(self, amount, Vector2(-26, -120))

func heal(amount: int) -> void:
	if health_component:
		health_component.heal(amount)
	SaveManager.current_health = health_component.current_health if health_component else 0
	_clear_resume_from_death_if_needed()
	SaveManager.save_game()
	health_changed.emit(health)

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
	SaveManager.current_health = health_component.current_health if health_component else 0
	_clear_resume_from_death_if_needed()
	SaveManager.save_game()
	
func gain_exp(amount: int):
	exp += amount
	
	while exp >= get_exp_to_next_level():
		exp -= get_exp_to_next_level()
		level += 1
		level_up()
	
	SaveManager.current_level = level
	SaveManager.current_exp = exp
	SaveManager.save_game()
	


func get_exp_to_next_level() -> int:
	return level * 100


func level_up():
	_apply_hero_tier_for_level(level)
	if health_component:
		health_component.set_current_health(max_health)
	SaveManager.current_health = health_component.current_health if health_component else 0
	_clear_resume_from_death_if_needed()
	_refresh_health_bar_ui()
	SoundManager.play_level_up()
	play_level_up_effect()


func _apply_hero_tier_for_level(hero_level: int) -> void:
	var tier := HeroProgression.get_tier_for_level(hero_level)
	anim.sprite_frames = tier.sprite_frames
	speed = tier.speed
	max_health = tier.max_health
	attack_damage = tier.attack_damage + GameManager.armory_attack_bonus
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
			if anim.sprite_frames.has_animation("shield"):
				anim.play("shield")
			else:
				back_to_movement()
		elif state in [State.IDLE, State.RUN]:
			update_anim()
