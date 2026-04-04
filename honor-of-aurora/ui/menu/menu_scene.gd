extends Node2D

## Ориентир высоты для смещения полосы спавна слева (половина типичного спрайта облака).
const _REF_CLOUD_TEXTURE: Texture2D = preload(
	"res://Asets/Unit_pack/Terrain/Decorations/Clouds/Clouds_01.png"
)
const _HUD_PACKED: PackedScene = preload("res://ui/HUD/canvas_layer.tscn")
## Синхронно с `cloud_base.visual_scale` по умолчанию (1.1 = +10% к размеру).
const _CLOUD_VISUAL_SCALE: float = 1.1

@export var cloud_scene: PackedScene
@export var spawn_x: float = -200
@export var spawn_interval: float = 2.0
## Выше всего мира меню (тайлы, декор, кнопки как «лежачие камни» на Node2D).
## Модалки/настройки — свои CanvasLayer выше (например 100). Клики по кнопкам: спрайты облаков не Control.
@export var menu_clouds_canvas_layer: int = 6
## HUD эпилога: выше слоя облаков меню.
const _MENU_EPILOGUE_HUD_LAYER: int = 12

var spawn_timer: Timer
var _menu_clouds_canvas: CanvasLayer


func _ready():
	Events.current_location = Events.LOCATION.MENU
	_ensure_menu_camera_centered()
	await get_tree().process_frame
	## После стабилизации current_scene — режим окна SLIPPER без viewport stretch для меню.
	SaveManager.call_deferred("apply_window_and_engine_settings")
	## После await у GameManager.handle_location_changed — стабильное сохранение в SaveManager.
	call_deferred("_apply_post_finale_menu_thanks_chest")

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


## Без активной Camera2D 2D-вид привязан к левому верхнему углу вьюпорта: при stretch expand ширина «нарастает» вправо.
## Камера с якорем по центру держит базовый кадр по центру экрана при любом соотношении сторон.
func _ensure_menu_camera_centered() -> void:
	var cam := get_node_or_null(^"MenuViewportCamera") as Camera2D
	if cam == null:
		cam = Camera2D.new()
		cam.name = "MenuViewportCamera"
		add_child(cam)
	cam.anchor_mode = Camera2D.ANCHOR_MODE_DRAG_CENTER
	var bw: float = float(ProjectSettings.get_setting("display/window/size/viewport_width", 1280))
	var bh: float = float(ProjectSettings.get_setting("display/window/size/viewport_height", 720))
	cam.position = Vector2(bw * 0.5, bh * 0.5)
	cam.make_current()


## Сундук — после финальных титров. Герой у сундука — в меню, если финал пройден (счётчик боссов / остров 5 / титры).
func _apply_post_finale_menu_thanks_chest() -> void:
	var chest := get_node_or_null(^"MenuThanksChest")
	if chest == null:
		return
	var show_chest := (
		SaveManager.menu_post_finale_thanks_unlocked
		or StoryState.has_flag("menu_post_finale_thanks_unlocked")
	)
	chest.visible = show_chest

	if _should_spawn_menu_hero_for_thanks_chest():
		GameManager.spawn_menu_player_next_to_chest(self, chest as Node2D)
		var hud: CanvasLayer = _HUD_PACKED.instantiate() as CanvasLayer
		if hud:
			hud.layer = _MENU_EPILOGUE_HUD_LAYER
		add_child(hud)
		call_deferred("_menu_epilogue_hud_passthrough_fullscreen_bg", hud)


func _should_spawn_menu_hero_for_thanks_chest() -> bool:
	## Не только boss_kill == 5: в сейвах счётчик мог расходиться с сюжетом; титры/остров 5 — надёжнее.
	if SaveManager.boss_kill >= 5:
		return true
	if StoryState.has_flag("story_island_5_cleared"):
		return true
	return (
		SaveManager.menu_post_finale_thanks_unlocked
		or StoryState.has_flag("menu_post_finale_thanks_unlocked")
	)


## Фон HUD на весь экран: не перехватывать клики по каменным кнопкам под облаками.
## Плюс скрываем верхнюю полосу HUD (ресурсы, HP) — остаются тач и кодекс.
func _menu_epilogue_hud_passthrough_fullscreen_bg(hud: Node) -> void:
	if not is_instance_valid(hud):
		return
	var tr := hud.get_node_or_null(^"TextureRect") as Control
	if tr:
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if hud.has_method("apply_epilogue_menu_minimal_top_hud"):
		hud.call("apply_epilogue_menu_minimal_top_hud")


func _on_cloud_spawn_timer_timeout() -> void:
	var cloud_instance = cloud_scene.instantiate()

	var screen_height: float = get_viewport().get_visible_rect().size.y
	var half_cloud_h: float = float(_REF_CLOUD_TEXTURE.get_height()) * 0.5 * _CLOUD_VISUAL_SCALE
	# Левый поток: полоса спавна ниже на половину высоты облака (асимметрия к «верхней» сетке экрана).
	var random_y: float = randf_range(half_cloud_h, screen_height)

	cloud_instance.position = Vector2(spawn_x, random_y)
	_menu_clouds_canvas.add_child(cloud_instance)
