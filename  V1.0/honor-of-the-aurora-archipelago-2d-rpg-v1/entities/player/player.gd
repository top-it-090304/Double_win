extends CharacterBody2D

@export var speed: int = 350  # Нормальная скорость для 2D RPG
@onready var anim_player = $AnimationPlayer

func _ready():
	print("🎮 Игрок загружен")
	print("📍 Начальная позиция: ", position)
	
	# Сброс позиции если нужно
	if position.x < 50 or position.x > 750 or position.y < 50 or position.y > 550:
		position = Vector2(400, 300)
		print("🔄 Позиция сброшена: ", position)
	
	# Проверка анимаций
	if anim_player:
		var anims = anim_player.get_animation_list()
		print("📺 Доступные анимации: ", anims)
		
		# Если анимаций нет - создадим временные
		if "idle" not in anims:
			print("⚠️ Создаю временную idle анимацию")
			var idle_anim = Animation.new()
			idle_anim.length = 1.0
			anim_player.add_animation("idle", idle_anim)
			
		if "run" not in anims:
			print("⚠️ Создаю временную run анимацию")
			var run_anim = Animation.new()
			run_anim.length = 1.0
			anim_player.add_animation("run", run_anim)

func _physics_process(delta):
	# Получаем ввод
	var direction = Vector2.ZERO
	
	# Используем Input Actions
	if Input.is_action_pressed("move_right"): direction.x += 1
	if Input.is_action_pressed("move_left"): direction.x -= 1
	if Input.is_action_pressed("move_down"): direction.y += 1
	if Input.is_action_pressed("move_up"): direction.y -= 1
	
	# Обработка движения
	if direction.length() > 0:
		direction = direction.normalized()
		velocity = direction * speed
		
		# Анимация бега
		if anim_player.has_animation("run"):
			anim_player.play("run")
	else:
		velocity = Vector2.ZERO
		# Анимация покоя
		if anim_player.has_animation("idle"):
			anim_player.play("idle")
	
	# Применяем движение
	move_and_slide()
	
	# Быстрая отладка (раз в 10 кадров)
	if Engine.get_frames_drawn() % 10 == 0:
		print("📊 Pos: ", position.round(), " Vel: ", velocity.round())

func _input(event):
	# Быстрая диагностика ввода
	if event is InputEventKey and event.pressed:
		print("🎹 Клавиша: ", char(event.keycode))
