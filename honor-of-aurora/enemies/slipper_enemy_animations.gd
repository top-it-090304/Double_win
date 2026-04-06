extends RefCounted
class_name SlipperEnemyAnimations
## Режим «На тапке»: облегчённые SpriteFrames — меньше кадров и ниже FPS анимаций (меньше работы GPU/CPU на переключение кадров).
## Кэш по `resource_path` исходного ресурса; один общий экземпляр на всех врагов с тем же `.tres`/сценой.

static var _cache: Dictionary = {}

## Максимум кадров для «длинных» клипов после урезания.
const _MAX_ATTACK_FRAMES := 4
const _MAX_DEAD_FRAMES := 3
const _MAX_RUN_FRAMES := 4
## Idle: один кадр, очень медленный цикл (визуально почти статика).
const _IDLE_FPS_CAP := 3.5


static func get_or_build_slipper_sprite_frames(source: SpriteFrames) -> SpriteFrames:
	if source == null:
		return null
	var key: String = source.resource_path
	if key.is_empty():
		key = "uid:%s" % str(source.get_instance_id())
	if _cache.has(key):
		return _cache[key]
	var built := _build_reduced_sprite_frames(source)
	_cache[key] = built
	return built


static func _build_reduced_sprite_frames(src: SpriteFrames) -> SpriteFrames:
	var dup: SpriteFrames = src.duplicate(true)
	for anim_name in dup.get_animation_names():
		var n: int = dup.get_frame_count(anim_name)
		if n <= 0:
			continue
		var keep: PackedInt32Array = _indices_to_keep(anim_name, n)
		if keep.size() == 0:
			keep = PackedInt32Array([0])
		## Удаляем с конца, чтобы индексы не сдвигались.
		for i in range(n - 1, -1, -1):
			if not _packed_contains(keep, i):
				dup.remove_frame(anim_name, i)
		_apply_slipper_speed(dup, anim_name, String(anim_name).to_lower())
	return dup


static func _packed_contains(p: PackedInt32Array, v: int) -> bool:
	for x in p:
		if x == v:
			return true
	return false


static func _indices_to_keep(anim_name: StringName, n: int) -> PackedInt32Array:
	if n <= 1:
		return PackedInt32Array([0])
	var s := String(anim_name).to_lower()
	## Idle: один кадр (максимальное урезание).
	if _is_idle_name(s):
		return PackedInt32Array([0])
	if s.contains("hit"):
		return PackedInt32Array([0, n - 1]) if n >= 2 else PackedInt32Array([0])
	if s.contains("dead") or s.contains("death") or s.contains("despawn"):
		return _uniform_sample(n, mini(n, _MAX_DEAD_FRAMES))
	if s.contains("attack") or s.contains("throw") or s.contains("windup") or s.contains("shild") or s.contains("shield") or s.contains("cast"):
		return _uniform_sample(n, mini(n, _MAX_ATTACK_FRAMES))
	if s.contains("run") or s.contains("walk") or s.contains("move") or s.contains("swim"):
		return _stride_or_sample(n, _MAX_RUN_FRAMES)
	## Прочее: каждый второй кадр или усечённая выборка.
	if n <= 3:
		return _uniform_sample(n, n)
	return _stride_or_sample(n, _MAX_ATTACK_FRAMES)


static func _is_idle_name(s: String) -> bool:
	if not s.contains("idle"):
		return false
	if s.contains("run") or s.contains("walk"):
		return false
	return true


static func _uniform_sample(n: int, max_keep: int) -> PackedInt32Array:
	if n <= max_keep:
		var acc: Array[int] = []
		for i in range(n):
			acc.append(i)
		return PackedInt32Array(acc)
	var acc2: Array[int] = []
	var mk: int = maxi(2, max_keep)
	for k in range(mk):
		var idx: int = int(round(float(k) * float(n - 1) / float(mk - 1)))
		idx = clampi(idx, 0, n - 1)
		if acc2.is_empty() or acc2[acc2.size() - 1] != idx:
			acc2.append(idx)
	return PackedInt32Array(acc2)


static func _stride_or_sample(n: int, max_keep: int) -> PackedInt32Array:
	if n <= max_keep:
		var acc: Array[int] = []
		for i in range(n):
			acc.append(i)
		return PackedInt32Array(acc)
	## Каждый второй кадр, пока не упрёмся в max_keep.
	var tmp: Array[int] = []
	var i := 0
	while i < n and tmp.size() < max_keep:
		tmp.append(i)
		i += 2
	if tmp.size() < 2 and n >= 2:
		tmp.append(n - 1)
	return PackedInt32Array(tmp)


static func _apply_slipper_speed(dup: SpriteFrames, anim_name: StringName, s: String) -> void:
	var spd: float = dup.get_animation_speed(anim_name)
	spd = maxf(spd, 0.01)
	if _is_idle_name(s):
		dup.set_animation_speed(anim_name, minf(spd * 0.35, _IDLE_FPS_CAP))
	elif s.contains("hit"):
		dup.set_animation_speed(anim_name, spd * 0.5)
	elif s.contains("dead") or s.contains("death"):
		dup.set_animation_speed(anim_name, spd * 0.55)
	elif s.contains("attack") or s.contains("throw") or s.contains("windup") or s.contains("shild") or s.contains("shield"):
		dup.set_animation_speed(anim_name, spd * 0.55)
	elif s.contains("run") or s.contains("walk") or s.contains("move"):
		dup.set_animation_speed(anim_name, spd * 0.5)
	else:
		dup.set_animation_speed(anim_name, spd * 0.6)
