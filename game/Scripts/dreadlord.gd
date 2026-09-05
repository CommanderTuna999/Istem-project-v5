extends CharacterBody2D

@export var max_health = 10.0
@export var contact_damage = 10
@export var speed_base = 135.0
@export var aggro_radius = 350.0

@export var contact_silence_duration = 1.0
@export var contact_silence_gap = 2.0
@export var contact_silence_damage = 1.0
var silence_sequence_active = false

@export var outer_zone_start_ratio = 0.6
@export var inner_zone_ratio = 0.6

@export var bomb_burst_interval = 2.25
@export var bomb_sub_interval = 0.5
@export var bomb_damage = 10.0
@export var bomb_explosion_radius = 120.0
@export var bomb_silence_duration = 0.5
@export var bomb_knockback_strength = 40.0
var bomb_burst_timer = 0.0
var in_outer_zone = false

@onready var bomb_scene = preload("res://Scenes/Enemies/dreadlord_bomb.tscn")

@export var inner_zone_dreadlord_speed_bonus = 0.15
@export var inner_zone_player_speed_penalty = 0.4
var player_inner_slow_active = false

@export var execution_stack_interval = 1.5
@export var execution_stacks_needed = 10
var execution_stacks = 0
var execution_stack_timer = 0.0
var execution_triggered = false

signal execution_stacks_changed(current: int, max_stacks: int)

@onready var moon_scene = preload("res://Scenes/Enemies/moon.tscn")
@export var moon_shatter_damage = 20 * 5

var current_health
var speed
var chase_subject = null

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var aggro_area: Area2D = $aggro_area


func _ready() -> void:
	current_health = max_health
	speed = speed_base
	animated_sprite_2d.play("default")

	var aggro_shape := $aggro_area/CollisionShape2D.shape as CircleShape2D
	if aggro_shape != null:
		aggro_shape.radius = aggro_radius


func _physics_process(delta: float) -> void:
	if is_instance_valid(chase_subject):
		update_zone_logic(delta)
		var direction_to_player = (chase_subject.global_position - global_position).normalized()
		velocity = direction_to_player * speed
	else:
		velocity = Vector2.ZERO
		reset_zone_state()

	move_and_slide()


func update_zone_logic(delta: float) -> void:
	if execution_triggered:
		return

	var dist = global_position.distance_to(chase_subject.global_position)
	var ratio = dist / aggro_radius

	var should_be_outer = ratio >= outer_zone_start_ratio and ratio <= 1.0
	var should_be_inner = ratio <= inner_zone_ratio

	if should_be_outer and not in_outer_zone:
		in_outer_zone = true
		bomb_burst_timer = bomb_burst_interval
	elif not should_be_outer and in_outer_zone:
		in_outer_zone = false

	if in_outer_zone:
		bomb_burst_timer -= delta
		if bomb_burst_timer <= 0.0:
			fire_bomb_burst()
			bomb_burst_timer = bomb_burst_interval

	if should_be_inner and not player_inner_slow_active:
		player_inner_slow_active = true
		if chase_subject.has_method("apply_dreadlord_slow"):
			chase_subject.apply_slow(9999.0, inner_zone_player_speed_penalty)
		speed = speed_base * (1.0 + inner_zone_dreadlord_speed_bonus)
	elif not should_be_inner and player_inner_slow_active:
		player_inner_slow_active = false
		speed = speed_base

	if should_be_inner:
		execution_stack_timer -= delta
		if execution_stack_timer <= 0.0:
			execution_stack_timer = execution_stack_interval
			gain_execution_stack()
	else:
		execution_stack_timer = 0.0


func reset_zone_state() -> void:
	in_outer_zone = false
	if player_inner_slow_active:
		player_inner_slow_active = false
		speed = speed_base
	execution_stack_timer = 0.0


func fire_bomb_burst() -> void:
	for i in range(2):
		spawn_bomb()
		await get_tree().create_timer(bomb_sub_interval).timeout


func spawn_bomb() -> void:
	if not is_instance_valid(chase_subject):
		return
	var bomb = bomb_scene.instantiate()
	bomb.global_position = global_position
	bomb.direction = (chase_subject.global_position - global_position).normalized()
	bomb.damage = bomb_damage
	bomb.explosion_radius = bomb_explosion_radius
	bomb.silence_duration = bomb_silence_duration
	bomb.knockback_strength = bomb_knockback_strength
	get_tree().current_scene.call_deferred("add_child", bomb)


func gain_execution_stack() -> void:
	if execution_triggered:
		return
	execution_stacks += 1
	execution_stacks_changed.emit(execution_stacks, execution_stacks_needed)
	if execution_stacks >= execution_stacks_needed:
		trigger_execution_event()


func trigger_execution_event() -> void:
	if execution_triggered:
		return
	execution_triggered = true

	if chase_subject.starsaveused:
		run_moon_shatter_sequence()
	else:
		#run_quiz_sequence()
		run_moon_shatter_sequence()


func run_moon_shatter_sequence() -> void:
	if chase_subject.has_method("silence"):
		chase_subject.is_silenced = true

	if chase_subject.has_method("set_rooted"):
		chase_subject.set_rooted(6.0)

	for enemy in get_tree().get_nodes_in_group("enemy"):
		if enemy != self and enemy.has_method("set_rooted"):
			enemy.set_rooted(6.0)

	var moon_position = chase_subject.global_position
	var moon = moon_scene.instantiate()
	moon.global_position = moon_position
	get_tree().current_scene.call_deferred("add_child", moon)

	await get_tree().create_timer(1.0).timeout

	global_position = moon_position + Vector2(-150, -150)

	var tween = create_tween()
	tween.tween_property(self, "global_position", moon_position + Vector2(150, 150), 0.8)
	tween.tween_callback(func():
		if moon.has_method("shatter"):
			moon.shatter()
		chase_subject.take_player_damage(moon_shatter_damage)
	)

	await get_tree().create_timer(1.0).timeout

	chase_subject.stunned = false

	if is_instance_valid(chase_subject) and chase_subject.current_health > 0:
		trigger_silence_sequence(chase_subject)


func run_quiz_sequence() -> void:
	TimeStop.time_stop_active = true
	var quiz_ui = preload("res://Scenes/Enemies/execution_quiz.tscn").instantiate()
	get_tree().current_scene.add_child(quiz_ui)
	quiz_ui.finished.connect(_on_quiz_finished)


func _on_quiz_finished(passed: bool) -> void:
	TimeStop.time_stop_active = false
	execution_stacks = 0
	execution_triggered = false

	if passed:
		current_health = current_health * 0.5
	else:
		if chase_subject.has_method("take_player_damage"):
			chase_subject.take_player_damage(999999)


func _on_aggro_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		chase_subject = body


func _on_aggro_area_body_exited(body: Node2D) -> void:
	if chase_subject == body:
		chase_subject = null


func _on_hurtbox_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		if body.has_method("take_player_damage"):
			body.take_player_damage(contact_damage)
		trigger_silence_sequence(body)


func trigger_silence_sequence(target: Node) -> void:
	if silence_sequence_active:
		return
	silence_sequence_active = true

	await apply_one_silence(target)
	await get_tree().create_timer(contact_silence_gap).timeout
	await apply_one_silence(target)

	silence_sequence_active = false


func apply_one_silence(target: Node) -> void:
	if not is_instance_valid(target):
		return
	target.is_silenced = true
	if target.has_method("take_player_damage"):
		target.take_player_damage(contact_silence_damage)
	await get_tree().create_timer(contact_silence_duration).timeout
	target.is_silenced = false
