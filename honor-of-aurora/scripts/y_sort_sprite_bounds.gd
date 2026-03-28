class_name YSortSpriteBounds
extends Object
## Общая логика Y-сортировки: максимальный global Y по углам видимых Sprite2D / AnimatedSprite2D
## (в Godot Y вниз — это «низ» спрайта на экране). Возвращает NAN, если нечего учитывать.


static func local_rect_for_sprite(node: Node2D) -> Rect2:
	if node is Sprite2D:
		return (node as Sprite2D).get_rect()
	if node is AnimatedSprite2D:
		var asn := node as AnimatedSprite2D
		var sf := asn.sprite_frames
		if sf == null:
			return Rect2()
		var anim: StringName = asn.animation
		if not sf.has_animation(anim):
			return Rect2()
		var fc := sf.get_frame_count(anim)
		if fc <= 0:
			return Rect2()
		var idx := clampi(asn.frame, 0, fc - 1)
		var tex: Texture2D = sf.get_frame_texture(anim, idx)
		if tex == null:
			return Rect2()
		var size := tex.get_size()
		if asn.centered:
			return Rect2(-size * 0.5 + asn.offset, size)
		return Rect2(asn.offset, size)
	return Rect2()


static func max_global_y_from_descendants(root: Node) -> float:
	var found := false
	var max_y := 0.0
	var stack: Array[Node] = [root]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n is Sprite2D or n is AnimatedSprite2D:
			var spr := n as CanvasItem
			if spr.visible:
				var rect: Rect2 = local_rect_for_sprite(n as Node2D)
				if rect.has_area():
					var p := rect.position
					var s := rect.size
					for corner in [p, p + Vector2(s.x, 0.0), p + Vector2(0.0, s.y), p + s]:
						var gy: float = (n as Node2D).to_global(corner).y
						if not found or gy > max_y:
							max_y = gy
						found = true
		for c in n.get_children():
			stack.append(c)
	if found:
		return max_y
	return NAN
