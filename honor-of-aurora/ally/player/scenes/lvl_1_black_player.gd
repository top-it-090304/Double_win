extends "res://ally/player/scripts/worrier_base.gd"

func _ready():
	super._ready()
	_apply_black_level1_stats()

func _enter_tree() -> void:
	super._enter_tree()
	if _player_ready:
		_apply_black_level1_stats()

func sync_from_save() -> void:
	super.sync_from_save()
	_apply_black_level1_stats()


func reset_after_death_resume() -> void:
	super.reset_after_death_resume()
	_apply_black_level1_stats()

func _apply_black_level1_stats() -> void:
	max_health = 100
	if health_component:
		health_component.set_max_health(max_health)
	health = mini(SaveManager.current_health, max_health)
	attack_damage = 100
	speed = 200
	super._refresh_health_bar_ui()
