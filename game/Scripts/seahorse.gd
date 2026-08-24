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
	
	



func _ready() -> void:
	var main = get_tree().current_scene #identifies the main game scene for projectiles
	animated_sprite_2d.play("pregnant")
func _process(_delta): #x axis flipping for now
	if not chase_subject == null and chase_subject.position.x > position.x:
		animated_sprite_2d.flip_h = true
	elif not chase_subject == null and chase_subject.position.x < position.x:
		animated_sprite_2d.flip_h = false
	
	
	if current_health <= 0:
		if TimeStop.time_stop_active == true:
			return
		queue_free()

	if rooted:
		return
		
	if kbtime > 0:
		kbtime 	-= _delta
		velocity = kbvelocity
		move_and_slide()
		return
	
		
func _on_aggro_area_body_entered(body):
	if TimeStop.time_stop_active == true:
		return
	chase_subject = body
	aggro = true
	print('entered')
	
	
	
func _on_aggro_area_body_exited(_body: Node2D) -> void:
	if TimeStop.time_stop_active == true:
		return
	chase_subject = null
	aggro = false
	animated_sprite_2d.play("idle")
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
	if aggro and chase_subject:
		if global_position.distance_to(chase_subject.global_position) > 400:
			velocity = (chase_subject.global_position - global_position).normalized() * speed
		else:
			velocity = (chase_subject.global_position - global_position).normalized() * -1 * speed
	else: 
		velocity = Vector2.ZERO
	move_and_slide()
	

		
	
#damage script below
func take_damage(amount: float):
	current_health -= amount
	animation_player.play("damaged")
	await get_tree().create_timer(0.1).timeout
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
	var kbdirection = (global_position - source_position).normalized()
	kbvelocity = kbdirection * 600
	kbtime = 0.12
#func _on_template_hurtbox_area_entered(area: Area2D) -> void:
	#var kbdirection = (global_position - area.global_position).normalized()
	#kbvelocity = kbdirection * 600
	#kbtime = 0.12
func _shoot():
	if TimeStop.time_stop_active == true:
		return
	if rooted:
		return
	var main = get_tree().current_scene #identifies the main game scene for projectiles, ik its already done on ready but it must be declared again to be used in this function so yeah
	var instance = projectile.instantiate()
	instance.dir = (chase_subject.global_position - global_position).normalized()
	instance.SpawnPos = global_position
	instance.SpawnRot = rotation
	main.call_deferred("add_child", instance)
	#instance.look_at(chase_subject.global_position)

func set_rooted(duration: float) -> void:
	rooted = true
	root_timer = max(root_timer, duration)

func set_slowed(duration: float, multiplier: float) -> void:
	if slow_active:
		return
	slow_active = true
	speed *= multiplier
	await get_tree().create_timer(duration).timeout
	speed /= multiplier
	slow_active = false

	


func _on_shoot_timer_timeout() -> void:
	if aggro and chase_subject:
		_shoot()



	
