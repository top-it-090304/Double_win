
extends "res://enemies/base_enemy.gd"

#  параметры для большого орка-гоблина
@export var rage_mode_threshold: float = 0.3  # 30% здоровья - режим ярости
@export var slam_attack_cooldown: float = 6.0
@export var charge_attack_speed: float = 300.0
@export var charge_attack_damage_multiplier: float = 2.0

var is_raging: bool = false
var can_slam: bool = true
var is_charging: bool = false
var original_speed: float

func _ready():
  # Характеристики большого орка-гоблина
  speed = 80.0                # Быстрее обычных орков, но все еще медленный
  health = 800                # Очень много здоровья
  attack_damage = 35          # Сильные удары
  attack_cooldown = 2.5       # Медленные атаки
  detection_radius = 600.0    # Хорошо видит
  gold_reward = 750           # Щедрая награда
  patrol_change_time = 3.0    # Медленно меняет направление 
  
  original_speed = speed
  
  # У орка-гоблина может быть своя анимация
  # если есть в спрайт листе и Толя сделал)
  
  super()

func _on_take_damage(amount: int):
  # Проверяем, не вошел ли в ярость
  var health_percent = float(health) / float(health + amount)  # Приблизительный расчет
  
  if health_percent <= rage_mode_threshold and not is_raging:
    enter_rage_mode()
  
  super(amount)

func enter_rage_mode():
  is_raging = true
  speed = original_speed * 1.5
  attack_damage = int(attack_damage * 1.8)
  attack_cooldown = attack_cooldown * 0.6
  anim.modulate = Color(1, 0.8, 0.8)  # Легкий красный оттенок
  
  # Кричит при входе в ярость
  if anim.sprite_frames.has_animation("roar"):
    anim.play("roar")
    await anim.animation_finished
  
  print("Большой орк-гоблин в ярости!")

func _on_attack_start():
  # Случайный выбор атаки
  var random_attack = randi() % 3  # 0, 1 или 2
  
  match random_attack:
    0:
      normal_attack()
    1:
      try_slam_attack()
    2:
      try_charge_attack()

func normal_attack():
  # Обычная атака (по умолчанию)
  anim.play("attack")

func try_slam_attack():
  if can_slam and is_raging:
    can_slam = false
    anim.play("slam_attack")
    
    # Создаем эффект удара по земле
    create_slam_effect()
    
    # Таймер восстановления
    await get_tree().create_timer(slam_attack_cooldown).timeout
    can_slam = true
  else:
    # Если не может сделать slam, делает обычную атаку
    normal_attack()

func create_slam_effect():
  # Создаем область поражения от удара
  var slam_area = Area2D.new()
  var collision = CollisionShape2D.new()
  var shape = CircleShape2D.new()
  shape.radius = 150
  collision.shape = shape
  slam_area.add_child(collision)
  
  slam_area.global_position = global_position
  get_parent().add_child(slam_area)
  
  # Наносим урон всем в области
  for body in slam_area.get_overlapping_bodies():
    if body.is_in_group("player"):
      body.take_damage(attack_damage * 2)
      # Отбрасываем игрока
      var knockback = (body.global_position - global_position).normalized() * 300
      body.velocity += knockback
  
  # Визуальный эффект
  if anim.sprite_frames.has_animation("slam_effect"):
    var effect = AnimatedSprite2D.new()
    effect.sprite_frames = anim.sprite_frames
    effect.play("slam_effect")
    effect.global_position = global_position + Vector2(0, 50)
    add_child(effect)
    await effect.animation_finished
    effect.queue_free()
  
  # Удаляем область через небольшое время
  await get_tree().create_timer(0.3).timeout
  slam_area.queue_free()

func try_charge_attack():
  if not is_charging and is_raging:
    start_charge_attack()

func start_charge_attack():
  is_charging = true
  
  # Анимация подготовки
  if anim.sprite_frames.has_animation("charge_start"):
    anim.play("charge_start")
    await anim.animation_finished
  
  # Определяем направление до игрока
  if player:
    var charge_direction = (player.global_position - global_position).normalized()
    last_dir = charge_direction
    
    # Визуальный индикатор
    show_charge_indicator(charge_direction)
    
    # Рывок
    var charge_time = 1.0
    var timer = 0.0
    
    while timer < charge_time and is_charging and player:
      velocity = charge_direction * charge_attack_speed
      move_and_slide()
      timer += get_process_delta_time()
      
      # Проверяем столкновение с игроком во время рывка
      if attack_area.overlaps_body(player):
        player.take_damage(int(attack_damage * charge_attack_damage_multiplier))
        # Отбрасываем игрока
        var knockback = charge_direction * 400
        player.velocity += knockback
        break
      
      # Если врезался в стену
      if is_on_wall():
        create_slam_effect()  # Эффект удара о стену
        break
      
      await get_tree().process_frame
    
    # Завершение рывка
    is_charging = false
    speed = original_speed
    
    # Орк оглушен после рывка
    state = State.HIT
    anim.play("hit")
    await anim.animation_finished
    state = State.CHASE

func show_charge_indicator(direction: Vector2):
  # Показываем направление атаки (например, стрелку)
  var indicator = Line2D.new()
  indicator.points = [Vector2.ZERO, direction * 200]
  indicator.width = 5
  indicator.default_color = Color.RED
  add_child(indicator)
  
  await get_tree().create_timer(0.5).timeout
  indicator.queue_free()

func _on_animation_finished(animation_name: String):
  if animation_name == "charge_start":
    # Продолжаем атаку
    pass
  elif animation_name == "slam_attack":
    # Возвращаемся к обычному поведению
    if player and detection_area.overlaps_body(player):
      state = State.CHASE

func _on_death():
  print("Большой орк-гоблин повержен!")
  # Эффект при смерти
  anim.modulate = Color(1, 1, 1)  # Возвращаем нормальный цвет
  
  # Может выронить уникальный предмет
  drop_unique_item()
  
  super()

func drop_unique_item():
  # Шанс выпадения особого предмета
  if randf() < 0.3:  # 30% шанс
    var item_scene = preload("res://items/orc_trophy.tscn")  #нужна сцена
    if item_scene:
      var item = item_scene.instantiate()
      item.global_position = global_position
      get_parent().add_child(item)
      print("Выпал трофей большого орка-гоблина!")
