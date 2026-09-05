extends CharacterBody2D

@export var health: float = 10
@export var ink_projectile_scene: PackedScene

@export var projectile_gravity: float = 1500.0
@export var projectile_flight_time: float = 0.7
@export var spread_distance: float = 70.0

@export var move_speed: float = 95.0
@export var player_avoid_strength: float = 0.35
@export var close_player_distance: float = 170.0
@export var close_player_avoid_strength: float = 0.8

@export var wall_avoid_strength: float = 1.2
@export var wall_avoid_duration: float = 0.45

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var shoot_point: Marker2D = $ShootPoint
@onready var shoot_timer: Timer = $ShootTimer

var aggro: bool = false
var chase_subject: Node2D = null
var dying: bool = false
var attacking: bool = false

var strafe_direction: float = 1.0

var wall_avoid_timer: float = 0.0
var wall_avoid_direction: Vector2 = Vector2.ZERO

var base_sprite_scale: Vector2 = Vector2.ONE


func _ready() -> void:
	base_sprite_scale = animated_sprite_2d.scale
	animated_sprite_2d.play("idle")


func _physics_process(delta: float) -> void:
	if dying:
		return

	if wall_avoid_timer > 0.0:
		wall_avoid_timer -= delta
	else:
		wall_avoid_direction = Vector2.ZERO

	if aggro and is_instance_valid(chase_subject):
		var to_player: Vector2 = (
			chase_subject.global_position
			- global_position
		)

		var distance_to_player: float = to_player.length()

		var direction_to_player: Vector2 = (
			to_player.normalized()
		)

		var away_from_player: Vector2 = (
			-direction_to_player
		)

		var strafe: Vector2 = (
			direction_to_player.orthogonal()
			* strafe_direction
		)

		var current_player_avoid: float = player_avoid_strength

		if distance_to_player < close_player_distance:
			current_player_avoid = close_player_avoid_strength

		var move_direction: Vector2 = (
			strafe
			+ away_from_player * current_player_avoid
			+ wall_avoid_direction * wall_avoid_strength
		).normalized()

		velocity = move_direction * move_speed

		if chase_subject.global_position.x > global_position.x:
			animated_sprite_2d.flip_h = false
		else:
			animated_sprite_2d.flip_h = true

	else:
		velocity = velocity.move_toward(
			Vector2.ZERO,
			300.0 * delta
		)

	move_and_slide()

	if get_slide_collision_count() > 0:
		var collision: KinematicCollision2D = get_slide_collision(0)

		wall_avoid_direction = collision.get_normal()
		wall_avoid_timer = wall_avoid_duration

		strafe_direction *= -1.0


func shoot_attack() -> void:
	if attacking:
		return

	if dying:
		return

	if not aggro:
		return

	if not is_instance_valid(chase_subject):
		return

	attacking = true

	var contract_tween: Tween = create_tween()

	contract_tween.tween_property(
		animated_sprite_2d,
		"scale",
		Vector2(
			base_sprite_scale.x * 0.82,
			base_sprite_scale.y * 1.14
		),
		0.12
	)

	await contract_tween.finished

	if dying:
		return

	if not aggro or not is_instance_valid(chase_subject):
		animated_sprite_2d.scale = base_sprite_scale
		attacking = false
		return

	shoot_ink_spread()

	var recoil_tween: Tween = create_tween()

	recoil_tween.tween_property(
		animated_sprite_2d,
		"scale",
		Vector2(
			base_sprite_scale.x * 1.16,
			base_sprite_scale.y * 0.88
		),
		0.055
	)

	recoil_tween.tween_property(
		animated_sprite_2d,
		"scale",
		Vector2(
			base_sprite_scale.x * 0.97,
			base_sprite_scale.y * 1.03
		),
		0.07
	)

	recoil_tween.tween_property(
		animated_sprite_2d,
		"scale",
		base_sprite_scale,
		0.09
	)

	await recoil_tween.finished

	attacking = false


func shoot_ink_spread() -> void:
	if dying:
		return

	if not aggro:
		return

	if not is_instance_valid(chase_subject):
		return

	if ink_projectile_scene == null:
		return

	var player_position: Vector2 = chase_subject.global_position

	var direction_to_player: Vector2 = (
		player_position
		- shoot_point.global_position
	).normalized()

	var perpendicular: Vector2 = (
		direction_to_player.orthogonal()
	)

	spawn_ballistic_projectile(
		player_position
		+ perpendicular * spread_distance
	)

	spawn_ballistic_projectile(
		player_position
	)

	spawn_ballistic_projectile(
		player_position
		- perpendicular * spread_distance
	)


func spawn_ballistic_projectile(target_position: Vector2) -> void:
	var projectile: Node2D = ink_projectile_scene.instantiate()

	var start_position: Vector2 = shoot_point.global_position

	var displacement: Vector2 = (
		target_position
		- start_position
	)

	var gravity_vector: Vector2 = Vector2(
		0.0,
		projectile_gravity
	)

	var launch_velocity: Vector2 = (
		displacement
		- 0.5
		* gravity_vector
		* projectile_flight_time
		* projectile_flight_time
	) / projectile_flight_time

	projectile.set(
		"starting_velocity",
		launch_velocity
	)

	projectile.set(
		"gravity_strength",
		projectile_gravity
	)

	get_tree().current_scene.add_child(projectile)

	projectile.global_position = start_position

	if projectile is PhysicsBody2D:
		projectile.add_collision_exception_with(self)


func take_damage(amount: float) -> void:
	if dying:
		return

	health -= amount

	if health <= 0.0:
		dying = true
		queue_free()
		return

	animation_player.stop()
	animation_player.play("damaged")


func _on_aggro_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		aggro = true
		chase_subject = body

		if shoot_timer.is_stopped():
			shoot_timer.start()


func _on_aggro_area_body_exited(body: Node2D) -> void:
	if body == chase_subject:
		aggro = false
		chase_subject = null
		shoot_timer.stop()


func _on_shoot_timer_timeout() -> void:
	shoot_attack()
