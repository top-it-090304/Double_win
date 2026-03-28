extends CharacterBody2D
## Дерево из `wood_zone`: случайная анимация tree_1…tree_4, рубка → dead, на земле бревно с анимацией wood (подбор пешкой).

const PICKUP_SCRIPT := preload("res://objects/world/wood_floor_pickup.gd")

enum _State { READY, CHOPPING, DYING }

var _state: _State = _State.READY

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	add_to_group("wood_job_tree")
	add_to_group("y_sortable")
	if _sprite == null:
		push_error("WoodZoneTree: нет AnimatedSprite2D.")
		return
	var variants: Array[StringName] = [&"tree_1", &"tree_2", &"tree_3", &"tree_4"]
	var chosen: StringName = variants[randi() % variants.size()]
	if _sprite.sprite_frames != null and _sprite.sprite_frames.has_animation(chosen):
		_sprite.play(chosen)
	else:
		push_warning("WoodZoneTree: нет анимации %s в SpriteFrames." % String(chosen))


func is_ready_for_worker() -> bool:
	return _state == _State.READY


func begin_chop() -> void:
	if _state != _State.READY:
		return
	_state = _State.CHOPPING


func cancel_chop() -> void:
	if _state != _State.CHOPPING:
		return
	_state = _State.READY


func finish_chop() -> Node2D:
	if _state != _State.CHOPPING:
		return null
	_state = _State.DYING
	var p := get_parent()
	var log_pickup := _create_wood_log_pickup()
	if p == null:
		log_pickup.queue_free()
		return null
	p.add_child(log_pickup)
	log_pickup.global_position = global_position
	if _sprite and _sprite.sprite_frames and _sprite.sprite_frames.has_animation(&"dead"):
		_sprite.play(&"dead")
		if not _sprite.animation_finished.is_connected(_on_dead_finished):
			_sprite.animation_finished.connect(_on_dead_finished, CONNECT_ONE_SHOT)
	else:
		queue_free()
	return log_pickup


func _create_wood_log_pickup() -> Area2D:
	var log := Area2D.new()
	log.collision_layer = 0
	log.collision_mask = 8
	log.monitoring = true
	log.monitorable = true
	log.set_script(PICKUP_SCRIPT)
	var spr := AnimatedSprite2D.new()
	spr.sprite_frames = _sprite.sprite_frames
	if spr.sprite_frames != null and spr.sprite_frames.has_animation(&"wood"):
		spr.play(&"wood")
	spr.position = Vector2(0, -8)
	log.add_child(spr)
	var cs := CollisionShape2D.new()
	var circ := CircleShape2D.new()
	circ.radius = 36.0
	cs.shape = circ
	log.add_child(cs)
	return log


func _on_dead_finished() -> void:
	queue_free()


func get_y_sort_bottom_y() -> float:
	var y := YSortSpriteBounds.max_global_y_from_descendants(self)
	if not is_nan(y):
		return y
	if _sprite == null or _sprite.sprite_frames == null:
		return global_position.y
	var anim := _sprite.animation
	if not _sprite.sprite_frames.has_animation(anim):
		return global_position.y
	var frame_idx := maxi(0, _sprite.frame)
	var tex := _sprite.sprite_frames.get_frame_texture(anim, frame_idx)
	if tex == null:
		return global_position.y
	var h := float(tex.get_height()) * absf(_sprite.global_scale.y)
	return _sprite.global_position.y + h * 0.5
