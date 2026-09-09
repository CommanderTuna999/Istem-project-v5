extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("Restart"):
		get_tree().call_deferred("change_scene_to_file", "res://Scenes/level_01.tscn")
		get_tree().call_deferred("reload_current_scene")
