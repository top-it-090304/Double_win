extends "res://path/to/base_enemy.gd"  # Укажите правильный путь

func _ready():
  # Переопределяем параметры
  speed = 150.0
  health = 100
  attack_damage = 10
  attack_cooldown = 1.5
  detection_radius = 600.0
  gold_reward = 75  # Своя награда
  
  # Вызов родительского _ready()
  super()

func _on_take_damage(amount: int):
  #  логика при получении урона
  print("Враг получил урон: ", amount)

func _on_death():
  #  логика перед смертью
  print("Враг умирает...")
