class_name AudioManager
extends Node

# === КОМПОНЕНТЫ ===
@onready var music_player: AudioStreamPlayer = $MusicPlayer
@onready var sfx_player: AudioStreamPlayer2D = $SFXPlayer
@onready var ambient_player: AudioStreamPlayer2D = $AmbientPlayer
@onready var ui_player: AudioStreamPlayer = $UIPlayer

# === НАСТРОЙКИ ГРОМКОСТИ ===
@export var master_volume: float = 1.0:
	set(value):
		master_volume = clamp(value, 0.0, 1.0)
		update_volumes()

@export var music_volume: float = 0.8:
	set(value):
		music_volume = clamp(value, 0.0, 1.0)
		update_volumes()

@export var sfx_volume: float = 0.9:
	set(value):
		sfx_volume = clamp(value, 0.0, 1.0)
		update_volumes()

@export var ambient_volume: float = 0.6:
	set(value):
		ambient_volume = clamp(value, 0.0, 1.0)
		update_volumes()

@export var ui_volume: float = 1.0:
	set(value):
		ui_volume = clamp(value, 0.0, 1.0)
		update_volumes()

# === ИНИЦИАЛИЗАЦИЯ ===
func _ready() -> void:
	update_volumes()
	
	# Подписка на сигналы
	SignalBus.player_took_damage.connect(_on_player_took_damage)
	SignalBus.enemy_died.connect(_on_enemy_died)
	SignalBus.item_picked_up.connect(_on_item_picked_up)

func update_volumes() -> void:
	music_player.volume_db = linear_to_db(music_volume * master_volume)
	sfx_player.volume_db = linear_to_db(sfx_volume * master_volume)
	ambient_player.volume_db = linear_to_db(ambient_volume * master_volume)
	ui_player.volume_db = linear_to_db(ui_volume * master_volume)

# === МУЗЫКА ===
func play_music(music_stream: AudioStream, fade_duration: float = 1.0) -> void:
	if music_player.stream == music_stream and music_player.playing:
		return
	
	if fade_duration > 0 and music_player.playing:
		# Плавное затухание
		var tween = create_tween()
		tween.tween_property(music_player, "volume_db", -80.0, fade_duration)
		await tween.finished
	
	music_player.stream = music_stream
	music_player.play()
	
	if fade_duration > 0:
		var tween = create_tween()
		tween.tween_property(music_player, "volume_db", linear_to_db(music_volume * master_volume), fade_duration)

func stop_music(fade_duration: float = 1.0) -> void:
	if fade_duration > 0:
		var tween = create_tween()
		tween.tween_property(music_player, "volume_db", -80.0, fade_duration)
		await tween.finished
	
	music_player.stop()
	music_player.volume_db = linear_to_db(music_volume * master_volume)

# === ЗВУКОВЫЕ ЭФФЕКТЫ ===
func play_sfx(sfx_stream: AudioStream, pitch_variation: float = 0.0) -> void:
	if not sfx_stream:
		return
	
	sfx_player.stream = sfx_stream
	
	if pitch_variation > 0:
		var variation = randf_range(-pitch_variation, pitch_variation)
		sfx_player.pitch_scale = 1.0 + variation
	else:
		sfx_player.pitch_scale = 1.0
	
	sfx_player.play()

func play_sfx_at_position(sfx_stream: AudioStream, position: Vector2) -> void:
	if not sfx_stream:
		return
	
	var new_player = AudioStreamPlayer2D.new()
	new_player.stream = sfx_stream
	new_player.volume_db = sfx_player.volume_db
	new_player.global_position = position
	add_child(new_player)
	
	new_player.play()
	new_player.finished.connect(func(): new_player.queue_free())

# === АМБИЕНТНЫЕ ЗВУКИ ===
func play_ambient(ambient_stream: AudioStream, loop: bool = true) -> void:
	ambient_player.stream = ambient_stream
	ambient_player.play()

func stop_ambient() -> void:
	ambient_player.stop()

# === UI ЗВУКИ ===
func play_ui_sound(ui_stream: AudioStream) -> void:
	ui_player.stream = ui_stream
	ui_player.play()

# === ОБРАБОТЧИКИ СОБЫТИЙ ===
func _on_player_took_damage(amount: int) -> void:
	if amount > 0:
		# Проигрываем звук получения урона
		pass

func _on_enemy_died(enemy: Enemy, experience: int, gold: int) -> void:
	# Проигрываем звук смерти врага
	pass

func _on_item_picked_up(item: Node, player: Player) -> void:
	# Проигрываем звук подбора предмета
	pass

# === УТИЛИТЫ ===
func set_music_volume_db(db: float) -> void:
	music_volume = db_to_linear(db)

func set_sfx_volume_db(db: float) -> void:
	sfx_volume = db_to_linear(db)

func pause_all() -> void:
	music_player.stream_paused = true
	sfx_player.stream_paused = true
	ambient_player.stream_paused = true
	ui_player.stream_paused = true

func resume_all() -> void:
	music_player.stream_paused = false
	sfx_player.stream_paused = false
	ambient_player.stream_paused = false
	ui_player.stream_paused = false
