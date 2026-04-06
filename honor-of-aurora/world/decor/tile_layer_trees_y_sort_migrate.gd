extends TileMapLayer
## Переносит тайлы слоя (деревья, кусты и др. декор на TileMapLayer) в Sprite2D / AnimatedSprite2D
## и стирает тайлы, чтобы YSortManager сортировал их вместе с юнитами.

const _SpriteScript := preload("res://world/decor/y_sort_tree_sprite.gd")
const _AnimScript := preload("res://world/decor/y_sort_tree_animated_sprite.gd")


func _ready() -> void:
	call_deferred("_migrate_deferred")


func _migrate_deferred() -> void:
	var ts := tile_set
	if ts == null:
		return
	var cells: Array[Vector2i] = []
	for c in get_used_cells():
		cells.append(c)
	for cell in cells:
		_migrate_cell(cell, ts)
	## У слоя в сцене часто y_sort_enabled = true (для тайлов). После миграции дочерние Sprite2D
	## сортируются движком по Y **origin** (верх спрайта при centered=false), а YSortManager — по
	## **низу** через get_y_sort_bottom_y(). Два правила дают сдвиг ~на высоту спрайта при отрисовке.
	y_sort_enabled = false
	add_to_group("slipper_cull_decor_layer")


func _migrate_cell(cell: Vector2i, ts: TileSet) -> void:
	var src_id := get_cell_source_id(cell)
	if src_id < 0:
		return
	var src := ts.get_source(src_id) as TileSetAtlasSource
	if src == null:
		return
	var atlas_coords := get_cell_atlas_coords(cell)
	var td := get_cell_tile_data(cell)
	if td == null:
		return
	## Совпадает с TileMapLayer::draw_tile (Godot 4.4): верхний левый угол нарисованного тайла =
	## map_to_local(cell) - region_size/2 - texture_origin (не map_to_local + texture_origin).
	var region0 := Rect2i(src.get_tile_texture_region(atlas_coords, 0))
	var region_size := Vector2(region0.size)
	var base_local: Vector2 = map_to_local(cell)
	var tex_origin := Vector2(td.texture_origin)
	var pos_local: Vector2
	if td.transpose:
		pos_local = base_local - Vector2(region_size.y, region_size.x) * 0.5 - tex_origin
	else:
		pos_local = base_local - region_size * 0.5 - tex_origin
	var frame_count: int = int(src.get_tile_animation_frames_count(atlas_coords))
	if frame_count > 1:
		_spawn_animated_sprite(src, atlas_coords, td, pos_local, frame_count)
	else:
		_spawn_static_sprite(src, atlas_coords, td, pos_local)
	erase_cell(cell)


func _spawn_static_sprite(src: TileSetAtlasSource, atlas_coords: Vector2i, td: TileData, pos_local: Vector2) -> void:
	var spr := Sprite2D.new()
	spr.set_script(_SpriteScript)
	spr.texture = src.texture
	spr.region_enabled = true
	spr.region_rect = Rect2(src.get_tile_texture_region(atlas_coords, 0))
	spr.centered = false
	spr.position = pos_local
	spr.flip_h = td.flip_h
	spr.flip_v = td.flip_v
	spr.modulate = td.modulate
	add_child(spr)


func _spawn_animated_sprite(
	src: TileSetAtlasSource,
	atlas_coords: Vector2i,
	td: TileData,
	pos_local: Vector2,
	frame_count: int
) -> void:
	## Режим «На тапке» (SLIPPER): без AnimatedSprite2D и без проигрывания — только первый кадр тайловой анимации.
	if PerformancePreset.is_slipper_mode(SaveManager):
		_spawn_static_sprite(src, atlas_coords, td, pos_local)
		return
	var speed: float = float(src.get_tile_animation_speed(atlas_coords))
	speed = maxf(speed, 0.001)
	var sf := SpriteFrames.new()
	# В части сборок Godot 4 у нового SpriteFrames уже есть анимация "default".
	if not sf.has_animation(&"default"):
		sf.add_animation(&"default")
	sf.set_animation_loop(&"default", true)
	for i in frame_count:
		var region := Rect2(src.get_tile_texture_region(atlas_coords, i))
		var dur: float = float(src.get_tile_animation_frame_duration(atlas_coords, i)) / speed
		if dur <= 0.0:
			dur = 1.0 / speed
		var at := AtlasTexture.new()
		at.atlas = src.texture
		at.region = region
		sf.add_frame(&"default", at, dur)
	var asn := AnimatedSprite2D.new()
	asn.set_script(_AnimScript)
	asn.sprite_frames = sf
	asn.animation = &"default"
	asn.centered = false
	asn.position = pos_local
	asn.flip_h = td.flip_h
	asn.flip_v = td.flip_v
	asn.modulate = td.modulate
	add_child(asn)
	asn.play(&"default")
