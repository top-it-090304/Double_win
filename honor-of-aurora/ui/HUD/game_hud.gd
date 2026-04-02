extends CanvasLayer
## Базовый HUD (корневой скрипт наследует отсюда).

func show_teleport_menu() -> void:
	pass


func hide_teleport_menu() -> void:
	pass


func show_castle_menu() -> void:
	pass


func hide_castle_menu() -> void:
	pass


func show_barracks_menu() -> void:
	pass


func hide_barracks_menu() -> void:
	pass


func show_monastery_menu() -> void:
	pass


func hide_monastery_menu() -> void:
	pass


func show_archery_menu() -> void:
	pass


func hide_archery_menu() -> void:
	pass


func show_payshop_menu() -> void:
	pass


func hide_payshop_menu() -> void:
	pass


func show_camp_codex_menu() -> void:
	pass


func hide_camp_codex_menu() -> void:
	pass


func try_open_squad_orders_menu(_unit: Node2D) -> bool:
	return false


func teleport_to(_location: Events.LOCATION) -> void:
	pass


func set_target_location(_location: Events.LOCATION) -> void:
	pass


func apply_user_ui_scale() -> void:
	pass
