extends RefCounted
class_name CodexNewMarker
## Общая жёлтая иконка «новое в журнале» для HUD, вкладок и списков.

static var _tex: ImageTexture


static func get_badge_texture() -> Texture2D:
	if _tex != null:
		return _tex
	var w := 20
	var h := 24
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var fill := Color(0.98, 0.84, 0.14, 1.0)
	var edge := Color(0.22, 0.14, 0.04, 1.0)
	# столбик
	for y in range(4, 15):
		for x in range(9, 12):
			_px(img, x, y, fill)
	# обводка столбика
	for y in range(3, 16):
		_px(img, 8, y, edge)
		_px(img, 12, y, edge)
	for x in range(9, 12):
		_px(img, x, 3, edge)
		_px(img, x, 15, edge)
	# точка
	for y in range(17, 20):
		for x in range(8, 13):
			_px(img, x, y, fill)
	for y in range(16, 21):
		_px(img, 7, y, edge)
		_px(img, 13, y, edge)
	for x in range(8, 13):
		_px(img, x, 16, edge)
		_px(img, x, 20, edge)
	_tex = ImageTexture.create_from_image(img)
	return _tex


static func _px(img: Image, x: int, y: int, c: Color) -> void:
	if x < 0 or y < 0 or x >= img.get_width() or y >= img.get_height():
		return
	img.set_pixel(x, y, c)
