extends CharacterBody2D

var speed = 235
var injured_speed = 150

var aggro = false
var chase_subject = null

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer

var current_health = 10

var kbtime = 0.0
var kbvelocity = Vector2.ZERO

var rooted: bool = false
var root_timer: float = 0.0

var slow_active: bool = false


func _on_aggro_area_body_entered(body):
	chase_subject = body
	aggro = true
	print("entered")


#func _on_aggro_area_body_exited(body: Node2D) -> void:
	#if body == chase_subject:
		#chase_subject = null
		#aggro = false

	#print("exited")


func _physics_process(delta):
	if rooted:
		root_timer -= delta
		velocity = Vector2.ZERO

		if root_timer <= 0.0:
			rooted = false

		move_and_slide()
		return

	if kbtime > 0:
		kbtime -= delta
		velocity = kbvelocity

	elif aggro and is_instance_valid(chase_subject):
		velocity = (
			chase_subject.global_position - global_position
		).normalized() * speed

	else:
		velocity = Vector2.ZERO

	update_facing()
	move_and_slide()


func update_facing() -> void:
	if velocity.length() < 1.0:
		return

	var move_angle := velocity.angle()

	if abs(move_angle) > PI / 2.0:
		animated_sprite_2d.rotation = move_angle + PI
		animated_sprite_2d.flip_h = true
	else:
		animated_sprite_2d.rotation = move_angle
		animated_sprite_2d.flip_h = false


# Damage still works so attacks/parries can interact with the shark.
# The shark simply does not die when health reaches 0.
func take_damage(amount: float):
	current_health -= amount
	animation_player.play("damaged")


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
	injured_speed *= multiplier

	await get_tree().create_timer(duration).timeout

	if not is_inside_tree():
		return

	speed /= multiplier
	injured_speed /= multiplier
	slow_active = false
