#everyone will look at this script eventually so important info:
#Layer 1 = Player
#Layer 2 = Walls
#Layer 3 = HarpoonProjectile
#Layer 11 = Enemies hurtbox

extends CharacterBody2D

var speed = 185
var damage_occuring = false
var aggro = false
var chase_subject = null

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var damage_number_template: damage_number_template = $damage_number_template

var current_health = 2

var kbtime = 0.0
var kbvelocity = Vector2.ZERO
var dying = false

var rooted: bool = false
var root_timer: float = 0.0

var slow_active: bool = false

var nearbyclownfish: Array[Node2D] = []
var separationdirection: Vector2 = Vector2.ZERO
var separationstrength: float = 220.0
var separationdistance: float = 45.0

@export var homemarker: Marker2D
var homeposition: Vector2 = Vector2.ZERO

@export var patrolpoints: Array[Marker2D] = []
var currentpatrolpoint = 0
@export var patrolspeed: float = 80.0

@export var wanderradius: float = 70.0
@export var wanderspeed: float = 60.0

var wandertarget: Vector2 = Vector2.ZERO
var wanderwaittimer = 0.0

var scroll_drop_increase = 0.0
var scrolls_drop_amount_increase = 0.0

var scrolls_drop_amount:
	get:
		return 1.0 + scrolls_drop_amount_increase

var scroll_drop_chance:
	get:
		return 0.5 + scroll_drop_increase


func _ready() -> void:
	animated_sprite_2d.play("idle")

	if homemarker:
		homeposition = homemarker.global_position
		picknewwandertarget()

	elif patrolpoints.size() > 0:
		currentpatrolpoint = 0


func _process(_delta):
	if TimeStop.time_stop_active == true:
		return

	if is_instance_valid(chase_subject):
		if chase_subject.position.x > position.x:
			animated_sprite_2d.flip_h = true

		elif chase_subject.position.x < position.x:
			animated_sprite_2d.flip_h = false

	if current_health <= 0 and not dying:
		dying = true
		animation_player.play("death")
		await animation_player.animation_finished
		queue_free()


func _on_aggro_area_body_entered(body):
	if TimeStop.time_stop_active == true:
		return

	if body.is_in_group("player"):
		chase_subject = body
		aggro = true
		animated_sprite_2d.play("aggro")


func _on_aggro_area_body_exited(body: Node2D) -> void:
	if TimeStop.time_stop_active == true:
		return

	if body == chase_subject:
		chase_subject = null
		aggro = false
		animated_sprite_2d.play("idle")


func _physics_process(_delta):
	if TimeStop.time_stop_active == true:
		return

	if rooted:
		root_timer -= _delta
		velocity = Vector2.ZERO
		move_and_slide()

		if root_timer <= 0.0:
			rooted = false

		return

	if kbtime > 0:
		kbtime -= _delta
		velocity = kbvelocity

	else:
		if aggro and is_instance_valid(chase_subject):
			var chasedirection: Vector2 = (
				chase_subject.global_position - global_position
			).normalized()

			separationdirection = Vector2.ZERO

			for fish in nearbyclownfish:
				if not is_instance_valid(fish):
					continue

				var awayfromfish: Vector2 = (
					global_position - fish.global_position
				)

				var distancefromfish: float = awayfromfish.length()

				if distancefromfish > 0.0 and distancefromfish < separationdistance:
					var separationamount: float = (
						1.0 - distancefromfish / separationdistance
					)

					separationdirection += (
						awayfromfish.normalized()
						* separationamount
					)

			velocity = (
				chasedirection * speed
				+ separationdirection * separationstrength
			)

			velocity = velocity.limit_length(speed)

		else:
			if homemarker:
				if wanderwaittimer > 0.0:
					wanderwaittimer -= _delta
					velocity = Vector2.ZERO

				else:
					var directiontowander: Vector2 = (
						wandertarget - global_position
					)

					if directiontowander.length() > 10:
						velocity = (
							directiontowander.normalized()
							* wanderspeed
						)

						if velocity.x > 0:
							animated_sprite_2d.flip_h = true

						elif velocity.x < 0:
							animated_sprite_2d.flip_h = false

					else:
						wanderwaittimer = randf_range(0.5, 2.0)
						picknewwandertarget()

			elif patrolpoints.size() > 0:
				var targetpoint: Marker2D = patrolpoints[currentpatrolpoint]

				if is_instance_valid(targetpoint):
					var directiontopoint: Vector2 = (
						targetpoint.global_position - global_position
					)

					if directiontopoint.length() > 10:
						velocity = (
							directiontopoint.normalized()
							* patrolspeed
						)

						if velocity.x > 0:
							animated_sprite_2d.flip_h = true

						elif velocity.x < 0:
							animated_sprite_2d.flip_h = false

					else:
						currentpatrolpoint += 1

						if currentpatrolpoint >= patrolpoints.size():
							currentpatrolpoint = 0

			else:
				velocity = Vector2.ZERO

	move_and_slide()

	if homemarker and not aggro and get_slide_collision_count() > 0:
		var collision: KinematicCollision2D = get_slide_collision(0)
		var normal: Vector2 = collision.get_normal()
		var sideways: Vector2 = normal.orthogonal()

		wandertarget = (
			global_position
			+ normal * 40.0
			+ sideways * randf_range(-20.0, 20.0)
		)

		wanderwaittimer = 0.0


func take_damage(amount: float):
	current_health -= amount
	animation_player.play("damaged")
	damage_number_template.spawn_label(amount, false)
	await get_tree().create_timer(0.1).timeout


func take_kb(source_position: Vector2):
	var kbdirection: Vector2 = (
		global_position - source_position
	).normalized()

	kbvelocity = kbdirection * 600
	kbtime = 0.12


func set_rooted(duration: float) -> void:
	rooted = true
	root_timer = maxf(root_timer, duration)


func set_slowed(duration: float, multiplier: float) -> void:
	if slow_active:
		return

	slow_active = true

	speed *= multiplier
	wanderspeed *= multiplier
	patrolspeed *= multiplier

	await get_tree().create_timer(duration).timeout

	speed /= multiplier
	wanderspeed /= multiplier
	patrolspeed /= multiplier

	slow_active = false


func on_SeperationArea_entered(body: Node2D) -> void:
	if body != self and body not in nearbyclownfish:
		nearbyclownfish.append(body)


func on_SeperationArea_exited(body: Node2D) -> void:
	nearbyclownfish.erase(body)


func picknewwandertarget():
	var randomoffset: Vector2 = Vector2(
		randf_range(-wanderradius, wanderradius),
		randf_range(-wanderradius, 15.0)
	)

	wandertarget = homeposition + randomoffset
