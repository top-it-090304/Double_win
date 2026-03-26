extends Area2D

## Меню здания открывается по нажатию «атаки» в зоне (как у монаха), не при входе в область.
enum MenuKind { CASTLE, BARRACKS }
@export var menu_kind: MenuKind = MenuKind.CASTLE


func _ready() -> void:
	add_to_group("building_menu_zone")


func try_open_menu_if_player_inside() -> bool:
	if DialogueManager.is_active():
		return false
	var tree := get_tree()
	var player := tree.get_first_node_in_group("player") as Node2D
	if player == null or not is_instance_valid(player):
		return false
	if not GameplayFacade.is_player_body(player):
		return false
	if not overlaps_body(player):
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
	return false
