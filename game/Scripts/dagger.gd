extends Area2D

var speed = 750.0
var damage = 5
var spin_speed = 25.0
var direction = Vector2.RIGHT
var thrower = null

@onready var lifetime_timer: Timer = $Timer

func _init() -> void:
	collision_layer = 32
	collision_mask = 3

func _ready() -> void:
	rotation = direction.angle()
	lifetime_timer.start(7.5)

func _physics_process(delta: float) -> void:
	position += direction * speed * delta
	rotation += spin_speed * delta

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		if body.has_method("take_player_damage"):
			body.take_player_damage(damage)
		if body.has_method("apply_dagger_slow"):
			body.apply_dagger_slow()
		if is_instance_valid(thrower) and thrower.has_method("gain_rage") and thrower.rage_level < 10:
			thrower.gain_rage()
		if is_instance_valid(thrower) and thrower.permanent_rage and body.has_method("apply_pull"):
			var pull_direction = (thrower.global_position - body.global_position).normalized()
			body.apply_pull(pull_direction * 150.0)
		queue_free()
	elif body.is_in_group("walls"):
		queue_free()

func _on_lifetime_timer_timeout() -> void:
	queue_free()
