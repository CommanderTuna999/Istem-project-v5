extends CharacterBody2D

@export var speed: float = 185.5
@export var range_radius: float = 250.0

@export var shot_ammo: int = 4

@export var shot_cooldown: float = 0.5

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


func _physics_process(delta: float) -> void:
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
		velocity = Vector2.ZERO
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


func _on_aggro_area_body_entered(body: Node2D) -> void:
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
	var kbdirection = (global_position - source_position).normalized()
	kbvelocity = kbdirection * 950
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
