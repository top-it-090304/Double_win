extends Node

## SFX и плейлист: см. audio/LICENSE_SOURCES.txt
## Шины: Music / SFX / UI / Dialogue (создаются в _ensure_audio_buses), громкость — SaveManager + компрессор на SFX.

const BUS_MUSIC := &"Music"
const BUS_SFX := &"SFX"
const BUS_UI := &"UI"
const BUS_DIALOGUE := &"Dialogue"

## Щит (raise + block) громче остального боя — хорошо слышно.
const VOL_MUSIC := -20.0
const VOL_COMBAT := -22.0
const VOL_ATTACK_SWING := -20.0
const VOL_ENEMY_ATTACK_SWING := -20.0
const VOL_SHIELD := -8.0
const VOL_SHIELD_RAISE := -6.0
const VOL_UI := -36.0
const VOL_UI_MENU := -40.0
const VOL_DIALOGUE := -36.0
const VOL_DIALOGUE_PAGE := -38.0
const VOL_DIALOGUE_MUMBLE := -24.0
const VOL_FOOTSTEP := -34.0
const VOL_REWARD := -24.0
const VOL_LEVEL_UP := -18.0
const VOL_BOSS := -14.0
const VOL_HEAL := -26.0
const VOL_TELEPORT := -38.0

const DUCK_DB_DIALOGUE := -5.0
const DUCK_DB_MENU := -4.0

const PLAYLIST = [
	preload("res://audio/music/fantasy_grasslands_cc0.mp3"),
	preload("res://audio/music/bg_02_field_of_dreams_cc0.mp3"),
	preload("res://audio/music/bg_03_grassland_cc0.mp3"),
	preload("res://audio/music/bg_04_town_theme_cc0.mp3"),
]

## CC0: Male Adventurer RPG — короткие возгласы при взмахе (под короткую анимацию).
const ATTACK_SHOUTS = [
	preload("res://audio/sfx/knight_attack_shout_0.wav"),
	preload("res://audio/sfx/knight_attack_shout_1.wav"),
	preload("res://audio/sfx/knight_attack_shout_2.wav"),
]
## Взмах врага — только Kenney (металл/механика), без голоса.
const ENEMY_ATTACK_SWINGS = [
	preload("res://audio/sfx/shield_variants/raise_03_metalClick.ogg"),
	preload("res://audio/sfx/shield_variants/raise_01_beltHandle.ogg"),
	preload("res://audio/sfx/shield_variants/block_01_metal_light.ogg"),
]
const STREAM_HIT_ARMOR := preload("res://audio/sfx/hit_armor.ogg")
const STREAM_HIT_BODY := preload("res://audio/sfx/hit_body.ogg")
const STREAM_PLAYER_HURT := preload("res://audio/sfx/player_hurt.ogg")
const STREAM_ENEMY_HURT := preload("res://audio/sfx/enemy_hurt.ogg")
const STREAM_SHIELD_RAISE := preload("res://audio/sfx/shield_variants/raise_00_metalLatch.ogg")
const STREAM_SHIELD_BLOCK := preload("res://audio/sfx/shield_variants/block_00_metalClick.ogg")
const STREAM_DEATH := preload("res://audio/sfx/death.ogg")

const STREAM_DIALOGUE_PAGE_TURN := preload("res://audio/sfx/dialogue/page_turn.ogg")

const MUMBLE_MALE = [
	preload("res://audio/sfx/dialogue/mumble_male_1.ogg"),
	preload("res://audio/sfx/dialogue/mumble_male_2.ogg"),
	preload("res://audio/sfx/dialogue/mumble_male_3.ogg"),
	preload("res://audio/sfx/dialogue/mumble_male_4.ogg"),
]
const MUMBLE_FEMALE = [
	preload("res://audio/sfx/dialogue/mumble_female_1.ogg"),
	preload("res://audio/sfx/dialogue/mumble_female_2.ogg"),
	preload("res://audio/sfx/dialogue/mumble_female_3.ogg"),
	preload("res://audio/sfx/dialogue/mumble_female_4.ogg"),
]
const MUMBLE_WHISPER = [
	preload("res://audio/sfx/dialogue/mumble_whisper_1.ogg"),
	preload("res://audio/sfx/dialogue/mumble_whisper_2.ogg"),
	preload("res://audio/sfx/dialogue/mumble_whisper_3.ogg"),
	preload("res://audio/sfx/dialogue/mumble_whisper_4.ogg"),
]

const STREAM_UI_DIALOGUE := preload("res://audio/sfx/ui/dialogue_advance.ogg")
const STREAM_UI_MENU_OPEN := preload("res://audio/sfx/ui/menu_open.ogg")
const STREAM_UI_MENU_CLOSE := preload("res://audio/sfx/ui/menu_close.ogg")
const STREAM_UI_BUTTON := preload("res://audio/sfx/ui/button_soft.ogg")

const FOOTSTEPS = [
	preload("res://audio/sfx/footstep_00.ogg"),
	preload("res://audio/sfx/footstep_02.ogg"),
	preload("res://audio/sfx/footstep_05.ogg"),
]

const _SFX_POOL_SIZE := 8

var _music: AudioStreamPlayer
var _sfx_pool: Array[AudioStreamPlayer] = []

var _playlist_order: Array[int] = []
var _playlist_cursor: int = 0
var _prev_location: Events.LOCATION = Events.LOCATION.MENU
var _music_duck_db: float = 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_audio_buses()
	_apply_compressor_to_sfx_bus()
	_music = AudioStreamPlayer.new()
	_music.name = "MusicPlayer"
	_music.process_mode = Node.PROCESS_MODE_ALWAYS
	_music.bus = BUS_MUSIC
	add_child(_music)
	_music.finished.connect(_on_music_track_finished)
	for i in _SFX_POOL_SIZE:
		var p := AudioStreamPlayer.new()
		p.name = "SfxPlayer_%d" % i
		p.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(p)
		_sfx_pool.append(p)
	Events.location_changed.connect(_on_location_changed)
	await get_tree().process_frame
	if DialogueManager:
		DialogueManager.dialogue_started.connect(_on_dialogue_duck_signal)
		DialogueManager.dialogue_ended.connect(_on_dialogue_duck_signal)
	apply_user_volume_settings()
	_refresh_music_duck()
	_sync_music_with_current_scene()


func _ensure_audio_buses() -> void:
	_ensure_bus("Music")
	_ensure_bus("SFX")
	_ensure_bus("UI")
	_ensure_bus("Dialogue")


func _ensure_bus(bus_name: String) -> void:
	if AudioServer.get_bus_index(bus_name) != -1:
		return
	AudioServer.add_bus(-1)
	var idx := AudioServer.get_bus_count() - 1
	AudioServer.set_bus_name(idx, bus_name)
	AudioServer.set_bus_send(idx, "Master")


func _apply_compressor_to_sfx_bus() -> void:
	var idx := AudioServer.get_bus_index("SFX")
	if idx < 0:
		return
	for i in AudioServer.get_bus_effect_count(idx):
		if AudioServer.get_bus_effect(idx, i) is AudioEffectCompressor:
			return
	var comp := AudioEffectCompressor.new()
	comp.threshold = -14.0
	comp.ratio = 3.0
	comp.gain = 1.0
	comp.attack_us = 40.0
	comp.release_ms = 180.0
	AudioServer.add_bus_effect(idx, comp)


## Вызывать после load_game и при смене ползунков в настройках.
func apply_user_volume_settings() -> void:
	_set_bus_linear(BUS_MUSIC, SaveManager.volume_music)
	_set_bus_linear(BUS_SFX, SaveManager.volume_sfx)
	_set_bus_linear(BUS_UI, SaveManager.volume_ui)
	_set_bus_linear(BUS_DIALOGUE, SaveManager.volume_dialogue)


func _set_bus_linear(bus_name: StringName, linear: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx < 0:
		return
	var lin := clampf(linear, 0.0, 1.0)
	var db := -80.0 if lin < 0.0001 else linear_to_db(lin)
	AudioServer.set_bus_volume_db(idx, db)


func _sync_music_with_current_scene() -> void:
	_play_background_music()


func _on_location_changed(loc: Events.LOCATION) -> void:
	if loc == Events.LOCATION.MENU and _prev_location != Events.LOCATION.MENU:
		play_menu_open()
	elif loc != Events.LOCATION.MENU and _prev_location == Events.LOCATION.MENU:
		play_menu_close()
	_prev_location = loc
	_play_background_music()
	_refresh_music_duck()


func _on_dialogue_duck_signal(_a = null) -> void:
	_refresh_music_duck()


func _refresh_music_duck() -> void:
	var duck := 0.0
	if DialogueManager and DialogueManager.is_active():
		duck += DUCK_DB_DIALOGUE
	if Events.current_location == Events.LOCATION.MENU:
		duck += DUCK_DB_MENU
	_music_duck_db = duck
	if _music:
		_music.volume_db = VOL_MUSIC + _music_duck_db


func _play_background_music() -> void:
	if _music.playing:
		return
	if _playlist_order.is_empty():
		_shuffle_playlist_order()
	_play_track_at_cursor()


func _shuffle_playlist_order() -> void:
	_playlist_order.clear()
	for i in range(PLAYLIST.size()):
		_playlist_order.append(i)
	_playlist_order.shuffle()
	_playlist_cursor = 0


func _play_track_at_cursor() -> void:
	if _playlist_order.is_empty():
		_shuffle_playlist_order()
	var track_idx: int = _playlist_order[_playlist_cursor]
	var base: AudioStream = PLAYLIST[track_idx]
	var s: AudioStream = base.duplicate()
	if s is AudioStreamMP3:
		(s as AudioStreamMP3).loop = false
	elif s is AudioStreamOggVorbis:
		(s as AudioStreamOggVorbis).loop = false
	_music.stop()
	_music.stream = s
	_music.volume_db = VOL_MUSIC + _music_duck_db
	_music.play()


func _on_music_track_finished() -> void:
	_playlist_cursor += 1
	if _playlist_cursor >= _playlist_order.size():
		_playlist_cursor = 0
		_playlist_order.shuffle()
	_play_track_at_cursor()


func _pick_sfx_player() -> AudioStreamPlayer:
	for p in _sfx_pool:
		if not p.playing:
			return p
	return _sfx_pool[0]


func _play_sfx(stream: AudioStream, pitch_scale: float, volume_db: float, bus_name: StringName) -> void:
	_play_sfx_from(stream, pitch_scale, volume_db, 0.0, bus_name)


func _play_sfx_from(stream: AudioStream, pitch_scale: float, volume_db: float, from_sec: float, bus_name: StringName) -> void:
	var s: AudioStream = stream.duplicate()
	var p := _pick_sfx_player()
	p.stream = s
	p.pitch_scale = pitch_scale
	p.volume_db = volume_db
	p.bus = bus_name
	p.play(from_sec)


func play_attack_swing() -> void:
	var stream: AudioStream = ATTACK_SHOUTS[randi() % ATTACK_SHOUTS.size()]
	_play_sfx(stream, randf_range(0.96, 1.04), VOL_ATTACK_SWING, BUS_SFX)


func play_enemy_attack_swing() -> void:
	var stream: AudioStream = ENEMY_ATTACK_SWINGS[randi() % ENEMY_ATTACK_SWINGS.size()]
	_play_sfx(stream, randf_range(0.92, 1.08), VOL_ENEMY_ATTACK_SWING, BUS_SFX)


func play_enemy_hit() -> void:
	var r := randf()
	var stream: AudioStream
	if r < 0.38:
		stream = STREAM_HIT_ARMOR
	elif r < 0.72:
		stream = STREAM_HIT_BODY
	else:
		stream = STREAM_ENEMY_HURT
	_play_sfx(stream, randf_range(0.95, 1.05), VOL_COMBAT, BUS_SFX)


func play_player_hurt() -> void:
	_play_sfx(STREAM_PLAYER_HURT, randf_range(0.95, 1.05), VOL_COMBAT, BUS_SFX)


func play_shield_block() -> void:
	_play_sfx(STREAM_SHIELD_BLOCK, randf_range(0.97, 1.03), VOL_SHIELD, BUS_SFX)


func play_shield_raise() -> void:
	var stream: AudioStream = STREAM_SHIELD_RAISE
	var len_sec: float = stream.get_length()
	var skip: float = 0.0
	if len_sec > 0.001:
		skip = len_sec * 0.32
		skip = minf(skip, len_sec * 0.42)
		skip = minf(skip, maxf(0.0, len_sec - 0.09))
	_play_sfx_from(stream, randf_range(0.98, 1.04), VOL_SHIELD_RAISE, skip, BUS_SFX)


func play_death() -> void:
	_play_sfx(STREAM_DEATH, randf_range(0.97, 1.03), VOL_COMBAT, BUS_SFX)


func play_dialogue_advance() -> void:
	_play_sfx(STREAM_UI_DIALOGUE, randf_range(0.98, 1.02), VOL_DIALOGUE, BUS_DIALOGUE)


func play_dialogue_page_turn() -> void:
	_play_sfx(STREAM_DIALOGUE_PAGE_TURN, randf_range(0.96, 1.04), VOL_DIALOGUE_PAGE, BUS_DIALOGUE)


## Короткий «бубнёж» под спикера (инди-стиль), CC0 vocal samples.
func play_dialogue_mumble(speaker_id: String) -> void:
	var sid := speaker_id.strip_edges().to_lower()
	var pool = MUMBLE_MALE
	match sid:
		"healer":
			pool = MUMBLE_FEMALE
		"narrator":
			pool = MUMBLE_WHISPER
		"hero":
			pool = MUMBLE_MALE
	var stream: AudioStream = pool[randi() % pool.size()]
	_play_sfx(stream, randf_range(0.94, 1.06), VOL_DIALOGUE_MUMBLE, BUS_DIALOGUE)


func play_menu_open() -> void:
	_play_sfx(STREAM_UI_MENU_OPEN, randf_range(0.98, 1.02), VOL_UI_MENU, BUS_UI)


func play_menu_close() -> void:
	_play_sfx(STREAM_UI_MENU_CLOSE, randf_range(0.98, 1.02), VOL_UI_MENU, BUS_UI)


func play_ui_button() -> void:
	_play_sfx(STREAM_UI_BUTTON, randf_range(0.96, 1.04), VOL_UI, BUS_UI)


func play_footstep() -> void:
	var stream: AudioStream = FOOTSTEPS[randi() % FOOTSTEPS.size()]
	_play_sfx(stream, randf_range(0.92, 1.08), VOL_FOOTSTEP, BUS_SFX)


## Награда / золото (Kenney UI, тот же сэмпл что кнопка — короткий «блик»).
func play_pickup_gold() -> void:
	_play_sfx(STREAM_UI_BUTTON, randf_range(1.12, 1.22), VOL_REWARD, BUS_SFX)


## Уровень: короткий позитивный тон (menu_open + чуть выше тон).
func play_level_up() -> void:
	_play_sfx(STREAM_UI_MENU_OPEN, randf_range(1.08, 1.18), VOL_LEVEL_UP, BUS_SFX)


## Победа над боссом: тяжёлый удар + низкий тон.
func play_boss_defeat() -> void:
	_play_sfx(STREAM_HIT_ARMOR, randf_range(0.88, 0.96), VOL_BOSS, BUS_SFX)


## Лечение: мягкий щелчок (page_turn).
func play_heal() -> void:
	_play_sfx(STREAM_DIALOGUE_PAGE_TURN, randf_range(1.05, 1.15), VOL_HEAL, BUS_SFX)


## Телепорт / смена локации в UI.
func play_teleport() -> void:
	_play_sfx(STREAM_UI_MENU_CLOSE, randf_range(0.88, 0.96), VOL_TELEPORT, BUS_UI)
