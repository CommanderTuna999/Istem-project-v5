extends Node

var current_mana: float = 100.0
var max_mana: float = 100.0
var mana_regeneration: float = 2.5

func _process(delta: float) -> void:
	if current_mana < max_mana:
		current_mana += mana_regeneration * delta
		current_mana = min(current_mana, max_mana)
