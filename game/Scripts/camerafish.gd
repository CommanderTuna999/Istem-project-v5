extends CharacterBody2D

@export var wander_radius: float = 160.0
@export var wander_speed: float = 60.0
@export var attack_cooldown: float = 3.0
@export var spawn_distance: float = 900.0

var max_health: float = 5.0
var current_health: float

var aggro: bool = false
var chase_subject: Node2D = null

var home_position: Vector2 = Vector2.ZERO
var wander_target: Vector2 = Vector2.ZERO
var wander_wait_time: float = 0.0

var attack_timer: float = 1.0

var kbtime: float = 0.0
var kbvelocity: Vector2 = Vector2.ZERO
var rooted: bool = false
var root_timer: float = 0.0
var slow_active: bool = false

var area_symbol_scene = preload("res://Scenes/Enemies/area_symbol.tscn")

@onready var animation: AnimatedSprite2D = $AnimatedSprite2D
@onready var aggro_area: Area2D = $aggro_area


func _ready() -> void:
	current_health = max_health
	animation.play("default")
	home_position = global_position
	pick_new_wander_target()


func _process(_delta: float) -> void:
	if TimeStop.time_stop_active == true:
		return
	if current_health <= 0:
		queue_free()


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

	if attack_timer > 0.0:
		attack_timer -= delta

	if not aggro or chase_subject == null:
		wander(delta)
		move_and_slide()
		return

	velocity = Vector2.ZERO
	move_and_slide()

	if attack_timer <= 0.0:
		perform_attack()


func perform_attack() -> void:
	if chase_subject == null:
		return
	attack_timer = attack_cooldown

	var target_position := chase_subject.global_position
	var random_angle := randf_range(0.0, TAU)
	var spawn_offset := Vector2(cos(random_angle), sin(random_angle)) * spawn_distance
	var spawn_position := target_position + spawn_offset

	var symbol = area_symbol_scene.instantiate()
	symbol.global_position = spawn_position
	symbol.target_position = target_position
	get_tree().current_scene.add_child(symbol)


func wander(delta: float) -> void:
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
	var random_offset := Vector2(randf_range(-wander_radius, wander_radius), randf_range(-wander_radius, wander_radius))
	wander_target = home_position + random_offset


func _on_aggro_area_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	chase_subject = body
	aggro = true


func _on_aggro_area_body_exited(_body: Node2D) -> void:
	chase_subject = null
	aggro = false


func take_damage(amount: float) -> void:
	current_health -= amount


func take_kb(source_position: Vector2) -> void:
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
	wander_speed *= multiplier
	await get_tree().create_timer(duration).timeout
	wander_speed /= multiplier
	slow_active = false
