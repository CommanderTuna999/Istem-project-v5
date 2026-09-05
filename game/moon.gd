extends Node2D

@onready var moon_sprite: Sprite2D = $Sprite2D
@onready var cut_line: Line2D = $Line2D
@onready var shatter_particles: GPUParticles2D = $GPUParticles2D


@onready var left_half: Sprite2D = $Sprite2D/LeftHalf
@onready var right_half: Sprite2D = $Sprite2D/RightHalf

var slide_direction: Vector2 = Vector2.ZERO

func _ready() -> void:
	cut_line.visible = false
	shatter_particles.emitting = false
	

	left_half.visible = false
	right_half.visible = false
	
	
	left_half.position = Vector2.ZERO
	right_half.position = Vector2.ZERO
	
	moon_sprite.modulate.a = 0.0
	
	var spawn_tween = create_tween()
	spawn_tween.tween_property(moon_sprite, "modulate:a", 1.0, 0.4)

func shatter() -> void:
	var sprite_size = moon_sprite.texture.get_size() * moon_sprite.scale
	var top_right = Vector2(sprite_size.x / 2.0, -sprite_size.y / 2.0)
	var bottom_left = Vector2(-sprite_size.x / 2.0, sprite_size.y / 2.0)
	

	var cut_vector = bottom_left - top_right
	slide_direction = Vector2(-cut_vector.y, cut_vector.x).normalized()
	
	cut_line.points = [top_right, top_right]
	cut_line.visible = true
	
	var tween = create_tween()
	tween.tween_method(update_cut_line.bind(top_right, bottom_left), 0.0, 1.0, 0.5)
	tween.tween_callback(finish_shatter)

func update_cut_line(progress: float, start_point: Vector2, end_point: Vector2) -> void:
	cut_line.points = [start_point, start_point.lerp(end_point, progress)]

func finish_shatter() -> void:
	cut_line.visible = false
	
	shatter_particles.global_position = global_position
	shatter_particles.restart()
	shatter_particles.emitting = true
	

	left_half.visible = true
	right_half.visible = true
	
	var fade_tween = create_tween().set_parallel(true)
	

	fade_tween.tween_property(moon_sprite, "modulate", Color(4, 4, 4, 0), 0.35)
	fade_tween.tween_property(moon_sprite, "scale", moon_sprite.scale * 1.15, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	

	var slide_distance = 75.0 
	fade_tween.tween_property(left_half, "position", left_half.position - (slide_direction * slide_distance), 0.3).set_trans(Tween.TRANS_QUAD)
	fade_tween.tween_property(right_half, "position", right_half.position + (slide_direction * slide_distance), 0.3).set_trans(Tween.TRANS_QUAD)
	
	await get_tree().create_timer(2.25).timeout
	queue_free()
