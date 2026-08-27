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

var rooted: bool = false
var root_timer: float = 0.0

var slow_active: bool = false

var nearbyclownfish: Array[Node2D] = []
var separationdirection = Vector2.ZERO
var separationstrength = 80.0

@export var homemarker: Marker2D
var homeposition = Vector2.ZERO

# Where the fish currently chooses normal wander targets around.
# At first this is its spawn position.
# After it encounters the player, this changes to its actual home.
var wandercenter = Vector2.ZERO

@export var defendradius: float = 50.0
@export var wanderradius: float = 70.0
@export var wanderspeed: float = 60.0

var wandertarget = Vector2.ZERO
var wanderwaittimer = 0.0


# Teammate currency / scroll system
var scroll_drop_increase = 0.0
var scrolls_drop_amount_increase = 0.0

var scrolls_drop_amount:
	get:
		return 1.0 + scrolls_drop_amount_increase

var scroll_drop_chance:
	get:
		return 0.5 + scroll_drop_increase


func scroll_drop():
	var roll: float = randf()

	if roll <= scroll_drop_chance:
		CurrencySystem.scrolls += scrolls_drop_amount


func _ready() -> void:
	animated_sprite_2d.play("idle")

	if homemarker:
		homeposition = homemarker.global_position

		# IMPORTANT:
		# The fish starts by wandering around wherever you placed it,
		# NOT around its anemone yet.
		wandercenter = global_position

		picknewwandertarget()


func _process(_delta):
	if TimeStop.time_stop_active:
		return

	# Face the direction the fish is actually travelling.
	if velocity.x > 5.0:
		animated_sprite_2d.flip_h = true
	elif velocity.x < -5.0:
		animated_sprite_2d.flip_h = false

	if current_health <= 0:
		var clownfish_coins_drop: float = randi_range(45, 55)

		CurrencySystem.TotalCoins += clownfish_coins_drop
		scroll_drop()

		queue_free()


func _on_aggro_area_body_entered(body):
	if TimeStop.time_stop_active:
		return

	chase_subject = body
	aggro = true
	animated_sprite_2d.play("aggro")

	# Once the fish has been disturbed,
	# its future wandering area becomes its actual home.
	wandercenter = homeposition

	print("entered")


func _on_aggro_area_body_exited(body: Node2D) -> void:
	if TimeStop.time_stop_active:
		return

	if body == chase_subject:
		chase_subject = null
		aggro = false
		animated_sprite_2d.play("idle")

		# Pick a new wander target around the anemone/home.
		picknewwandertarget()

	print("exited")


func _physics_process(delta):
	if TimeStop.time_stop_active:
		return

	if rooted:
		root_timer -= delta
		velocity = Vector2.ZERO
		move_and_slide()

		if root_timer <= 0.0:
			rooted = false

		return


	if kbtime > 0:
		kbtime -= delta
		velocity = kbvelocity

	else:
		if aggro and is_instance_valid(chase_subject):

			var distance_to_home = global_position.distance_to(homeposition)

			# If threatened while away from home:
			# RUN HOME.
			if distance_to_home > defendradius:
				velocity = (
					homeposition - global_position
				).normalized() * speed

			# Once near the anemone:
			# DEFEND IT.
			else:
				velocity = (
					chase_subject.global_position - global_position
				).normalized() * speed


			# Existing separation behaviour.
			separationdirection = Vector2.ZERO

			for fish in nearbyclownfish:
				if is_instance_valid(fish):
					separationdirection += (
						global_position - fish.global_position
					).normalized()

			if separationdirection != Vector2.ZERO:
				separationdirection = separationdirection.normalized()
				velocity += separationdirection * separationstrength


		else:
			# Normal wandering around wandercenter.
			if wanderwaittimer > 0.0:
				wanderwaittimer -= delta
				velocity = Vector2.ZERO

			else:
				var directiontowander = wandertarget - global_position

				if directiontowander.length() > 10:
					velocity = directiontowander.normalized() * wanderspeed

				else:
					wanderwaittimer = randf_range(0.5, 2.0)
					picknewwandertarget()


	move_and_slide()


# Damage
func take_damage(amount: float):
	current_health -= amount

	animation_player.play("damaged")
	damage_number_template.spawn_label(amount, false)

	await get_tree().create_timer(0.1).timeout


# Knockback
func take_kb(source_position: Vector2):
	var kbdirection = (
		global_position - source_position
	).normalized()

	kbvelocity = kbdirection * 600
	kbtime = 0.12


func set_rooted(duration: float) -> void:
	rooted = true
	root_timer = max(root_timer, duration)


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


func on_SeperationArea_entered(body: Node2D) -> void:
	if body != self and body not in nearbyclownfish:
		nearbyclownfish.append(body)


func on_SeperationArea_exited(body: Node2D) -> void:
	nearbyclownfish.erase(body)


func picknewwandertarget():
	var randomoffset = Vector2(
		randf_range(-wanderradius, wanderradius),
		randf_range(-wanderradius, 15.0)
	)

	wandertarget = wandercenter + randomoffset

	print("new wander target: ", wandertarget)
