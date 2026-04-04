extends Node2D
## Овца на базе: удар рабочего (interact*, не нож) — M_Idle_(NoShadow), +1 мяса.

const TEX_SHEEP := preload("res://Asets/Environment/Resources/Sheep/HappySheep_Idle.png")
const TEX_MEAT := preload("res://Asets/Environment/Resources/Resources/M_Idle_(NoShadow).png")
const SHEEP_FRAMES := 8

@onready var _anim: AnimatedSprite2D = $AnimatedSprite2D

var _state: String = "alive"
var _hit_cd: float = 0.0


func _ready() -> void:
	add_to_group("sheep_resource")
	if _anim:
		_anim.sprite_frames = ResourceStripFrames.build_horizontal_strip(TEX_SHEEP, SHEEP_FRAMES, 10.0)
		_anim.play(&"default")


func _physics_process(_delta: float) -> void:
	if Events.current_location != Events.LOCATION.BASE:
		return
	if _state != "alive":
		return
	_hit_cd = maxf(0.0, _hit_cd - _delta)
	if _hit_cd > 0.0:
		return
	if _pawn_hits_sheep():
		_shear()


func _pawn_hits_sheep() -> bool:
	var tree := get_tree()
	if tree == null or tree.get_node_count_in_group(&"ally_pawn") < 1:
		return false
	var my_pos := global_position
	var max_d2 := 56.0 * 56.0
	for pawn in tree.get_nodes_in_group("ally_pawn"):
		if not pawn is Node2D:
			continue
		var n2: Node2D = pawn as Node2D
		if my_pos.distance_squared_to(n2.global_position) > max_d2:
			continue
		var spr := n2.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
		if spr == null:
			continue
		var an: StringName = spr.animation
		if an == &"interact_knife":
			continue
		if an.begins_with("interact"):
			return true
	return false


func _shear() -> void:
	_state = "meat"
	_hit_cd = 999.0
	if _anim:
		_anim.sprite_frames = ResourceStripFrames.build_single_frame(TEX_MEAT)
		_anim.play(&"default")
	GameManager.add_meat(1)
