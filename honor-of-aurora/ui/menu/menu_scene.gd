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
## Выше карты и выше MenuCanvas с кнопками (там layer 10): облака рисуются поверх картинок кнопок.
## Клики идут в кнопки: облака — Node2D + input_pickable=false, не участвуют в GUI.
@export var menu_clouds_canvas_layer: int = 15

var spawn_timer: Timer
var _menu_clouds_canvas: CanvasLayer


func _ready():
	Events.current_location = Events.LOCATION.MENU
	await get_tree().process_frame

	_menu_clouds_canvas = CanvasLayer.new()
	_menu_clouds_canvas.name = "MenuCloudsLayer"
	_menu_clouds_canvas.layer = menu_clouds_canvas_layer
	add_child(_menu_clouds_canvas)
	var deco_cloud: Node = get_node_or_null(^"cloud")
	if deco_cloud != null:
		deco_cloud.reparent(_menu_clouds_canvas)

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
	_menu_clouds_canvas.add_child(cloud_instance)
