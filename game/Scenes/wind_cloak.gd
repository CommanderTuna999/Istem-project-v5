extends Node

var on_cooldown = false
var duration = 10.0

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("Ability") and AbilityFolder.ability == "Wind_Cloak" and not on_cooldown:
		activate_wind_cloak()

func activate_wind_cloak():
	var player := get_tree().get_first_node_in_group("player") as CharacterBody2D
	player.total_speed_increase += 1.5
	player.total_defence_increase += 30.0
	await get_tree().create_timer(duration).timeout
