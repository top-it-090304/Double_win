extends Node2D
## Дерево на базе: удар рабочего топором (interact_axe) — W_Spawn → W_Idle_(NoShadow), +дерево.

const TEX_TREE := preload("res://Asets/Environment/Resources/Trees/Tree.png")
const TEX_W_SPAWN := preload("res://Asets/Environment/Resources/Resources/W_Spawn.png")
const TEX_W_IDLE_NS := preload("res://Asets/Environment/Resources/Resources/W_Idle_(NoShadow).png")
const W_SPAWN_FRAMES := 6

@onready var _tree: Sprite2D = $Sprite2D
@onready var _fx: AnimatedSprite2D = $FxSprite

var _state: String = "alive"
var _hit_cd: float = 0.0


func _ready() -> void:
	add_to_group("wood_tree_resource")
	if _fx:
		_fx.visible = false


func _physics_process(_delta: float) -> void:
	if Events.current_location != Events.LOCATION.BASE:
		return
	if _state != "alive":
		return
	_hit_cd = maxf(0.0, _hit_cd - _delta)
	if _hit_cd > 0.0:
		return
	if _pawn_axe_hit():
		_begin_chop()


func _pawn_axe_hit() -> bool:
	for pawn in get_tree().get_nodes_in_group("ally_pawn"):
		if not pawn is Node2D:
			continue
		var n2: Node2D = pawn as Node2D
		if global_position.distance_to(n2.global_position) > 58.0:
			continue
		var spr := n2.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
		if spr == null:
			continue
		if spr.animation == &"interact_axe":
			return true
	return false


func _begin_chop() -> void:
	_state = "chop"
	_hit_cd = 999.0
	if _tree:
		_tree.visible = false
	if _fx == null:
		queue_free()
		return
	var sf := SpriteFrames.new()
	sf.add_animation(&"spawn")
	sf.set_animation_loop(&"spawn", false)
	var tw: int = TEX_W_SPAWN.get_width()
	var th: int = TEX_W_SPAWN.get_height()
	var fw: int = tw / W_SPAWN_FRAMES
	var dur := 1.0 / 12.0
	for i in range(W_SPAWN_FRAMES):
		var at := AtlasTexture.new()
		at.atlas = TEX_W_SPAWN
		at.region = Rect2(i * fw, 0, fw, th)
		sf.add_frame(&"spawn", at, dur)
	_fx.sprite_frames = sf
	_fx.visible = true
	_fx.play(&"spawn")
	if not _fx.animation_finished.is_connected(_on_fx_anim_finished):
		_fx.animation_finished.connect(_on_fx_anim_finished, CONNECT_ONE_SHOT)


func _on_fx_anim_finished() -> void:
	if _fx == null or not is_instance_valid(_fx):
		return
	if _fx.animation != &"spawn":
		return
	_fx.sprite_frames = ResourceStripFrames.build_single_frame(TEX_W_IDLE_NS)
	_fx.play(&"default")
	GameManager.add_wood(2)
	var t := get_tree().create_timer(0.85)
	t.timeout.connect(_finish_tree_free, CONNECT_ONE_SHOT)


func _finish_tree_free() -> void:
	queue_free()
