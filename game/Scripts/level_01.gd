extends Area2D



		
func on_LEVELONE_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		get_tree().call_deferred("change_scene_to_file", "res://Scenes/level_01.tscn")


func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("Restart"):
		get_tree().call_deferred("change_scene_to_file", "res://Scenes/Game.tscn")
