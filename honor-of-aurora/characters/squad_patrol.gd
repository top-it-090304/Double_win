class_name SquadPatrol
extends Object
## Дешёвый патруль: одна целевая точка в круге вокруг точки спавна, без навигации и без частой смены направления.

## Случайная точка в кольце вокруг center, гарантированно внутри радиуса leash.
static func pick_waypoint(center: Vector2, leash_radius: float) -> Vector2:
	if leash_radius < 8.0:
		return center
	var r_min: float = minf(140.0, leash_radius * 0.2)
	var r_max: float = minf(leash_radius * 0.88, 700.0)
	if r_max < r_min + 24.0:
		r_max = r_min + 40.0
	for _i in range(8):
		var ang := randf() * TAU
		var dist := randf_range(r_min, r_max)
		var p := center + Vector2.RIGHT.rotated(ang) * dist
		if p.distance_to(center) <= leash_radius * 0.92:
			return p
	return center + Vector2.RIGHT.rotated(randf() * TAU) * (leash_radius * 0.48)
