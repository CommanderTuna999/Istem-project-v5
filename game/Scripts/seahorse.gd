#everyone will look at this script eventually so important info:
#Layer 1 = Player
#Layer 2 = Walls
#Layer 3 = HarpoonProjectile
#Layer 11 = Enemies hurtbox

extends CharacterBody2D

@onready var projectile = preload("res://Scenes/Enemies/seahorse_projectile.tscn")
@onready var child = preload("res://Scenes/Enemies/seahorse_child.tscn")

var speed = 300
var damage_occuring = false
var aggro = false
var chase_subject = null

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer

var current_health = 6

var kbtime = 0.0
var kbvelocity = Vector2.ZERO

var projectile_cooldown = 2

var rooted: bool = false
var root_timer: float = 0.0

var slow_active: bool = false

var spawn: float = 1.0

var scroll_drop_increase = 0.0
var scrolls_drop_amount_increase = 0.0

var scrolls_drop_amount:
	get:
		return 1.0 + scrolls_drop_amount_increase

var scroll_drop_chance:
	get:
		return (0.5 + scroll_drop_increase)


#retreat stuff
var retreating = false
var retreattimer = 0.0
var retreatcooldown = 0.0

var retreatspeed = 300
var retreatduration = 0.15
var retreatcooldowntime = 0.45

#player this close = retreat
var retreatdistance = 160

#if player is coming in VERY fast,
#the seahorse can panic slightly earlier
var fastapproachdistance = 260
var fastapproachspeed = 800


func _ready() -> void:
	var main = get_tree().current_scene #identifies the main game scene for projectiles

	animated_sprite_2d.play("pregnant")

	animation_player.play("floatidle")


func scroll_drop():
	var roll: float = randf()

	#if roll <= scroll_drop_chance:
	#	CurrencySystem.scrolls += scrolls_drop_amount


func _process(_delta): #x axis flipping for now

	if not chase_subject == null and chase_subject.position.x > position.x:
		animated_sprite_2d.flip_h = true

	elif not chase_subject == null and chase_subject.position.x < position.x:
		animated_sprite_2d.flip_h = false


	if current_health <= 0:

		if TimeStop.time_stop_active == true:
			return

		var seahorse_coins_drop = randi_range(80, 120)

		#CurrencySystem.TotalCoins += seahorse_coins_drop

		scroll_drop()

		queue_free()


	if rooted:
		return


	if kbtime > 0:
		kbtime -= _delta
		velocity = kbvelocity
		move_and_slide()
		return


func _on_aggro_area_body_entered(body):

	if TimeStop.time_stop_active == true:
		return

	chase_subject = body
	aggro = true

	print("entered")


func _on_aggro_area_body_exited(body: Node2D) -> void:

	if TimeStop.time_stop_active == true:
		return

	if chase_subject == body:
		chase_subject = null
		aggro = false

	print("exited")


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


	#retreat cooldown
	if retreatcooldown > 0.0:
		retreatcooldown -= _delta


	#currently doing the retreat burst
	if retreating:

		retreattimer -= _delta

		if retreattimer <= 0.0:
			retreating = false


	#player is inside the seahorses normal shooting / aggro area
	elif aggro and is_instance_valid(chase_subject):

		var distancetoplayer = global_position.distance_to(
			chase_subject.global_position
		)


		var shouldretreat = false


		#player simply got too close
		if distancetoplayer < retreatdistance:
			shouldretreat = true


		#player is still a little further away,
		#but is flying directly towards the seahorse
		elif distancetoplayer < fastapproachdistance:		

			if chase_subject is CharacterBody2D:

				var directiontoseahorse = (
					global_position
					- chase_subject.global_position
				).normalized()


				var approachspeed = (
					chase_subject.velocity.dot(
						directiontoseahorse
					)
				)


				if approachspeed > fastapproachspeed:
					shouldretreat = true


		#begin one retreat burst
		if shouldretreat and retreatcooldown <= 0.0:

			var awayfromplayer = (
				global_position
				- chase_subject.global_position
			).normalized()


			#slight sideways variation stops every retreat
			#from being perfectly straight
			var sideways = Vector2(
				-awayfromplayer.y,
				awayfromplayer.x
			)

			sideways *= randf_range(-0.35, 0.35)


			var retreatdirection = (
				awayfromplayer + sideways
			).normalized()


			velocity = retreatdirection * retreatspeed

			retreating = true
			retreattimer = retreatduration
			retreatcooldown = retreatcooldowntime


		else:

			#normally it just floats and shoots
			#rather than chasing or constantly backing away
			velocity = velocity.move_toward(
				Vector2.ZERO,
				500.0 * _delta
			)


	else:

		velocity = velocity.move_toward(
			Vector2.ZERO,
			500.0 * _delta
		)


	move_and_slide()



#damage script below
func take_damage(amount: float):

	current_health -= amount

	animation_player.play("damaged")

	await get_tree().create_timer(0.1).timeout

	animation_player.play("floatidle")


	if current_health <= 3 and spawn >= 1:

		animated_sprite_2d.play("deflated")

		spawn_child(25)

		spawn = 0


func spawn_child(amount):

	for i in range(amount):

		var main = get_tree().current_scene #identifies the main game scene for projectiles, ik its already done on ready but it must be declared again to be used in this function so yeah

		var instance = child.instantiate()

		main.call_deferred("add_child", instance)

		instance.position.x = global_position.x + randf_range(1, 15)
		instance.position.y = global_position.y + randf_range(1, 15)

		await get_tree().create_timer(0.1).timeout


# knockback script below
func take_kb(source_position: Vector2):

	var kbdirection = (
		global_position - source_position
	).normalized()

	kbvelocity = kbdirection * 300
	kbtime = 0.12


func _shoot():

	if TimeStop.time_stop_active == true:
		return

	if rooted:
		return

	if not is_instance_valid(chase_subject):
		return


	var main = get_tree().current_scene #identifies the main game scene for projectiles, ik its already done on ready but it must be declared again to be used in this function so yeah

	var instance = projectile.instantiate()

	instance.dir = (
		chase_subject.global_position
		- global_position
	).normalized()

	instance.SpawnPos = global_position
	instance.SpawnRot = rotation

	instance.scale = Vector2(0.5, 0.5)

	main.call_deferred("add_child", instance)


func set_rooted(duration: float) -> void:

	rooted = true
	root_timer = max(root_timer, duration)


func set_slowed(duration: float, multiplier: float) -> void:

	if slow_active:
		return

	slow_active = true

	retreatspeed *= multiplier

	await get_tree().create_timer(duration).timeout

	retreatspeed /= multiplier

	slow_active = false


func _on_shoot_timer_timeout() -> void:

	if aggro and is_instance_valid(chase_subject):
		_shoot()
