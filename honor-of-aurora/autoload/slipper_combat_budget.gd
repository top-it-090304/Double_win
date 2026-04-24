extends RefCounted
class_name SlipperCombatBudget
## TASK-015: бюджет тяжёлой логики боя в режиме «На тапке» (дистанция до героя, без изменения урона/HP).

## Полный AI каждый физкадр, если герой ближе этого порога (мировые px).
## SLIPPER: узкая зона — дальше враги идут прямо на цель без навигации/лучей.
const NEAR_FULL_AI_DISTANCE_PX := 2000.0
const NEAR_FULL_AI_DISTANCE_PX_SLIPPER := 720.0
## Запас к радиусу атаки: overlap/дистанция не должны «отставать» на кадр при редком AI.
const CONSERVATIVE_ATTACK_REACH_MARGIN_PX := 420.0
## Дальше от героя: полный тяжёлый AI (навигация, выбор цели, soft-sep, анимация) раз в N физкадров.
const FAR_HEAVY_AI_INTERVAL_FRAMES := 4
const FAR_HEAVY_AI_INTERVAL_FRAMES_SLIPPER := 12

## Снаряды дальше этого расстояния до героя могут откладывать шаг движения (накопление delta — средняя скорость сохраняется).
const PROJECTILE_NEAR_PLAYER_PX := 1600.0
const PROJECTILE_DEFER_EVERY_N_PROCESS_FRAMES := 2
## Совпадает с enemy_base._MELEE_EXTRA_REACH_PX: overlaps_body на GLES может быть «на весь экран» — не доверяем ему в SLIPPER.
const _MELEE_EXTRA_REACH_PX := 90.0

## TASK-018: NavigationAgent2D — шире пороги waypoint/финиша в SLIPPER (меньше микро-репасов; target_desired ≥ path_desired).
const ENEMY_NAV_PATH_DESIRED_DEFAULT := 22.0
const ENEMY_NAV_TARGET_DESIRED_DEFAULT := 28.0
const ENEMY_NAV_PATH_DESIRED_SLIPPER := 30.0
const ENEMY_NAV_TARGET_DESIRED_SLIPPER := 40.0
## Рабочие (pawn_base): дефолты как в _ready.
const PAWN_NAV_PATH_DESIRED_DEFAULT := 16.0
const PAWN_NAV_TARGET_DESIRED_DEFAULT := 28.0
const PAWN_NAV_PATH_DESIRED_SLIPPER := 22.0
const PAWN_NAV_TARGET_DESIRED_SLIPPER := 38.0
## Дальше NEAR_FULL_AI — реже выставлять target_position (меньше запросов пути к NavigationServer), get_next_path_position по-прежнему каждый кадр движения по агенту.
const NAV_TARGET_REFRESH_FAR_INTERVAL_FRAMES := 2
const NAV_TARGET_REFRESH_FAR_INTERVAL_FRAMES_SLIPPER := 6


static func apply_enemy_navigation_agent_preset(agent: NavigationAgent2D) -> void:
	if agent == null or not is_instance_valid(agent):
		return
	if PerformancePreset.is_slipper_mode(SaveManager):
		agent.path_desired_distance = ENEMY_NAV_PATH_DESIRED_SLIPPER
		agent.target_desired_distance = ENEMY_NAV_TARGET_DESIRED_SLIPPER
	else:
		agent.path_desired_distance = ENEMY_NAV_PATH_DESIRED_DEFAULT
		agent.target_desired_distance = ENEMY_NAV_TARGET_DESIRED_DEFAULT


static func _melee_reach_max_dist_sq(attack_radius_px: float, attack_area: Area2D) -> float:
	var reach: float = attack_radius_px
	if attack_area != null and is_instance_valid(attack_area):
		var sh := attack_area.get_node_or_null("AttackShape") as CollisionShape2D
		if sh != null and sh.shape is CircleShape2D:
			reach = (sh.shape as CircleShape2D).radius
			var gs: Vector2 = sh.get_global_transform().get_scale().abs()
			reach *= maxf(gs.x, gs.y)
	var max_d: float = reach + _MELEE_EXTRA_REACH_PX
	return max_d * max_d


static func _player_aim_global(player: Node2D) -> Vector2:
	if player == null or not is_instance_valid(player):
		return Vector2.ZERO
	var aim: Vector2 = player.global_position
	var cs := player.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if cs != null and cs.shape != null:
		aim = cs.global_position
	return aim


## Как enemy_base._is_target_within_melee_distance: только геометрия, без overlaps_body.
static func player_in_credible_melee_reach_pixels(
	attack_radius_px: float,
	attack_area: Area2D,
	player: Node2D
) -> bool:
	if attack_area == null or not is_instance_valid(attack_area):
		return false
	if player == null or not is_instance_valid(player):
		return false
	var rsq := _melee_reach_max_dist_sq(attack_radius_px, attack_area)
	var origin: Vector2 = attack_area.global_position
	var aim := _player_aim_global(player)
	return origin.distance_squared_to(aim) <= rsq


static func apply_pawn_navigation_agent_preset(agent: NavigationAgent2D) -> void:
	if agent == null or not is_instance_valid(agent):
		return
	if PerformancePreset.is_slipper_mode(SaveManager):
		agent.path_desired_distance = PAWN_NAV_PATH_DESIRED_SLIPPER
		agent.target_desired_distance = PAWN_NAV_TARGET_DESIRED_SLIPPER
	else:
		agent.path_desired_distance = PAWN_NAV_PATH_DESIRED_DEFAULT
		agent.target_desired_distance = PAWN_NAV_TARGET_DESIRED_DEFAULT


static func should_push_nav_target_to_player_this_physics_frame(
	enemy: Node2D,
	attack_radius_px: float,
	attack_area: Area2D,
	player: Node2D,
	physics_frame: int
) -> bool:
	## Одно чтение на вызов — Variant / Node-setter и сравнения лишние в горячем пути.
	var slipper: bool = PerformancePreset.is_slipper_mode(SaveManager)
	if not slipper:
		return true
	if enemy == null or not is_instance_valid(enemy):
		return true
	if enemy.is_in_group(&"BOSS"):
		return true
	if player == null or not is_instance_valid(player):
		return true
	var dist: float = enemy.global_position.distance_to(player.global_position)
	var near_thr: float = NEAR_FULL_AI_DISTANCE_PX_SLIPPER
	var nav_iv: int = NAV_TARGET_REFRESH_FAR_INTERVAL_FRAMES_SLIPPER
	if dist <= near_thr:
		return true
	if attack_radius_px > 0.0 and dist <= attack_radius_px + CONSERVATIVE_ATTACK_REACH_MARGIN_PX:
		return true
	if attack_area != null and is_instance_valid(attack_area) and attack_area.monitoring:
		if player_in_credible_melee_reach_pixels(attack_radius_px, attack_area, player):
			return true
	return (physics_frame % nav_iv) == 0


static func should_push_nav_target_worker_vs_player_this_physics_frame(
	worker: Node2D,
	player: Node2D,
	physics_frame: int
) -> bool:
	if not PerformancePreset.is_slipper_mode(SaveManager):
		return true
	if worker == null or not is_instance_valid(worker):
		return true
	if player == null or not is_instance_valid(player):
		return true
	if worker.global_position.distance_to(player.global_position) <= NEAR_FULL_AI_DISTANCE_PX_SLIPPER:
		return true
	return (physics_frame % NAV_TARGET_REFRESH_FAR_INTERVAL_FRAMES_SLIPPER) == 0


static func should_run_heavy_ai_for_enemy(
	enemy: Node2D,
	attack_radius_px: float,
	attack_area: Area2D,
	player: Node2D,
	physics_frame: int
) -> bool:
	if not PerformancePreset.is_slipper_mode(SaveManager):
		return true
	if enemy == null or not is_instance_valid(enemy):
		return true
	if enemy.is_in_group(&"BOSS"):
		return true
	if player == null or not is_instance_valid(player):
		return true
	var enemy_pos: Vector2 = enemy.global_position
	var pp: Vector2 = player.global_position
	## Горячий путь (вызов на каждого врага каждый физкадр) — избегаем дорогой sqrt в distance_to,
	## сравниваем квадрат дистанции.
	var near_thr: float = NEAR_FULL_AI_DISTANCE_PX_SLIPPER
	var far_iv: int = FAR_HEAVY_AI_INTERVAL_FRAMES_SLIPPER
	var dist_sq: float = enemy_pos.distance_squared_to(pp)
	if dist_sq <= near_thr * near_thr:
		return true
	var dist: float = sqrt(dist_sq)
	if dist <= near_thr:
		return true
	if attack_radius_px > 0.0 and dist <= attack_radius_px + CONSERVATIVE_ATTACK_REACH_MARGIN_PX:
		return true
	if attack_area != null and is_instance_valid(attack_area) and attack_area.monitoring:
		if player_in_credible_melee_reach_pixels(attack_radius_px, attack_area, player):
			return true
	return (physics_frame % far_iv) == 0


static func should_defer_projectile_motion_frame(projectile_pos: Vector2, player: Node2D, process_frame: int) -> bool:
	if not PerformancePreset.is_slipper_mode(SaveManager):
		return false
	if player == null or not is_instance_valid(player):
		return false
	if projectile_pos.distance_to(player.global_position) <= PROJECTILE_NEAR_PLAYER_PX:
		return false
	return (process_frame % PROJECTILE_DEFER_EVERY_N_PROCESS_FRAMES) != 0
