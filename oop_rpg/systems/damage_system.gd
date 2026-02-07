class_name DamageSystem
extends Node

static func calculate_damage(base_damage: int, attacker_level: int, defender_defense: int) -> int:
    var defense_multiplier = 100.0 / (100.0 + defender_defense)
    var calculated_damage = base_damage * defense_multiplier
    return int(calculated_damage)

static func calculate_critical(base_damage: int, critical_chance: float, critical_multiplier: float) -> int:
    if randf() * 100 < critical_chance:
        return int(base_damage * critical_multiplier)
    return base_damage
