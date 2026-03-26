extends NavigationRegion2D
## Один регион навигации на остров: по умолчанию — большой прямоугольник (как раньше в коде).
## В редакторе можно заменить `NavigationPolygon` на свой контур с «дырами» под стены.

var _default_outline: PackedVector2Array = PackedVector2Array([
	Vector2(-3200, -1100),
	Vector2(1600, -1100),
	Vector2(1600, 1200),
	Vector2(-3200, 1200),
])


func _ready() -> void:
	navigation_layers = 1
	if navigation_polygon == null:
		_apply_outline(_default_outline)
	elif navigation_polygon.get_polygon_count() == 0 and navigation_polygon.get_outline_count() > 0:
		navigation_polygon.make_polygons_from_outlines()
	elif navigation_polygon.get_polygon_count() == 0:
		_apply_outline(_default_outline)


func _apply_outline(outline: PackedVector2Array) -> void:
	var np := NavigationPolygon.new()
	np.add_outline(outline)
	np.make_polygons_from_outlines()
	navigation_polygon = np
