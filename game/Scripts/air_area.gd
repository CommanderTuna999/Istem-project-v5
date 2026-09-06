extends Area2D


func _on_body_entered(body: Node2D) -> void:
	if body.has_method("enter_air"):
		body.enter_air()
		
func _on_body_exited(body: Node2D) -> void:
	if body.has_method("exit_air"):
		body.exit_air()
