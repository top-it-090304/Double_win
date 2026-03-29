class_name OreVariantLibrary
extends RefCounted
## Случайная текстура сердцевины из `res://Asets/Руда/` (1.png … 9.png). Кэш загрузки — один раз за сессию.

const _BASE := "res://Asets/Руда"

static var _textures: Array[Texture2D] = []


static func pick_random_ore_texture() -> Texture2D:
	if _textures.is_empty():
		for i in range(1, 10):
			var path := "%s/%d.png" % [_BASE, i]
			if ResourceLoader.exists(path):
				var tex: Texture2D = load(path) as Texture2D
				if tex:
					_textures.append(tex)
	if _textures.is_empty():
		return null
	return _textures[randi() % _textures.size()]
