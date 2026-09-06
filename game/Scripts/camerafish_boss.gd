extends CharacterBody2D

@export var attack_cooldown: float = 2.0
@export var spawn_distance: float = 900.0
@export var teleport_offset: Vector2 = Vector2(0.0, 0.0)
var slowmo_ability_cooldown = 20.0
var slowmo_timer = 20.0
var slowmo_duration = 1.85

var max_health: float = 25.0
var current_health: float
var attack_count: int = 0
var special_attack_cooldown = 2.0

var has_teleported: bool = false
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

var area_symbol_scene = preload("res://Scenes/Enemies/area_symbol_boss.tscn")
var in_frame_scene = preload("res://Scenes/Enemies/in_frame.tscn")

@onready var animation: AnimatedSprite2D = $AnimatedSprite2D
@onready var aggro_area: Area2D = $aggro_area

func _ready() -> void:
	current_health = max_health
	animation.play("default")
	home_position = global_position

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
	if slowmo_timer > 0.0:
		slowmo_timer -= delta

	if attack_timer > 0.0:
		attack_timer -= delta

	if not aggro or chase_subject == null:
		wander(delta)
		move_and_slide()
		return

	velocity = Vector2.ZERO
	move_and_slide()

	if attack_timer <= 0.0:
		if attack_count >= 4:
			perform_special_attack()
		else:
			perform_attack()
	if slowmo_timer <= 0.0:
		perform_slomo()
		

func perform_slomo() -> void:
	slowmo_timer = slowmo_ability_cooldown
	slowmo_timer -= 0.025
	if chase_subject.has_method("slowmo_func"):
		chase_subject.slowmo_func(slowmo_duration)
	slowmo_duration += 0.025

func perform_attack() -> void:
	attack_count += 1
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
	
func perform_special_attack() -> void:
	attack_timer = special_attack_cooldown
	attack_count -= 4

	var target_position := chase_subject.global_position

	var normal_angle := randf_range(0.0, TAU)
	var normal_offset := Vector2(cos(normal_angle), sin(normal_angle)) * spawn_distance
	var normal_spawn := target_position + normal_offset

	var main_symbol = area_symbol_scene.instantiate()
	main_symbol.global_position = normal_spawn
	main_symbol.target_position = target_position
	get_tree().current_scene.add_child(main_symbol)

	for i in range(3):
		await get_tree().create_timer(0.5).timeout
		var offset_vector := Vector2(randf_range(-200.0, 200.0), randf_range(-200.0, 200.0))
		var offset_target := target_position + offset_vector

		var random_angle := randf_range(0.0, TAU)
		var spawn_offset := Vector2(cos(random_angle), sin(random_angle)) * spawn_distance
		var spawn_position := offset_target + spawn_offset

		var offset_symbol = area_symbol_scene.instantiate()
		offset_symbol.global_position = spawn_position
		offset_symbol.target_position = offset_target
		get_tree().current_scene.add_child(offset_symbol)
	

func wander(delta: float) -> void:
	if wander_wait_time > 0.0:
		wander_wait_time -= delta
		velocity = Vector2.ZERO
		return

	if global_position.distance_to(wander_target) < 10.0:
		wander_wait_time = randf_range(0.6, 1.8)
		return

	if velocity.x > 0:
		animation.flip_h = true
	elif velocity.x < 0:
		animation.flip_h = false

func _on_aggro_area_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	
	chase_subject = body
	aggro = true
	chase_subject.boss_targeted = true
	
	if not has_teleported:
		has_teleported = true
		callable_teleport.call_deferred(body)

func callable_teleport(target_player: Node2D) -> void:
	if is_instance_valid(target_player):
		global_position = target_player.global_position + teleport_offset
		if in_frame_scene != null:
			var frame_instance = in_frame_scene.instantiate()
			frame_instance.global_position = target_player.global_position
			get_tree().current_scene.add_child(frame_instance)

func _on_aggro_area_body_exited(_body: Node2D) -> void:
	chase_subject = null
	aggro = false

func take_damage(amount: float) -> void:
	current_health -= amount
	
	var target_position := chase_subject.global_position
	var random_angle := randf_range(0.0, TAU)
	var spawn_offset := Vector2(cos(random_angle), sin(random_angle)) * spawn_distance
	var spawn_position := target_position + spawn_offset

	var symbol = area_symbol_scene.instantiate()
	symbol.global_position = spawn_position
	symbol.target_position = target_position
	get_tree().current_scene.add_child(symbol)

func set_rooted(duration: float) -> void:
	rooted = true
	root_timer = max(root_timer, duration)

func set_slowed(duration: float, multiplier: float) -> void:
	if slow_active:
		return
	slow_active = true
	await get_tree().create_timer(duration).timeout
	slow_active = false
