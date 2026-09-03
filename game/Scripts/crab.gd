#everyone will look at this script eventually so important info:
#Layer 1 = Player
#Layer 2 = Walls
#Layer 3 = HarpoonProjectile
#Layer 11 = Enemies hurtbox

extends CharacterBody2D

var speed = 70
var damage_occuring = false
var aggro = false
var chase_subject = null

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer

var current_health = 5

var kbtime = 0.0
var kbvelocity = Vector2.ZERO

var rooted: bool = false
var root_timer: float = 0.0

var slow_active: bool = false

#jump stuff
var crabgravity = 350.0
var jumpspeed = 330.0
var jumpforwardspeed = 300.0

var jumpcooldown = 0.0
var jumpcooldowntime = 0.8

var jumping = false


func _ready() -> void:
	animated_sprite_2d.play("idle")


func _process(_delta): #x axis flipping for now

	if not chase_subject == null and chase_subject.position.x > position.x:
		animated_sprite_2d.flip_h = true

	elif not chase_subject == null and chase_subject.position.x < position.x:
		animated_sprite_2d.flip_h = false


	if current_health <= 0:
		queue_free()


	if rooted:
		return


	if kbtime > 0:
		kbtime -= _delta
		velocity = kbvelocity
		move_and_slide()
		return


func _on_aggro_area_body_entered(body):
	chase_subject = body
	aggro = true
	animated_sprite_2d.play("aggro")
	print("entered")


func _on_aggro_area_body_exited(_body: Node2D) -> void:
	chase_subject = null
	aggro = false
	animated_sprite_2d.play("idle")
	print("exited")


func _physics_process(_delta):

	if rooted:
		root_timer -= _delta
		velocity = Vector2.ZERO
		move_and_slide()

		if root_timer <= 0.0:
			rooted = false

		return


	if jumpcooldown > 0.0:
		jumpcooldown -= _delta


	#underwater gravity
	if not is_on_floor():
		velocity.y += crabgravity * _delta


	#when it lands after jumping
	if is_on_floor() and jumping:
		jumping = false
		velocity.x = 0
		jumpcooldown = jumpcooldowntime


	#if player is nearby and crab is ready, jump at them
	if aggro and is_instance_valid(chase_subject):

		if is_on_floor() and not jumping and jumpcooldown <= 0.0:

			var directiontoplayer = (
				chase_subject.global_position - global_position
			)

			var horizontaldirection = sign(directiontoplayer.x)

			velocity.x = horizontaldirection * jumpforwardspeed
			velocity.y = -jumpspeed

			jumping = true


	#stay still while grounded
	elif is_on_floor() and not jumping:
		velocity.x = 0


	move_and_slide()


#damage script below
func take_damage(amount: float):
	current_health -= amount
	animation_player.play("damaged")
	await get_tree().create_timer(0.1).timeout


# knockback script below
func take_kb(source_position: Vector2):
	var kbdirection = (global_position - source_position).normalized()
	kbvelocity = kbdirection * 200
	kbtime = 0.12


func set_rooted(duration: float) -> void:
	rooted = true
	root_timer = max(root_timer, duration)


func set_slowed(duration: float, multiplier: float) -> void:
	if slow_active:
		return

	slow_active = true

	jumpforwardspeed *= multiplier
	jumpspeed *= multiplier

	await get_tree().create_timer(duration).timeout

	jumpforwardspeed /= multiplier
	jumpspeed /= multiplier

	slow_active = false


	
