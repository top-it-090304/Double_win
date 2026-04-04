extends Node2D
## Лёгкий дождь: редкие капли чуть крупнее, медленное падение, низкая частота симуляции.
## CPUParticles2D — стабильно на gl_compatibility. Позиция = центр экрана камеры.
## Включается при `RainSystem.should_show_rain_overlay()` (период дождя без режима «На тапке»).

@onready var _particles: CPUParticles2D = $RainParticles
## Кэш камеры с узла «player», если viewport не даёт Camera2D — без повторного обхода группы каждый кадр.
var _cached_player_camera: Camera2D = null


func _ready() -> void:
	z_index = 400
	_particles.position = Vector2(0.0, -280.0)
	_particles.emitting = false
	_particles.amount = 98
	_particles.lifetime = 0.78
	_particles.preprocess = 0.28
	_particles.randomness = 0.18
	_particles.explosiveness = 0.0
	_particles.fixed_fps = 20
	_particles.local_coords = true
	_particles.color = Color(0.78, 0.88, 1.0, 0.56)

	# Чуть шире/длиннее полоска + больший scale — заметнее на фоне тайлов.
	var img := Image.create(3, 18, false, Image.FORMAT_RGBA8)
	img.fill(Color(1.0, 1.0, 1.0, 1.0))
	_particles.texture = ImageTexture.create_from_image(img)

	_particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	_particles.emission_rect_extents = Vector2(920.0, 360.0)
	_particles.direction = Vector2(0.1, 1.0).normalized()
	_particles.spread = 6.0
	_particles.initial_velocity_min = 210.0
	_particles.initial_velocity_max = 320.0
	_particles.gravity = Vector2(0.0, 620.0)
	_particles.scale_amount_min = 1.08
	_particles.scale_amount_max = 1.48
	_particles.particle_flag_align_y = true
	_particles.restart()
	refresh_rain_state()


func refresh_rain_state() -> void:
	var on := RainSystem.should_show_rain_overlay()
	visible = on
	set_process(on)
	if not on:
		_particles.emitting = false


func _resolve_camera_2d() -> Camera2D:
	var cam := get_viewport().get_camera_2d()
	if cam != null and cam.enabled:
		_cached_player_camera = null
		return cam
	if _cached_player_camera != null and is_instance_valid(_cached_player_camera) and _cached_player_camera.enabled:
		return _cached_player_camera
	for n in get_tree().get_nodes_in_group("player"):
		if not (n is Node) or not n.is_inside_tree():
			continue
		var c := (n as Node).get_node_or_null("Camera2D") as Camera2D
		if c != null and c.enabled:
			_cached_player_camera = c
			return c
	_cached_player_camera = null
	return null


func _process(_delta: float) -> void:
	if not visible:
		return
	var cam := _resolve_camera_2d()
	if cam:
		global_position = cam.get_screen_center_position()
		if not _particles.emitting:
			_particles.emitting = true
			_particles.restart()
	elif _particles.emitting:
		_particles.emitting = false
