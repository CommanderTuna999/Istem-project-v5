extends Area2D

var speed = 700.0
var direction = Vector2.RIGHT
var damage = 8.0
var spin_speed = 100.0

func _ready() -> void:
	rotation = direction.angle()

func _physics_process(delta: float) -> void:
	position += direction * speed * delta
	rotation += spin_speed * delta

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		if body.has_method("take_player_damage"):
			body.take_player_damage(damage)
		if body.has_method("bleed"):
			body.bleed()
		queue_free()
	elif body.is_in_group("walls"):
		queue_free()

func _on_lifetime_timer_timeout() -> void:
	queue_free()
