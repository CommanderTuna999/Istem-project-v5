extends CharacterBody2D

@export var speed: float = 220.0
@export var health: float = 5.0
@export var bounce_variation_degrees: float = 8.0

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer

var dying: bool = false

var base_sprite_scale: Vector2 = Vector2.ONE
var base_sprite_rotation: float = 0.0

var bounce_tween: Tween = null


func _ready() -> void:
	base_sprite_scale = animated_sprite_2d.scale
	base_sprite_rotation = animated_sprite_2d.rotation

	animated_sprite_2d.play("idle")

	var starting_angle: float = randf_range(0.0, TAU)
	velocity = Vector2.RIGHT.rotated(starting_angle) * speed


func _physics_process(delta: float) -> void:
	if dying:
		return

	var collision: KinematicCollision2D = move_and_collide(
		velocity * delta
	)

	if collision:
		var normal: Vector2 = collision.get_normal()

		velocity = velocity.bounce(normal)

		var random_turn: float = deg_to_rad(
			randf_range(
				-bounce_variation_degrees,
				bounce_variation_degrees
			)
		)

		velocity = velocity.rotated(random_turn).normalized() * speed

		bounce_visual(normal)

	if velocity.x > 0.0:
		animated_sprite_2d.flip_h = false

	elif velocity.x < 0.0:
		animated_sprite_2d.flip_h = true


func bounce_visual(normal: Vector2) -> void:
	if bounce_tween != null:
		if bounce_tween.is_valid():
			bounce_tween.kill()

	var horizontal_hit: bool = (
		absf(normal.x) >= absf(normal.y)
	)

	var squash_scale: Vector2

	if horizontal_hit:
		squash_scale = Vector2(
			base_sprite_scale.x * 0.68,
			base_sprite_scale.y * 1.32
		)

	else:
		squash_scale = Vector2(
			base_sprite_scale.x * 1.32,
			base_sprite_scale.y * 0.68
		)

	animated_sprite_2d.scale = squash_scale

	var rotation_kick: float = deg_to_rad(
		randf_range(-10.0, 10.0)
	)

	animated_sprite_2d.rotation = (
		base_sprite_rotation + rotation_kick
	)

	bounce_tween = create_tween()

	bounce_tween.tween_property(
		animated_sprite_2d,
		"scale",
		Vector2(
			base_sprite_scale.x * 1.08,
			base_sprite_scale.y * 0.94
		),
		0.045
	)

	bounce_tween.parallel().tween_property(
		animated_sprite_2d,
		"rotation",
		base_sprite_rotation,
		0.045
	)

	bounce_tween.tween_property(
		animated_sprite_2d,
		"scale",
		base_sprite_scale,
		0.07
	)


func take_damage(amount: float) -> void:
	if dying:
		return

	health -= amount

	if health <= 0.0:
		dying = true
		queue_free()
		return

	if bounce_tween != null:
		if bounce_tween.is_valid():
			bounce_tween.kill()

	animated_sprite_2d.scale = base_sprite_scale
	animated_sprite_2d.rotation = base_sprite_rotation

	animation_player.stop()
	animation_player.play("damaged")
