extends Node2D

@onready var moon_sprite: Sprite2D = $Sprite2D
@onready var cut_line: Line2D = $Line2D
@onready var shatter_particles: GPUParticles2D = $GPUParticles2D


func _ready() -> void:
	cut_line.visible = false
	shatter_particles.emitting = false


func shatter() -> void:
	var sprite_size = moon_sprite.texture.get_size() * moon_sprite.scale
	var top_right = Vector2(sprite_size.x / 2.0, -sprite_size.y / 2.0)
	var bottom_left = Vector2(-sprite_size.x / 2.0, sprite_size.y / 2.0)

	cut_line.points = [top_right, top_right]
	cut_line.visible = true

	var tween = create_tween()
	tween.tween_property(cut_line, "points", PackedVector2Array([top_right, bottom_left]), 0.5)
	tween.tween_callback(finish_shatter)


func finish_shatter() -> void:
	moon_sprite.visible = false
	cut_line.visible = false
	shatter_particles.global_position = global_position
	shatter_particles.emitting = true

	await get_tree().create_timer(1.5).timeout
	queue_free()
