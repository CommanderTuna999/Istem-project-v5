extends Node2D
@onready var moon_sprite: Sprite2D = $Sprite2D
@onready var left_half: Sprite2D = $LeftHalf
@onready var right_half: Sprite2D = $RightHalf
@onready var cut_line: Line2D = $Line2D
@onready var shatter_particles: GPUParticles2D = $GPUParticles2D
@export var ghost_offset_distance: float = 300.0
@export var ghost_travel_duration: float = 0.6
@export var ghost_light_alpha: float = 0.2
@export var ghost_dark_alpha: float = 0.2

@onready var ghost_left: Sprite2D = $GhostLeft
@onready var ghost_right: Sprite2D = $GhostRight


var slide_direction: Vector2 = Vector2.ZERO
func _ready() -> void:
	cut_line.visible = false
	shatter_particles.emitting = false
	
	left_half.visible = false
	right_half.visible = false
	
	moon_sprite.visible = false
	moon_sprite.modulate.a = 0.0
	ghost_left.scale = Vector2(20.692, 20.692)
	ghost_right.scale = Vector2(20.692, 20.692)
	play_coalesce_intro()
	


func shatter(cut_direction: Vector2 = Vector2.RIGHT) -> void:
	var sprite_size = moon_sprite.texture.get_size() * moon_sprite.scale
	var half_width = sprite_size.x / 2.0


	var start_point: Vector2
	var end_point: Vector2
	var horizontal_sign: float

	if cut_direction.x >= 0.0:

		horizontal_sign = 1.0
		start_point = Vector2(-half_width, 0.0)
		end_point = Vector2(half_width, 0.0)
	else:

		horizontal_sign = -1.0
		start_point = Vector2(half_width, 0.0)
		end_point = Vector2(-half_width, 0.0)

	slide_direction = Vector2(horizontal_sign, 0.0)


	cut_line.points = [start_point, start_point]
	cut_line.visible = true


	var tween = create_tween()

	tween.tween_callback(finish_shatter)

func update_cut_line(progress: float, start_point: Vector2, end_point: Vector2) -> void:
	cut_line.points = [start_point, start_point.lerp(end_point, progress)]
func finish_shatter() -> void:
	moon_sprite.visible = false
	cut_line.visible = false
	left_half.visible = true
	right_half.visible = true
	
	shatter_particles.global_position = global_position
	shatter_particles.restart()
	shatter_particles.emitting = true
	
	var fade_tween = create_tween().set_parallel(true)
	
	var flash_color = Color(5, 5, 5, 0) 
	fade_tween.tween_property(left_half, "modulate", flash_color, 0.25)
	fade_tween.tween_property(right_half, "modulate", flash_color, 0.25)
	
	var slide_distance = 80.0
	fade_tween.tween_property(left_half, "position", left_half.position - (slide_direction * slide_distance), 0.25).set_trans(Tween.TRANS_QUAD)
	fade_tween.tween_property(right_half, "position", right_half.position + (slide_direction * slide_distance), 0.25).set_trans(Tween.TRANS_QUAD)
	
	await get_tree().create_timer(2.25).timeout
	queue_free()

func play_coalesce_intro() -> void:
	ghost_left.texture = moon_sprite.texture
	ghost_right.texture = moon_sprite.texture

	ghost_left.position = Vector2(-ghost_offset_distance, 0.0)
	ghost_right.position = Vector2(ghost_offset_distance, 0.0)

	ghost_left.modulate = Color(1.4, 1.4, 1.4, 0.0)
	ghost_right.modulate = Color(0.5, 0.5, 0.5, 0.0)

	ghost_left.visible = true
	ghost_right.visible = true

	var intro_tween = create_tween().set_parallel(true)

	intro_tween.tween_property(ghost_left, "modulate:a", ghost_light_alpha, ghost_travel_duration * 0.5)
	intro_tween.tween_property(ghost_right, "modulate:a", ghost_dark_alpha, ghost_travel_duration * 0.5)

	intro_tween.tween_property(ghost_left, "position", Vector2.ZERO, ghost_travel_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	intro_tween.tween_property(ghost_right, "position", Vector2.ZERO, ghost_travel_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	intro_tween.chain().tween_callback(coalesce_into_moon)


func coalesce_into_moon() -> void:
	ghost_left.visible = false
	ghost_right.visible = false

	moon_sprite.visible = true
	var spawn_tween = create_tween()
	spawn_tween.tween_property(moon_sprite, "modulate:a", 1.0, 0.7)
