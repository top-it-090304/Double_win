class_name SignalBus
extends Node

# Персонажи
signal character_damaged(character, amount, source)
signal character_died(character)
signal player_spawned(player)

# Мир
signal room_cleared(room_name)
signal room_changed(from_room, to_room)

# UI
signal health_changed(entity, current, max)
signal experience_gained(amount, total)
