class_name HeroProgression
extends RefCounted

const _MAX_TIER_INDEX := 4

const _BLUE := preload("res://ally/player/resources/blue_worrier_frame.tres")
const _PURPLE := preload("res://ally/player/resources/purple_worrier_frame.tres")
const _BLACK := preload("res://ally/player/resources/black_worrier_frame.tres")
const _RED := preload("res://ally/player/resources/red_worrier_frame.tres")
const _YELLOW := preload("res://ally/player/resources/yellow_worrier_frame.tres")

static var _tiers: Array[HeroTierData] = []

static func _ensure_tiers() -> void:
	if not _tiers.is_empty():
		return
	# Уровни 1–5: HP и урон ниже старых значений (раньше у 1 уровня было 400 HP — слишком много для старта).
	_tiers = [
		_make(_BLUE, 220.0, 120, 28, 1.0, 1.0),
		_make(_PURPLE, 235.0, 165, 38, 1.08, 1.0),
		_make(_BLACK, 250.0, 215, 48, 1.15, 1.0),
		_make(_RED, 265.0, 275, 58, 1.22, 1.02),
		_make(_YELLOW, 280.0, 340, 68, 1.3, 1.04),
	]


static func _make(
		frames: SpriteFrames,
		move_speed: float,
		hp: int,
		dmg: int,
		atk_scale: float,
		move_anim_scale: float
	) -> HeroTierData:
	var t := HeroTierData.new()
	t.sprite_frames = frames
	t.speed = move_speed
	t.max_health = hp
	t.attack_damage = dmg
	t.attack_anim_speed_scale = atk_scale
	t.move_anim_speed_scale = move_anim_scale
	return t


static func tier_index_for_level(level: int) -> int:
	return clampi(level - 1, 0, _MAX_TIER_INDEX)


static func get_tier_for_level(level: int) -> HeroTierData:
	_ensure_tiers()
	return _tiers[tier_index_for_level(level)]
