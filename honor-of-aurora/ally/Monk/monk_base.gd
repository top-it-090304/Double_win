extends CharacterBody2D

enum State { IDLE, RUN, HEAL }
var state = State.IDLE
var target_player = null
var can_heal = true

@export var speed = 150.0
@export var heal_amount = 50
@export var heal_cooldown = 3.0
@export var health = 100
@export var max_health = 60

## Порядок: сюжет (боссы, интро) → линия монаха (monk_story) → лор мира → бантер по клику/атаке после похода.
const DEFAULT_HEAL_ZONE_DIALOGUE_IDS: PackedStringArray = [
	"boss_post_1",
	"boss_post_2",
	"boss_post_3",
	"boss_post_4",
	"boss_post_5",
	"intro_base_island",
	"monk_story_1",
	"monk_story_2",
	"monk_story_3",
	"monk_story_4",
	"monk_letter_1",
	"monk_story_5",
	"monk_letter_2",
	"monk_story_6",
	"lore_crown_purse",
	"lore_crown_contract",
	"lore_order_oath",
	"lore_chain_seal",
	"lore_deaths_liturgy",
	"lore_archer_sentinel",
	"lore_gold_blood",
	"lore_return_veteran",
	"heal_banter",
]

## Если не пусто — используется вместо DEFAULT и вместо legacy heal_zone_dialogue_id.
@export var heal_zone_dialogue_ids: PackedStringArray = []
## Устаревшее: один id. Используется только если heal_zone_dialogue_ids пуст.
@export var heal_zone_dialogue_id: String = ""
@export var heal_zone_dialogue_pause_game: bool = false

@onready var anim = $AnimatedSprite2D
@onready var detection = $detection_area
@onready var heal_area = $heal_area
@onready var cooldown = $HealCooldown
@onready var talk_click_area: Area2D = $talk_click_area

## После возврата с острова: сколько раз по клику можно взять шутку (heal_banter), 3–4 за поход.
var _expedition_click_jokes_remaining: int = 0


func _ready():
	add_to_group("healer")
	call_deferred("_try_offer_heal_zone_dialogue_if_player_in_zone")
	DialogueManager.dialogue_ended.connect(_on_dialogue_ended_offer_next_in_zone)
	detection.body_entered.connect(_on_detection)
	heal_area.body_entered.connect(_on_heal_zone_dialogue)
	heal_area.body_entered.connect(_on_heal_area)
	cooldown.timeout.connect(_on_cooldown)
	cooldown.one_shot = true
	talk_click_area.input_event.connect(_on_talk_click_area_input_event)

func _physics_process(delta):
	if state == State.HEAL:
		return
		
	if target_player and is_instance_valid(target_player):
		var should_move = true
		var in_heal_zone = heal_area.overlaps_body(target_player)
		
		var health_full = false
		if target_player.has_method("is_health_full"):
			health_full = target_player.is_health_full()
		elif "health" in target_player and "max_health" in target_player:
			health_full = target_player.health >= target_player.max_health
		
		if in_heal_zone or health_full:
			should_move = false
		
		if should_move:
			var dir = global_position.direction_to(target_player.global_position)
			velocity = dir * speed
			move_and_slide()
			state = State.RUN if velocity.length() > 0 else State.IDLE
		else:
			velocity = Vector2.ZERO
			state = State.IDLE

		if in_heal_zone and can_heal and not health_full and not _heal_blocked_by_dialogue():
			_heal(target_player)
	else:
		velocity = Vector2.ZERO
		state = State.IDLE
	
	if Input.is_action_just_pressed("attack"):
		if _try_healer_interact_from_player_close():
			get_viewport().set_input_as_handled()
	
	update_animation()

func update_animation():
	match state:
		State.IDLE:
			anim.play("idle")
		State.RUN:
			anim.play("run")
			anim.flip_h = velocity.x < 0

func _on_detection(body):
	if body.is_in_group("player"):
		target_player = body


## Вызывается из GameManager после загрузки сцены базы — после возврата с острова.
func apply_pending_healer_dialogue_token() -> void:
	if not Events.pending_healer_dialogue_after_expedition:
		return
	_expedition_click_jokes_remaining = randi_range(3, 4)
	Events.pending_healer_dialogue_after_expedition = false
	_try_offer_heal_zone_dialogue_if_player_in_zone()


func _try_offer_heal_zone_dialogue_if_player_in_zone() -> void:
	if DialogueManager.is_active():
		return
	for body in heal_area.get_overlapping_bodies():
		if body.is_in_group("player"):
			_on_heal_zone_dialogue(body)
			break


func _on_dialogue_ended_offer_next_in_zone(_sequence: DialogueSequence) -> void:
	# Игрок остаётся в зоне — body_entered не сработает снова; цепочка boss_post / сюжет продолжается.
	call_deferred("_try_offer_heal_zone_dialogue_if_player_in_zone")


func _heal_zone_dialogue_ids_resolved() -> PackedStringArray:
	if not heal_zone_dialogue_ids.is_empty():
		return heal_zone_dialogue_ids
	if not heal_zone_dialogue_id.is_empty():
		return PackedStringArray([heal_zone_dialogue_id])
	return DEFAULT_HEAL_ZONE_DIALOGUE_IDS


func _pick_heal_zone_dialogue_id(for_click: bool = false) -> String:
	for d_id in _heal_zone_dialogue_ids_resolved():
		if d_id == "heal_banter":
			if not for_click:
				continue
			if _expedition_click_jokes_remaining <= 0:
				continue
		if DialogueRegistry.can_play(d_id):
			return d_id
	return ""


func _heal_blocked_by_dialogue() -> bool:
	# Блокируем только пока идёт диалог. «Ожидающий» сюжет не должен отключать лечение —
	# иначе при уже стоящем в зоне герое body_entered не срабатывает, диалог не стартует, хил вечно заблокирован.
	return DialogueManager.is_active()


func _attempt_start_heal_zone_story_dialogue(for_click: bool = false) -> bool:
	if DialogueManager.is_active():
		return false
	var d_id := _pick_heal_zone_dialogue_id(for_click)
	if d_id.is_empty() or not DialogueRegistry.can_play(d_id):
		return false
	if not DialogueRegistry.try_start(d_id, heal_zone_dialogue_pause_game):
		return false
	if d_id == "heal_banter":
		_expedition_click_jokes_remaining = maxi(0, _expedition_click_jokes_remaining - 1)
	return true


func _on_heal_zone_dialogue(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	_attempt_start_heal_zone_story_dialogue(false)


func _on_talk_click_area_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if not event is InputEventMouseButton:
		return
	var mb := event as InputEventMouseButton
	if not mb.pressed or mb.button_index != MOUSE_BUTTON_LEFT:
		return
	_try_healer_interact_from_player_close()


func _try_healer_interact_from_player_close() -> bool:
	if DialogueManager.is_active():
		return false
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null or not is_instance_valid(player):
		return false
	if not detection.overlaps_body(player):
		return false
	if _attempt_start_heal_zone_story_dialogue(true):
		return true
	return DialogueRegistry.try_start("healer_idle_fallback", heal_zone_dialogue_pause_game)


func _on_heal_area(body):
	if _heal_blocked_by_dialogue():
		return
	if not can_heal:
		return
	if body.is_in_group("player") or body.is_in_group("healer"):
		var health_full = false
		if body.has_method("is_health_full"):
			health_full = body.is_health_full()
		elif "health" in body and "max_health" in body:
			health_full = body.health >= body.max_health
		if not health_full:
			_heal(body)

func _heal(target):
	can_heal = false
	cooldown.start(heal_cooldown)
	if target.has_method("heal"):
		target.heal(heal_amount)
	elif target.has_method("take_damage"):
		target.take_damage(-heal_amount)
	if target.has_method("play_heal_effect"):
		target.play_heal_effect()
	SoundManager.play_heal()
	play_heal_effect()
	state = State.HEAL
	anim.play("heal")
	await anim.animation_finished
	state = State.IDLE

func play_heal_effect():
	if anim.sprite_frames.has_animation("heal_effect"):
		anim.play("heal_effect")
		await get_tree().create_timer(0.3).timeout
		update_animation()

func _on_cooldown():
	can_heal = true

func take_damage(amount):
	health -= amount
	if health <= 0:
		queue_free()
	elif amount > 0 and can_heal and health < max_health:
		_heal(self)
