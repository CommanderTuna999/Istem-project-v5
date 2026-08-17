extends Node

@onready var player = get_tree().get_first_node_in_group("player")
@export var time_stop_active = false
var time_stop_cooldown = false
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("Ability"):
		if AbilityFolder.ability == "Time_Stop":
			if not time_stop_active and not time_stop_cooldown:
				activate_time_stop()

func activate_time_stop() -> void:
	time_stop_active = true
	time_stop_cooldown = true
	print("Time Stop is active.")
	get_node("/root/Game/TimeStopFilter/ColorRect").visible = true
	player.current_health *= 0.71
	await get_tree().create_timer(6.0).timeout
	get_node("/root/Game/TimeStopFilter/ColorRect").visible = false
	time_stop_active = false
	await get_tree().create_timer(1.0).timeout
	time_stop_cooldown = false
	print("Time Stop is ready.")
