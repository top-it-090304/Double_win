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

@export var heal_zone_dialogue: DialogueSequence
@export var heal_zone_dialogue_once: bool = true
@export var heal_zone_dialogue_pause_game: bool = false

var _heal_zone_dialogue_done: bool = false

@onready var anim = $AnimatedSprite2D
@onready var detection = $detection_area
@onready var heal_area = $heal_area
@onready var cooldown = $HealCooldown

func _ready():
	add_to_group("healer")
	detection.body_entered.connect(_on_detection)
	# Сначала диалог: иначе _heal() успевает запустить await анимации, затем пауза дерева
	# замирает на кадре и корутина _heal никогда не завершается.
	heal_area.body_entered.connect(_on_heal_zone_dialogue)
	heal_area.body_entered.connect(_on_heal_area)
	cooldown.timeout.connect(_on_cooldown)
	cooldown.one_shot = true

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


func _heal_blocked_by_dialogue() -> bool:
	if DialogueManager.is_active():
		return true
	if heal_zone_dialogue == null:
		return false
	heal_zone_dialogue.ensure_lines_ready()
	if heal_zone_dialogue.lines.is_empty():
		return false
	return not _heal_zone_dialogue_done


func _on_heal_zone_dialogue(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	if heal_zone_dialogue == null:
		return
	heal_zone_dialogue.ensure_lines_ready()
	if heal_zone_dialogue.lines.is_empty():
		return
	if heal_zone_dialogue_once and _heal_zone_dialogue_done:
		return
	if DialogueManager.is_active():
		return
	if DialogueManager.start_dialogue(heal_zone_dialogue, heal_zone_dialogue_pause_game):
		_heal_zone_dialogue_done = true
	elif not DialogueManager.is_active():
		# Не удалось запустить (пустые строки и т.д.) — не держим хилл заблокированным.
		_heal_zone_dialogue_done = true


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
