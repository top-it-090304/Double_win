extends Control

func get_hud():
	return get_tree().get_first_node_in_group("hud")

func _on_button_pressed() -> void:
	print("Кнопка 1 нажата")  # ОТЛАДКА
	var hud = get_hud()
	print("HUD найден: ", hud)  # ОТЛАДКА
	if hud:
		hud.teleport_to(Events.LOCATION.LVL1)



func _on_button_2_pressed() -> void:
	var hud = get_hud()
	if hud:
		hud.teleport_to(Events.LOCATION.LVL2)


func _on_button_3_pressed() -> void:
	var hud = get_hud()
	if hud:
		hud.teleport_to(Events.LOCATION.LVL3)


func _on_button_4_pressed() -> void:
	var hud = get_hud()
	if hud:
		hud.teleport_to(Events.LOCATION.LVL4)


func _on_button_5_pressed() -> void:
	var hud = get_hud()
	if hud:
		hud.teleport_to(Events.LOCATION.LVL5)




func _on_button_6_pressed() -> void:
	print("Кнопка 6 нажата")  # ОТЛАДКА
	var hud = get_hud()
	if hud:
		hud.hide_teleport_menu()


func _on_button_7_pressed() -> void:
	var hud = get_hud()
	if hud:
		hud.teleport_to(Events.LOCATION.BASE)
