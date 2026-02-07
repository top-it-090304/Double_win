class_name AudioManager
extends Node

@onready var music_player: AudioStreamPlayer = $MusicPlayer
@onready var sfx_player: AudioStreamPlayer = $SFXPlayer

func play_music(music_stream: AudioStream) -> void:
    music_player.stream = music_stream
    music_player.play()

func play_sfx(sfx_stream: AudioStream) -> void:
    sfx_player.stream = sfx_stream
    sfx_player.play()

func set_music_volume(volume: float) -> void:
    music_player.volume_db = linear_to_db(volume)

func set_sfx_volume(volume: float) -> void:
    sfx_player.volume_db = linear_to_db(volume)
