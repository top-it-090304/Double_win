extends Node2D
## Дерево для рабочего лесоруба: idle (как тайлы острова), рубка → анимация dead (как у героя), бревно на земле.

const WOOD_LOG_SCENE := preload("res://objects/world/wood_floor_pickup.tscn")
const HERO_FRAMES := preload("res://ally/player/resources/black_worrier_frame.tres") as SpriteFrames

const TREE_TEXTURES: Array[Texture2D] = [
	preload("res://Asets/Unit_pack/Terrain/Resources/Wood/Trees/Tree1.png"),
	preload("res://Asets/Unit_pack/Terrain/Resources/Wood/Trees/Tree2.png"),
	preload("res://Asets/Unit_pack/Terrain/Resources/Wood/Trees/Tree4.png"),
]

const FRAME_W := 192
const FRAME_H := 256
const FRAME_COUNT := 8

enum _State { READY, CHOPPING, DYING }

var _state: _State = _State.READY

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	add_to_group("wood_job_tree")
	add_to_group("y_sortable")
	if _sprite == null:
		push_error("WoodJobTree: нет AnimatedSprite2D — дерево не отрисуется.")
		return
	var tex: Texture2D = TREE_TEXTURES[randi() % TREE_TEXTURES.size()]
	if tex == null or tex.get_width() <= 0:
		push_error("WoodJobTree: текстура дерева не загрузилась.")
		return
	var sf := _build_sprite_frames(tex)
	if sf.get_frame_count(&"idle") < 1:
		push_error("WoodJobTree: не удалось собрать кадры idle (проверь размер атласа Tree*.png).")
		return
	_sprite.sprite_frames = sf
	_sprite.play(&"idle")


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


## Рубка завершена (5 с): спавн бревна, проигрыш dead, затем освобождение слота зоны.
func finish_chop() -> Node2D:
	if _state != _State.CHOPPING:
		return null
	_state = _State.DYING
	var log_pickup: Node2D = WOOD_LOG_SCENE.instantiate()
	var p := get_parent()
	if p:
		p.add_child(log_pickup)
		log_pickup.global_position = global_position
	else:
		log_pickup.queue_free()
		return null
	if _sprite and _sprite.sprite_frames and _sprite.sprite_frames.has_animation(&"dead"):
		_sprite.play(&"dead")
		if not _sprite.animation_finished.is_connected(_on_dead_finished):
			_sprite.animation_finished.connect(_on_dead_finished, CONNECT_ONE_SHOT)
	else:
		queue_free()
	return log_pickup


func _on_dead_finished() -> void:
	queue_free()


func _build_sprite_frames(tex: Texture2D) -> SpriteFrames:
	var sf := SpriteFrames.new()
	sf.add_animation(&"idle")
	sf.set_animation_loop(&"idle", true)
	sf.set_animation_speed(&"idle", 5.0)
	var tw := tex.get_width()
	var th := tex.get_height()
	var frame_count := FRAME_COUNT
	var fw := float(tw) / float(frame_count)
	if fw < 2.0:
		frame_count = 1
		fw = float(tw)
	var fh := minf(th, float(FRAME_H))
	for i in frame_count:
		var at := AtlasTexture.new()
		at.atlas = tex
		at.region = Rect2(i * fw, 0, fw, fh)
		sf.add_frame(&"idle", at, 1.0 / 8.0)
	_copy_dead_animation(sf)
	return sf


func _copy_dead_animation(sf: SpriteFrames) -> void:
	if HERO_FRAMES == null or not HERO_FRAMES.has_animation(&"dead"):
		return
	sf.add_animation(&"dead")
	sf.set_animation_loop(&"dead", false)
	var speed := HERO_FRAMES.get_animation_speed(&"dead")
	sf.set_animation_speed(&"dead", speed)
	var n := HERO_FRAMES.get_frame_count(&"dead")
	for i in n:
		var t := HERO_FRAMES.get_frame_texture(&"dead", i)
		var dur := HERO_FRAMES.get_frame_duration(&"dead", i)
		sf.add_frame(&"dead", t, dur)


func get_y_sort_bottom_y() -> float:
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
