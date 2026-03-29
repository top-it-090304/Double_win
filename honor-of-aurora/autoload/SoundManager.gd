extends Node

## SFX и плейлисты: см. audio/LICENSE_SOURCES.txt
## Фон: папки res://audio/music/playlists/island_01 .. island_05 (случайный порядок внутри папки).
## База и меню — всегда island_01. На LVL*N до победы над боссом острова — island_0N; после флага story_island_N_cleared на этом острове — снова island_01.
## После story_island_5_cleared — везде island_05 (напряжённо), в т.ч. на базе.
## Шины: Music / SFX / UI / Dialogue (создаются в _ensure_audio_buses), громкость — SaveManager + компрессор на SFX.

const PLAYLIST_ROOT := "res://audio/music/playlists"
const _PLAYLIST_TIER_BASE := 1
const _PLAYLIST_TIER_FINALE := 5

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
## Голосовые блипы в диалоге: громче «сырой» уровень; итог крутит шина Dialogue × SaveManager.volume_dialogue.
const VOL_DIALOGUE := -14.0
const VOL_DIALOGUE_PAGE := -18.0
const VOL_FOOTSTEP := -34.0
const VOL_REWARD := -24.0
const VOL_LEVEL_UP := -18.0
const VOL_HEAL := -26.0
const VOL_TELEPORT := -38.0

const DUCK_DB_DIALOGUE := -5.0
const DUCK_DB_MENU := -4.0

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

const STREAM_UI_DIALOGUE := preload("res://audio/sfx/ui/dialogue_advance.ogg")

## Короткие «мумбл»-блипы (Kenney / CC0 в LICENSE_SOURCES). Один закреплённый сэмпл на speaker_id / тип юнита — без rand().
const DIALOGUE_MUMBLE_MALE: Array[AudioStream] = [
	preload("res://audio/sfx/dialogue/mumble_male_1.ogg"),
	preload("res://audio/sfx/dialogue/mumble_male_2.ogg"),
	preload("res://audio/sfx/dialogue/mumble_male_3.ogg"),
	preload("res://audio/sfx/dialogue/mumble_male_4.ogg"),
]
const DIALOGUE_MUMBLE_FEMALE: Array[AudioStream] = [
	preload("res://audio/sfx/dialogue/mumble_female_1.ogg"),
	preload("res://audio/sfx/dialogue/mumble_female_2.ogg"),
	preload("res://audio/sfx/dialogue/mumble_female_3.ogg"),
	preload("res://audio/sfx/dialogue/mumble_female_4.ogg"),
]
const DIALOGUE_MUMBLE_WHISPER: Array[AudioStream] = [
	preload("res://audio/sfx/dialogue/mumble_whisper_1.ogg"),
	preload("res://audio/sfx/dialogue/mumble_whisper_2.ogg"),
	preload("res://audio/sfx/dialogue/mumble_whisper_3.ogg"),
	preload("res://audio/sfx/dialogue/mumble_whisper_4.ogg"),
]

## speaker_id из DialogueLine / лора → [индекс в массиве выше, "male"|"female"|"whisper", pitch_scale].
const _SPEAKER_BLIP := {
	"hero": [0, &"male", 1.0],
	"healer": [1, &"male", 0.96],
	"young_worker": [2, &"male", 1.06],
	"veteran": [3, &"male", 0.91],
	"caravan": [0, &"female", 0.98],
	"narrator": [0, &"whisper", 1.0],
	"letter": [1, &"whisper", 1.02],
	## Внутренние id для меню приказов (не speaker_id в ресурсах).
	"_squad_archer": [1, &"female", 1.0],
	"_squad_lancer": [2, &"male", 0.97],
	"_squad_pawn": [2, &"male", 0.89],
	"_squad_default": [0, &"male", 0.94],
}
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
var _playlist_tier_when_shuffled: int = -1
## Кэш загруженных AudioStream по тиру (после правок папок в редакторе перезапустите игру или вызовите invalidate).
var _playlist_stream_cache: Dictionary = {}
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
	refresh_adventure_bgm_state()


func _on_location_changed(loc: Events.LOCATION) -> void:
	if loc == Events.LOCATION.MENU and _prev_location != Events.LOCATION.MENU:
		play_menu_open()
	elif loc != Events.LOCATION.MENU and _prev_location == Events.LOCATION.MENU:
		play_menu_close()
	_prev_location = loc
	refresh_adventure_bgm_state()
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


## После убийства босса (флаг острова уже выставлен): переключить плейлист при необходимости.
func notify_adventure_music_progress() -> void:
	var tier := _desired_playlist_tier()
	if tier != _playlist_tier_when_shuffled:
		_playlist_stream_cache.clear()
		_playlist_order.clear()
		_playlist_cursor = 0
		_playlist_tier_when_shuffled = -1
		if _music.playing:
			_music.stop()
	refresh_adventure_bgm_state()


## Вызывать из PostFinaleWorld при событиях финала / смене сцены (перезапуск трека при смене тира и т.п.).
func refresh_adventure_bgm_state() -> void:
	_play_background_music()


func _location_to_story_island_index(loc: Events.LOCATION) -> int:
	match loc:
		Events.LOCATION.LVL1:
			return 1
		Events.LOCATION.LVL2:
			return 2
		Events.LOCATION.LVL3:
			return 3
		Events.LOCATION.LVL4:
			return 4
		Events.LOCATION.LVL5:
			return 5
		_:
			return 0


## Номер папки island_XX (1..5). 1 — «базовый» спокойный набор; 5 — напряжённый (остров 5 до босса и весь мир после финала).
func _desired_playlist_tier() -> int:
	if StoryState.has_flag("story_island_5_cleared"):
		return _PLAYLIST_TIER_FINALE
	var loc := Events.current_location
	if loc == Events.LOCATION.BASE or loc == Events.LOCATION.MENU:
		return _PLAYLIST_TIER_BASE
	var island_idx := _location_to_story_island_index(loc)
	if island_idx <= 0:
		return _PLAYLIST_TIER_BASE
	if StoryState.has_flag("story_island_%d_cleared" % island_idx):
		return _PLAYLIST_TIER_BASE
	return island_idx


func _load_audio_streams_from_folder(folder_path: String) -> Array[AudioStream]:
	var out: Array[AudioStream] = []
	var dir := DirAccess.open(folder_path)
	if dir == null:
		return out
	var err := dir.list_dir_begin()
	if err != OK:
		return out
	var fn := dir.get_next()
	while fn != "":
		if dir.current_is_dir() or fn.begins_with("."):
			fn = dir.get_next()
			continue
		var low := fn.to_lower()
		if not (low.ends_with(".ogg") or low.ends_with(".mp3") or low.ends_with(".wav")):
			fn = dir.get_next()
			continue
		var full_path := folder_path.path_join(fn)
		if not ResourceLoader.exists(full_path):
			fn = dir.get_next()
			continue
		var res := load(full_path)
		if res is AudioStream:
			out.append(res as AudioStream)
		fn = dir.get_next()
	dir.list_dir_end()
	return out


func _get_streams_for_tier(tier: int) -> Array[AudioStream]:
	if _playlist_stream_cache.has(tier):
		return _playlist_stream_cache[tier] as Array[AudioStream]
	var path := "%s/island_%02d" % [PLAYLIST_ROOT, tier]
	var loaded := _load_audio_streams_from_folder(path)
	if loaded.is_empty() and tier != 1:
		loaded = _get_streams_for_tier(1)
	_playlist_stream_cache[tier] = loaded
	return loaded


func _play_background_music() -> void:
	var tier := _desired_playlist_tier()
	if _music.playing and _playlist_tier_when_shuffled == tier:
		return
	if _playlist_tier_when_shuffled != tier:
		_playlist_order.clear()
		_playlist_cursor = 0
		_playlist_tier_when_shuffled = -1
	if _music.playing:
		_music.stop()
	if _playlist_order.is_empty() or _playlist_tier_when_shuffled != tier:
		_shuffle_playlist_order()
	_play_track_at_cursor()


func _shuffle_playlist_order() -> void:
	var tier := _desired_playlist_tier()
	var streams := _get_streams_for_tier(tier)
	_playlist_order.clear()
	if streams.is_empty():
		push_warning("SoundManager: нет треков в плейлисте тира %d (%s/island_%02d)" % [tier, PLAYLIST_ROOT, tier])
		_playlist_tier_when_shuffled = -1
		return
	for i in range(streams.size()):
		_playlist_order.append(i)
	_playlist_order.shuffle()
	_playlist_cursor = 0
	_playlist_tier_when_shuffled = tier


func _duplicate_stream_no_loop(base: AudioStream) -> AudioStream:
	var s: AudioStream = base.duplicate()
	if s is AudioStreamMP3:
		(s as AudioStreamMP3).loop = false
	elif s is AudioStreamOggVorbis:
		(s as AudioStreamOggVorbis).loop = false
	elif s is AudioStreamWAV:
		(s as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_DISABLED
	return s


func _play_track_at_cursor() -> void:
	var tier := _desired_playlist_tier()
	if _playlist_order.is_empty() or _playlist_tier_when_shuffled != tier:
		_shuffle_playlist_order()
	var streams := _get_streams_for_tier(tier)
	if streams.is_empty() or _playlist_order.is_empty():
		return
	_playlist_cursor = clampi(_playlist_cursor, 0, _playlist_order.size() - 1)
	var stream_index: int = _playlist_order[_playlist_cursor]
	if stream_index < 0 or stream_index >= streams.size():
		_shuffle_playlist_order()
		if _playlist_order.is_empty():
			return
		_playlist_cursor = clampi(_playlist_cursor, 0, _playlist_order.size() - 1)
		stream_index = _playlist_order[_playlist_cursor]
	var base: AudioStream = streams[stream_index]
	var s: AudioStream = _duplicate_stream_no_loop(base)
	_music.stop()
	_music.stream = s
	_music.volume_db = VOL_MUSIC + _music_duck_db
	_music.play()


func _on_music_track_finished() -> void:
	var tier := _desired_playlist_tier()
	var streams := _get_streams_for_tier(tier)
	if streams.is_empty():
		return
	if _playlist_tier_when_shuffled != tier or _playlist_order.size() != streams.size():
		_shuffle_playlist_order()
		if _playlist_order.is_empty():
			return
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
	var p := _pick_sfx_player()
	p.stream = stream
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


## Блип голоса при появлении реплики (speaker_id из DialogueLine).
func play_dialogue_speaker_blip(speaker_id: String) -> void:
	var sid: String = speaker_id.strip_edges().to_lower()
	var stream: AudioStream = null
	var pitch: float = 1.0
	if _SPEAKER_BLIP.has(sid):
		var spec: Array = _SPEAKER_BLIP[sid]
		var idx: int = int(spec[0])
		var kind: StringName = spec[1]
		pitch = float(spec[2])
		stream = _dialogue_mumble_at(kind, idx)
	else:
		## Неизвестный id — стабильно от строки (не rand), чтобы новые персонажи сразу получали «свой» тембр.
		var h: int = hash(sid)
		var u: int = absi(h)
		stream = DIALOGUE_MUMBLE_MALE[u % DIALOGUE_MUMBLE_MALE.size()]
		pitch = 0.93 + float((u >> 4) % 7) * 0.02
	if stream == null:
		stream = STREAM_UI_DIALOGUE
		pitch = 1.0
	_play_sfx(stream, pitch, VOL_DIALOGUE, BUS_DIALOGUE)


func _dialogue_mumble_at(kind: StringName, idx: int) -> AudioStream:
	var a: Array[AudioStream] = DIALOGUE_MUMBLE_MALE
	if kind == &"female":
		a = DIALOGUE_MUMBLE_FEMALE
	elif kind == &"whisper":
		a = DIALOGUE_MUMBLE_WHISPER
	if a.is_empty():
		return null
	return a[idx % a.size()]


## Меню отряда: свой блип на тип юнита (группы ally_* / сюжетный юноша).
func play_dialogue_speaker_blip_for_squad_unit(unit: Node) -> void:
	if unit == null or not is_instance_valid(unit):
		play_dialogue_speaker_blip("hero")
		return
	if unit.is_in_group("ally_archer"):
		play_dialogue_speaker_blip("_squad_archer")
	elif unit.is_in_group("ally_lancer"):
		play_dialogue_speaker_blip("_squad_lancer")
	elif unit.is_in_group("story_youth_companion"):
		play_dialogue_speaker_blip("young_worker")
	elif unit.is_in_group("ally_pawn"):
		play_dialogue_speaker_blip("_squad_pawn")
	else:
		play_dialogue_speaker_blip("_squad_default")


## Совместимость: раньше — один UI-щелчок с случайным pitch; теперь блип героя (меню отряда вызывает явно).
func play_dialogue_advance() -> void:
	play_dialogue_speaker_blip("hero")


func play_dialogue_page_turn() -> void:
	_play_sfx(STREAM_DIALOGUE_PAGE_TURN, randf_range(0.96, 1.04), VOL_DIALOGUE_PAGE, BUS_DIALOGUE)


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


## Лечение: мягкий щелчок (page_turn).
func play_heal() -> void:
	_play_sfx(STREAM_DIALOGUE_PAGE_TURN, randf_range(1.05, 1.15), VOL_HEAL, BUS_SFX)


## Телепорт / смена локации в UI.
func play_teleport() -> void:
	_play_sfx(STREAM_UI_MENU_CLOSE, randf_range(0.88, 0.96), VOL_TELEPORT, BUS_UI)
