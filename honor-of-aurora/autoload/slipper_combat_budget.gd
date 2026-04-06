extends RefCounted
class_name SlipperCombatBudget
## TASK-015: бюджет тяжёлой логики боя в режиме «На тапке» (дистанция до героя, без изменения урона/HP).

## Полный AI каждый физкадр, если герой ближе этого порога (мировые px).
const NEAR_FULL_AI_DISTANCE_PX := 2000.0
## Запас к радиусу атаки: overlap/дистанция не должны «отставать» на кадр при редком AI.
const CONSERVATIVE_ATTACK_REACH_MARGIN_PX := 420.0
## Дальше от героя: полный тяжёлый AI (навигация, выбор цели, soft-sep, анимация) раз в N физкадров.
const FAR_HEAVY_AI_INTERVAL_FRAMES := 4

## Снаряды дальше этого расстояния до героя могут откладывать шаг движения (накопление delta — средняя скорость сохраняется).
const PROJECTILE_NEAR_PLAYER_PX := 1600.0
const PROJECTILE_DEFER_EVERY_N_PROCESS_FRAMES := 2

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


static func apply_enemy_navigation_agent_preset(agent: NavigationAgent2D) -> void:
	if agent == null or not is_instance_valid(agent):
		return
	if PerformancePreset.is_slipper_mode(SaveManager):
		agent.path_desired_distance = ENEMY_NAV_PATH_DESIRED_SLIPPER
		agent.target_desired_distance = ENEMY_NAV_TARGET_DESIRED_SLIPPER
	else:
		agent.path_desired_distance = ENEMY_NAV_PATH_DESIRED_DEFAULT
		agent.target_desired_distance = ENEMY_NAV_TARGET_DESIRED_DEFAULT


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
	if not PerformancePreset.is_slipper_mode(SaveManager):
		return true
	if enemy == null or not is_instance_valid(enemy):
		return true
	if enemy.is_in_group(&"BOSS"):
		return true
	if player == null or not is_instance_valid(player):
		return true
	var dist: float = enemy.global_position.distance_to(player.global_position)
	if dist <= NEAR_FULL_AI_DISTANCE_PX:
		return true
	if attack_radius_px > 0.0 and dist <= attack_radius_px + CONSERVATIVE_ATTACK_REACH_MARGIN_PX:
		return true
	if attack_area != null and is_instance_valid(attack_area) and attack_area.monitoring and attack_area.overlaps_body(player):
		return true
	return (physics_frame % NAV_TARGET_REFRESH_FAR_INTERVAL_FRAMES) == 0


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
	if worker.global_position.distance_to(player.global_position) <= NEAR_FULL_AI_DISTANCE_PX:
		return true
	return (physics_frame % NAV_TARGET_REFRESH_FAR_INTERVAL_FRAMES) == 0


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
	var dist: float = enemy_pos.distance_to(pp)
	if dist <= NEAR_FULL_AI_DISTANCE_PX:
		return true
	if attack_radius_px > 0.0 and dist <= attack_radius_px + CONSERVATIVE_ATTACK_REACH_MARGIN_PX:
		return true
	if attack_area != null and is_instance_valid(attack_area) and attack_area.monitoring and attack_area.overlaps_body(player):
		return true
	return (physics_frame % FAR_HEAVY_AI_INTERVAL_FRAMES) == 0


static func should_defer_projectile_motion_frame(projectile_pos: Vector2, player: Node2D, process_frame: int) -> bool:
	if not PerformancePreset.is_slipper_mode(SaveManager):
		return false
	if player == null or not is_instance_valid(player):
		return false
	if projectile_pos.distance_to(player.global_position) <= PROJECTILE_NEAR_PLAYER_PX:
		return false
	return (process_frame % PROJECTILE_DEFER_EVERY_N_PROCESS_FRAMES) != 0
