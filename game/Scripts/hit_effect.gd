extends Node2D
func _ready() -> void:
	await $AnimationPlayer.animation_finished
	queue_free()
