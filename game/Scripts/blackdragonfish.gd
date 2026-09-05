extends CharacterBody2D

@export var speed: float = 185.0
@export var range_radius: float = 250.0

@export var shot_ammo: int = 4

@export var shot_cooldown: float = 1.0

@export var wander_radius: float = 160.0
@export var wander_speed: float = 85.0

var max_health: float = 6.0
var current_health: float

var aggro: bool = false
var chase_subject: Node2D = null

var in_range: bool = false
var shots_fired: int = 0
var out_of_ammo: bool = false

var kbtime: float = 0.0
var kbvelocity: Vector2 = Vector2.ZERO
var rooted: bool = false
var root_timer: float = 0.0
var slow_active: bool = false

var home_position: Vector2 = Vector2.ZERO
var wander_target: Vector2 = Vector2.ZERO
var wander_wait_time: float = 0.0

var ice_projectile = preload("res://Scenes/Enemies/blackdragonfish_ice_projectile.tscn")
var fire_projectile = preload("res://Scenes/Enemies/blackdragonfish_fire_projectile.tscn")

@onready var animation: AnimatedSprite2D = $bdraganim
@onready var range_area: Area2D = $range_area
@onready var shoot_timer: Timer = $ShootTimer


func _ready() -> void:
	current_health = max_health
	animation.play("default")

	shoot_timer.wait_time = shot_cooldown
	shoot_timer.one_shot = false
	shoot_timer.autostart = false
	shoot_timer.stop()

	var range_shape := $range_area/CollisionShape2D.shape as CircleShape2D
	if range_shape:
		range_shape.radius = range_radius

	home_position = global_position
	pick_new_wander_target()


func _physics_process(delta: float) -> void:
	if TimeStop.time_stop_active == true:
		return
	if rooted:
		root_timer -= delta
		velocity = Vector2.ZERO
		move_and_slide()
		if root_timer <= 0.0:
			rooted = false
		return

	if kbtime > 0.0:
		kbtime -= delta
		velocity = kbvelocity
		move_and_slide()
		return

	if current_health <= 0:
		queue_free()
		return

	if not aggro or chase_subject == null:
		wander(delta)
		move_and_slide()
		return

	if chase_subject.global_position.x > global_position.x:
		animation.flip_h = true
	elif chase_subject.global_position.x < global_position.x:
		animation.flip_h = false

	if in_range and not out_of_ammo:
		velocity = Vector2.ZERO
	else:
		velocity = (chase_subject.global_position - global_position).normalized() * speed

	move_and_slide()


func wander(delta: float) -> void:
	if TimeStop.time_stop_active == true:
		return
	if wander_wait_time > 0.0:
		wander_wait_time -= delta
		velocity = Vector2.ZERO
		return

	if global_position.distance_to(wander_target) < 10.0:
		wander_wait_time = randf_range(0.6, 1.8)
		pick_new_wander_target()
		return

	velocity = (wander_target - global_position).normalized() * wander_speed
	if velocity.x > 0:
		animation.flip_h = true
	elif velocity.x < 0:
		animation.flip_h = false


func pick_new_wander_target() -> void:
	if TimeStop.time_stop_active == true:
		return
	var random_offset := Vector2(randf_range(-wander_radius, wander_radius), randf_range(-wander_radius, wander_radius))
	wander_target = home_position + random_offset


func _on_aggro_area_body_entered(body: Node2D) -> void:
	if TimeStop.time_stop_active == true:
		return
	if not body.is_in_group("player"):
		return
	chase_subject = body
	aggro = true


func _on_aggro_area_body_exited(_body: Node2D) -> void:
	chase_subject = null
	aggro = false
	in_range = false
	shoot_timer.stop()


func _on_range_area_body_entered(body: Node2D) -> void:
	if TimeStop.time_stop_active == true:
		return
	if not body.is_in_group("player"):
		return
	if out_of_ammo:
		return
	in_range = true
	shoot_timer.start()



func _on_range_area_body_exited(_body: Node2D) -> void:
	in_range = false
	shoot_timer.stop()



func _on_shoot_timer_timeout() -> void:
	if not in_range or out_of_ammo or chase_subject == null:
		return
	_shoot()
	shots_fired += 1
	if shots_fired >= shot_ammo:
		out_of_ammo = true
		in_range = false
		shoot_timer.stop()


func _shoot() -> void:
	if TimeStop.time_stop_active == true:
		return
	var is_ice_shot: bool = shots_fired % 2 == 0

	var scene = ice_projectile if is_ice_shot else fire_projectile
	var main = get_tree().current_scene
	var instance = scene.instantiate()
	instance.global_position = global_position
	instance.dir = (chase_subject.global_position - global_position).normalized()
	main.call_deferred("add_child", instance)


func take_damage(amount: float) -> void:
	current_health -= amount


func take_kb(source_position: Vector2) -> void:
	if TimeStop.time_stop_active == true:
		return
	var kbdirection = (global_position - source_position).normalized()
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
	await get_tree().create_timer(duration).timeout
	speed /= multiplier
	slow_active = false
