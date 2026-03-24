class_name ResourceStripFrames
extends Object
## Нарезка горизонтального листа в SpriteFrames (равные кадры).

static func build_horizontal_strip(tex: Texture2D, frame_count: int, fps: float = 12.0) -> SpriteFrames:
	var sf := SpriteFrames.new()
	if tex == null or frame_count < 1:
		return sf
	var tw: int = tex.get_width()
	var th: int = tex.get_height()
	var fw: int = tw / frame_count
	if fw < 1:
		return sf
	var dur := 1.0 / maxf(0.01, fps)
	# SpriteFrames.new() уже содержит пустую анимацию "default" — не вызывать add_animation.
	sf.set_animation_loop(&"default", true)
	for i in range(frame_count):
		var at := AtlasTexture.new()
		at.atlas = tex
		at.region = Rect2(i * fw, 0, fw, th)
		sf.add_frame(&"default", at, dur)
	return sf


static func build_single_frame(tex: Texture2D) -> SpriteFrames:
	var sf := SpriteFrames.new()
	if tex == null:
		return sf
	sf.set_animation_loop(&"default", true)
	sf.add_frame(&"default", tex, 1.0)
	return sf
