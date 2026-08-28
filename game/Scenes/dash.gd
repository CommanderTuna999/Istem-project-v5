extends Node2D

@onready var player = $Player
@export var on_cooldown = false
var cooldown = 1.0

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("Ability") and AbilityFolder.ability == "Extra_Dash" and not on_cooldown:
		start_extra_dash(player.direction)
	var mouse_pos = get_global_mouse_position()

func start_extra_dash(direction: Vector2) -> void:
	if direction.length() > 0.0:
		player.dash_direction = direction.normalized()
	else:
		player.dash_direction = (get_global_mouse_position() - player.global_position).normalized()

	if player.dash_direction == Vector2.ZERO:
		return
	player.get_node("DashParticles").rotation = player.dash_direction.angle()
	player.get_node("DashParticles").restart()
	player.get_node("DashParticles").emitting = true
	player.is_dashing = true
	player.dash_timer = player.dash_duration
