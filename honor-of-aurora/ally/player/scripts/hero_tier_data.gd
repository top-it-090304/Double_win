class_name HeroTierData
extends Resource

@export var sprite_frames: SpriteFrames
@export var speed: float = 250.0
@export var max_health: int = 1000
@export var attack_damage: int = 90
## Higher = faster attack animation (shorter time between hits).
@export var attack_anim_speed_scale: float = 1.0
## Idle / run / death animation speed.
@export var move_anim_speed_scale: float = 1.0
