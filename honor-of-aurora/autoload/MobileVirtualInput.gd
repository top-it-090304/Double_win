extends Node

## Виртуальный ввод с сенсорного HUD: движение, атака (тап), щит (удержание).
## Состояние щита читается напрямую по shield_held в worrier_base.

var enabled: bool = false
var move_vector: Vector2 = Vector2.ZERO
var shield_held: bool = false

var _attack_pending: bool = false


func set_controls_visible(v: bool) -> void:
	enabled = v
	if not v:
		clear_input()


func queue_attack() -> void:
	if not enabled:
		return
	_attack_pending = true


func consume_attack() -> bool:
	if not enabled:
		return false
	var a := _attack_pending
	_attack_pending = false
	return a


func has_attack_pending() -> bool:
	return _attack_pending


func clear_input() -> void:
	move_vector = Vector2.ZERO
	shield_held = false
	_attack_pending = false
