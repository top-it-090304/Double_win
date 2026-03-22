class_name DialogueSequence
extends Resource

## Необязательный ключ (квесты, сохранение «уже показали») — используйте в своей логике.
@export var id: String = ""

@export var lines: Array[DialogueLine] = []


## Переопределите в подклассах, если строки собираются в коде (например после загрузки .tres).
func ensure_lines_ready() -> void:
	pass
