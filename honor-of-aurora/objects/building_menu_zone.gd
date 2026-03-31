extends Area2D

## Меню здания открывается по нажатию «атаки» в зоне (как у монаха), не при входе в область.
enum MenuKind { CASTLE, BARRACKS, MONASTERY, ARCHERY, PAYSHOP }
@export var menu_kind: MenuKind = MenuKind.CASTLE


func _ready() -> void:
	add_to_group("building_menu_zone")
	## Стрельбище / замок: зона у коллизии здания — цель патруля часто недостижима или даёт залипание.
	if menu_kind != MenuKind.ARCHERY and menu_kind != MenuKind.CASTLE:
		add_to_group("base_patrol_zone")
	if menu_kind == MenuKind.CASTLE:
		add_to_group("base_ore_castle_dropoff")


func try_open_menu_if_player_inside() -> bool:
	if DialogueManager.is_active():
		return false
	var tree := get_tree()
	var player := tree.get_first_node_in_group("player") as Node2D
	if player == null or not is_instance_valid(player):
		return false
	if not GameplayFacade.is_player_body(player):
		return false
	var inside := overlaps_body(player)
	if not inside:
		if menu_kind == MenuKind.PAYSHOP:
			# Фолбэк для pay_zone: если у конкретной сцены сбиты маски Area2D, оставляем активацию по близости.
			var self_2d := self as Node2D
			if self_2d == null or self_2d.global_position.distance_to(player.global_position) > 92.0:
				return false
		else:
			return false
	var hud := GameplayFacade.get_hud(tree)
	if hud == null:
		return false
	match menu_kind:
		MenuKind.CASTLE:
			if not hud.has_method("show_castle_menu"):
				return false
			if hud.castle_menu != null and hud.castle_menu.visible:
				return false
			hud.show_castle_menu()
			return true
		MenuKind.BARRACKS:
			if not hud.has_method("show_barracks_menu"):
				return false
			if hud.barracks_menu != null and hud.barracks_menu.visible:
				return false
			hud.show_barracks_menu()
			return true
		MenuKind.MONASTERY:
			if not hud.has_method("show_monastery_menu"):
				return false
			if hud.monastery_menu != null and hud.monastery_menu.visible:
				return false
			hud.show_monastery_menu()
			return true
		MenuKind.ARCHERY:
			if not hud.has_method("show_archery_menu"):
				return false
			if hud.archery_menu != null and hud.archery_menu.visible:
				return false
			hud.show_archery_menu()
			return true
		MenuKind.PAYSHOP:
			if not hud.has_method("show_payshop_menu"):
				return false
			if hud.payshop_menu != null and hud.payshop_menu.visible:
				return false
			hud.show_payshop_menu()
			return true
	return false
