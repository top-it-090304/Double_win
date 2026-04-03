extends Node2D

## Ориентир высоты для смещения полосы спавна слева (половина типичного спрайта облака).
const _REF_CLOUD_TEXTURE: Texture2D = preload(
	"res://Asets/Unit_pack/Terrain/Decorations/Clouds/Clouds_01.png"
)
## Синхронно с `cloud_base.visual_scale` по умолчанию (1.1 = +10% к размеру).
const _CLOUD_VISUAL_SCALE: float = 1.1

@export var cloud_scene: PackedScene
@export var spawn_x: float = -200
@export var spawn_interval: float = 2.0

var spawn_timer: Timer


func _ready():
	Events.current_location = Events.LOCATION.MENU
	await get_tree().process_frame

	spawn_timer = Timer.new()
	spawn_timer.wait_time = spawn_interval
	spawn_timer.autostart = true
	add_child(spawn_timer)
	spawn_timer.timeout.connect(_on_cloud_spawn_timer_timeout)


func _on_cloud_spawn_timer_timeout() -> void:
	var cloud_instance = cloud_scene.instantiate()

	var screen_height: float = get_viewport().get_visible_rect().size.y
	var half_cloud_h: float = float(_REF_CLOUD_TEXTURE.get_height()) * 0.5 * _CLOUD_VISUAL_SCALE
	# Левый поток: полоса спавна ниже на половину высоты облака (асимметрия к «верхней» сетке экрана).
	var random_y: float = randf_range(half_cloud_h, screen_height)

	cloud_instance.position = Vector2(spawn_x, random_y)
	add_child(cloud_instance)
