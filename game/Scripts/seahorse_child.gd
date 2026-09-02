#everyone will look at this script eventually so important info:
#Layer 1 = Player
#Layer 2 = Walls
#Layer 3 = HarpoonProjectile
#Layer 11 = Enemies hurtbox

extends CharacterBody2D

@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer

var speed = 150
var aggro = false
var chase_subject = null

var current_health = 1

var kbtime = 0.0
var kbvelocity = Vector2.ZERO

var rooted: bool = false
var root_timer: float = 0.0

var slow_active: bool = false

#separation stuff
var nearbyfish: Array[Node2D] = []
var separationdirection = Vector2.ZERO
var separationstrength = 80.0

#wander stuff
var homeposition = Vector2.ZERO
var wandertarget = Vector2.ZERO
var wanderwaittimer = 0.0
var wanderradius = 50.0
var wanderspeed = 40.0


func _ready() -> void:
	collision_shape_2d.set_deferred("disabled", true)
	animated_sprite_2d.play("idle")

	#wherever the fish spawns becomes where it wanders around
	homeposition = global_position
	picknewwandertarget()

	await get_tree().create_timer(1).timeout
	collision_shape_2d.set_deferred("disabled", false)


func _process(_delta):

	#x axis flipping
	if not chase_subject == null and chase_subject.position.x > position.x:
		animated_sprite_2d.flip_h = true

	elif not chase_subject == null and chase_subject.position.x < position.x:
		animated_sprite_2d.flip_h = false


	if current_health <= 0:
		queue_free()


func _physics_process(_delta):
	print("nearby fish: ", nearbyfish.size())
	#root code
	if rooted:
		root_timer -= _delta
		velocity = Vector2.ZERO
		move_and_slide()

		if root_timer <= 0.0:
			rooted = false

		return


	#knockback code
	if kbtime > 0:
		kbtime -= _delta
		velocity = kbvelocity
		move_and_slide()
		return


	#chase player
	if aggro and chase_subject:

		velocity = (
			chase_subject.global_position - global_position
		).normalized() * speed


		#separate from nearby fish so they dont all become one blob
		separationdirection = Vector2.ZERO

		for fish in nearbyfish:
			if is_instance_valid(fish):

				var distancetofish = global_position.distance_to(
					fish.global_position
				)

				if distancetofish > 0:
					separationdirection += (
						global_position - fish.global_position
					).normalized()


		if separationdirection != Vector2.ZERO:
			separationdirection = separationdirection.normalized()

			velocity += (
				separationdirection
				* separationstrength
			)


	#wandering when player isnt nearby
	else:

		if wanderwaittimer > 0.0:
			wanderwaittimer -= _delta
			velocity = Vector2.ZERO

		else:

			var directiontowander = (
				wandertarget - global_position
			)


			if directiontowander.length() > 8:

				velocity = (
					directiontowander.normalized()
					* wanderspeed
				)


				if velocity.x > 0:
					animated_sprite_2d.flip_h = true

				elif velocity.x < 0:
					animated_sprite_2d.flip_h = false


			else:
				wanderwaittimer = randf_range(0.3, 1.0)
				picknewwandertarget()


	move_and_slide()


#aggro stuff
func _on_aggro_area_body_entered(body):
	chase_subject = body
	aggro = true


func _on_aggro_area_body_exited(body: Node2D) -> void:

	if chase_subject == body:
		chase_subject = null
		aggro = false

	animated_sprite_2d.play("idle")


#damage script below
func take_damage(amount: float):

	current_health -= amount

	animation_player.play("damaged")


# knockback script below
func take_kb(source_position: Vector2):

	var kbdirection = (
		global_position - source_position
	).normalized()

	kbvelocity = kbdirection * 600
	kbtime = 0.12


#root code
func set_rooted(duration: float) -> void:

	rooted = true
	root_timer = max(root_timer, duration)


#slow code
func set_slowed(duration: float, multiplier: float) -> void:

	if slow_active:
		return

	slow_active = true

	speed *= multiplier
	wanderspeed *= multiplier

	await get_tree().create_timer(duration).timeout

	speed /= multiplier
	wanderspeed /= multiplier

	slow_active = false


#separation code
func _on_seperation_area_body_entered(body: Node2D) -> void:

	if body != self and body not in nearbyfish:
		nearbyfish.append(body)


func _on_separation_area_body_exited(body: Node2D) -> void:

	nearbyfish.erase(body)


#wander code
func picknewwandertarget():

	var randomoffset = Vector2(
		randf_range(-wanderradius, wanderradius),
		randf_range(-wanderradius, wanderradius)
	)

	wandertarget = homeposition + randomoffset
