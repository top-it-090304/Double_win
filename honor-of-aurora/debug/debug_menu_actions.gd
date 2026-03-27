extends RefCounted
## Только для ui/debug_menu (F3). Не autoload — подключается из debug_menu.gd.
## Ресурсы: те же GameManager.add_* что подбор/награды; SaveManager только внутри GameManager.

func grant_gold(amount: int) -> void:
	GameManager.add_gold(amount)


func grant_wood(amount: int) -> void:
	GameManager.add_wood(amount)


func grant_meat(amount: int) -> void:
	GameManager.add_meat(amount)


func grant_ore(amount: int) -> void:
	GameManager.add_ore(amount)


func grant_exp(amount: int) -> void:
	GameManager.add_exp(amount)


func reset_death_count() -> void:
	GameManager.debug_reset_death_count_to_zero()


func add_hero_speed_bonus(delta: float) -> void:
	GameManager.debug_add_hero_speed_bonus(delta)


func apply_progress_reset_like_new_game() -> void:
	GameManager.debug_apply_progress_reset_like_new_game()
