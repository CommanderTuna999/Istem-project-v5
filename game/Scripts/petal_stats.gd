extends Node

var bonus_damage: float = 0.0


func update_missing_health_bonus(current_health: float, max_health: float) -> void:
	if max_health <= 0.0:
		bonus_damage = 0.0
		return

	var health_percent: float = clampf(current_health / max_health, 0.0, 1.0)
	var missing_health_percent: float = 1.0 - health_percent

	bonus_damage = missing_health_percent * 0.5
