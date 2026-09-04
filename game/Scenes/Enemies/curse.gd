extends Area2D

var speed = 250.0
var direction = Vector2.RIGHT
var damage = 8.0
var morecurse: bool = false
var mark_duration = 3.0


func _ready() -> void:
	var sprite: AnimatedSprite2D = $AnimatedSprite2D
	sprite.play("default")
	if morecurse == true:
		sprite.play("cursed")
	pass

func _physics_process(delta: float) -> void:
	position += direction * speed * delta

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		if body.has_method("take_player_damage"):
			body.take_player_damage(damage)
		if body.has_method("reverse_movement"):
			body.reverse_movement()
		if body.has_method("mark"):
			body.mark(mark_duration)
		if morecurse == true:
			if body.has_method("explode"):
				print("exploded")
				body.explode()
		queue_free()
	elif body.is_in_group("walls"):
		queue_free()

func _on_lifetime_timer_timeout() -> void:
	queue_free()
