extends CharacterBody2D

@export var max_health = 10.0
@export var contact_damage = 10
@export var speed_base = 135.0
@export var aggro_radius = 350.0

@onready var TimeStopDreadlord: ColorRect = $TimeStopFilter/ColorRect
var time_stop_active = false

@export var contact_silence_duration = 1.0
@export var contact_silence_gap = 2.0
@export var contact_silence_damage = 1.0
var silence_sequence_active = false

@export var outer_zone_start_ratio = 0.6
@export var inner_zone_ratio = 0.6

@export var bomb_burst_interval = 1.0
@export var bomb_sub_interval = 0.5
@export var bomb_damage = 10.0
@export var bomb_explosion_radius = 120.0
@export var bomb_silence_duration = 0.5
@export var bomb_knockback_strength = 40.0
var bomb_burst_timer = 0.0
var in_outer_zone = false

var kbvelocity = 0
var kbtime = 0

@onready var bomb_scene = preload("res://Scenes/Enemies/dreadlord_bomb.tscn")

@export var inner_zone_dreadlord_speed_bonus = 0.15
@export var inner_zone_player_speed_penalty = 0.4
var player_inner_slow_active = false

@export var execution_stack_interval = 0.5
@export var execution_stacks_needed = 10
var execution_stacks = 0
var execution_stack_timer = 0.0
var execution_triggered = false

signal execution_stacks_changed(current: int, max_stacks: int)

@onready var moon_scene = preload("res://Scenes/Enemies/moon.tscn")
@export var moon_shatter_damage = 10
@export var dash_start_distance = 175.0
@export var dash_duration = 0.5

var current_health
var speed
var chase_subject = null
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

#@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var aggro_area: Area2D = $aggro_area


func _ready() -> void:
	current_health = max_health
	speed = speed_base
	animated_sprite_2d.play("default")

	var aggro_shape := $aggro_area/CollisionShape2D.shape as CircleShape2D
	if aggro_shape != null:
		aggro_shape.radius = aggro_radius


func _physics_process(delta: float) -> void:
	if TimeStop.time_stop_active == true:
		return
	if is_instance_valid(chase_subject) and not chase_subject.rooted:
		update_zone_logic(delta)
		var direction_to_player = (chase_subject.global_position - global_position).normalized()
		velocity = direction_to_player * speed

		if chase_subject.global_position.x > global_position.x:
			animated_sprite_2d.flip_h = true
		elif chase_subject.global_position.x < global_position.x:
			animated_sprite_2d.flip_h = false
	else:
		velocity = Vector2.ZERO
		reset_zone_state()
	if current_health <= 0:
		queue_free()
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
	get_tree().current_scene.add_child(bomb)
	bomb.global_position = global_position
	bomb.direction = (chase_subject.global_position - global_position).normalized()
	bomb.damage = bomb_damage
	bomb.explosion_radius = bomb_explosion_radius
	bomb.silence_duration = bomb_silence_duration
	bomb.knockback_strength = bomb_knockback_strength


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
	if chase_subject.has_method("moon_silence"):
		chase_subject.moon_silence(6.0)
	if chase_subject.has_method("moon_stun"):
		chase_subject.moon_stun(2.0)
		
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if enemy != self and enemy.has_method("set_rooted"):
			enemy.set_rooted(2.0)
			
	var moon_position = chase_subject.global_position
	var moon = moon_scene.instantiate()
	moon.global_position = moon_position
	get_tree().current_scene.call_deferred("add_child", moon)
	
	var direction_to_player = chase_subject.global_position - global_position
	
	if direction_to_player.length() < 1.0:
		direction_to_player = Vector2.RIGHT
		
	var horizontal_sign = 1.0 if direction_to_player.x >= 0.0 else -1.0
	

	await get_tree().create_timer(1.0).timeout
	spawn_afterimage(global_position, horizontal_sign >= 0.0)
	var start_position = moon_position + Vector2(-horizontal_sign * dash_start_distance, 0.0)
	var end_position = moon_position + Vector2(horizontal_sign * dash_start_distance, 0.0)
	
	global_position = start_position
	
	animated_sprite_2d.flip_h = (horizontal_sign >= 0.0)
	
	spawn_afterimage(start_position, horizontal_sign >= 0.0)
	create_dash_slice_line(start_position, end_position)
	
	var tween = create_tween()
	tween.tween_property(self, "global_position", end_position, dash_duration)
	tween.tween_callback(func():
		if moon.has_method("shatter"):
			moon.shatter(Vector2(horizontal_sign, 0.0))
		moon_shatter_damage_sequence(5, 0.05)
	)
	
	execution_stacks = 0
	execution_triggered = false
	execution_stacks_changed.emit(execution_stacks, execution_stacks_needed)
	chase_subject.stunned = false

func moon_shatter_damage_sequence(ticks: int, tick_delay: float) -> void:
	for i in range(ticks):
		chase_subject.moon_damaged = true
		chase_subject.take_player_damage(moon_shatter_damage)
		await get_tree().create_timer(tick_delay).timeout

func spawn_afterimage(at_position: Vector2, facing_right: bool) -> void:
	var afterimage = Sprite2D.new()
	afterimage.texture = animated_sprite_2d.sprite_frames.get_frame_texture(animated_sprite_2d.animation, animated_sprite_2d.frame)
	afterimage.flip_h = facing_right
	afterimage.global_position = at_position
	afterimage.scale = animated_sprite_2d.scale
	afterimage.modulate = Color(1.0, 1.0, 1.0, 0.6)
	afterimage.z_index = animated_sprite_2d.z_index
	get_tree().current_scene.add_child(afterimage)

	var tween = create_tween()
	tween.tween_property(afterimage, "modulate:a", 0.0, 0.4)
	tween.tween_callback(afterimage.queue_free)


func create_dash_slice_line(start_pos: Vector2, end_pos: Vector2) -> void:
	var line = Line2D.new()
	line.width = 3.0
	line.default_color = Color(1.0, 1.0, 1.0, 0.9)
	line.points = [start_pos, start_pos]
	get_tree().current_scene.add_child(line)

	var tween = create_tween()
	tween.tween_method(func(progress):
		line.points = [start_pos, start_pos.lerp(end_pos, progress)]
	, 0.0, 1.0, dash_duration)
	tween.tween_property(line, "modulate:a", 0.0, 0.3)
	tween.tween_callback(line.queue_free)


func run_quiz_sequence() -> void:
	activate_time_stop()
	var quiz_ui = preload("res://Scenes/Enemies/execution_quiz.tscn").instantiate()
	get_tree().current_scene.add_child(quiz_ui)
	quiz_ui.finished.connect(_on_quiz_finished)


func _on_quiz_finished(passed: bool) -> void:
	MusicManager.unpause_music()
	if TimeStopDreadlord:
		TimeStopDreadlord.visible = false
	time_stop_active = false
	TimeStop.time_stop_active = false
	execution_stacks = 0
	execution_triggered = false

	if passed:
		current_health = current_health * 0.5
	else:
		if is_instance_valid(chase_subject) and chase_subject.has_method("take_player_damage"):
			chase_subject.take_player_damage(99999)

func take_damage(amount: float) -> void:
	current_health -= amount
	#animation_player.play("damaged")

func take_kb(source_position: Vector2) -> void:
	var kbdirection = (global_position - source_position).normalized()
	kbvelocity = kbdirection * 600
	kbtime = 0.12


func _on_aggro_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		chase_subject = body
		var stack_ui = body.get_node_or_null("ExecutionStackDisplay")
		if stack_ui and not execution_stacks_changed.is_connected(stack_ui.update_stacks): 
			execution_stacks_changed.connect(stack_ui.update_stacks)


func _on_aggro_area_body_exited(body: Node2D) -> void:
	if chase_subject == body:
		var stack_ui = body.get_node_or_null("ExecutionStackDisplay")
		if stack_ui and execution_stacks_changed.is_connected(stack_ui.update_stacks):
			execution_stacks_changed.disconnect(stack_ui.update_stacks)
			stack_ui.update_stacks(0, execution_stacks_needed)
		chase_subject = null



func trigger_silence_sequence(target: CharacterBody2D) -> void:
	if silence_sequence_active:
		return
	silence_sequence_active = true

	await apply_one_silence(target)
	await get_tree().create_timer(contact_silence_gap).timeout
	await apply_one_silence(target)

	silence_sequence_active = false


func apply_one_silence(target: CharacterBody2D) -> void:
	if not is_instance_valid(target):
		return
	if target.has_method("silence"):
		target.silence(contact_silence_duration)
	if target.has_method("take_player_damage"):
		target.take_player_damage(contact_silence_damage)
	await get_tree().create_timer(contact_silence_duration).timeout
	target.is_silenced = false
	
func activate_time_stop() -> void:
	time_stop_active = true
	TimeStop.time_stop_active = true
	if TimeStopDreadlord:
		TimeStopDreadlord.visible = true
	MusicManager.pause_music()
