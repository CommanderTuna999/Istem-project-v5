extends Area2D

@export var current_direction: Vector2 = Vector2.RIGHT
@export var current_strength: float = 700.0


func _on_body_entered(body: Node2D) -> void:
	if body.has_method("enter_current"):
		body.enter_current(self)


func _on_body_exited(body: Node2D) -> void:
	if body.has_method("exit_current"):
		body.exit_current(self)
