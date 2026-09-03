extends CharacterBody2D

@export var speed: float = 150.0
@export var wander_radius: float = 160.0
@export var wander_speed: float = 60.0
@export var absorb_radius: float = 500.0
@export var absorb_percent: float = 0.25
@export var sprite_offset_x: float = 7.5

var max_health: float = 25.0
var current_health: float

var aggro: bool = false
var chase_subject: Node2D = null

var home_position: Vector2 = Vector2.ZERO
var wander_target: Vector2 = Vector2.ZERO
var wander_wait_time: float = 0.0

var kbtime: float = 0.0
var kbvelocity: Vector2 = Vector2.ZERO
var rooted: bool = false
var root_timer: float = 0.0
var slow_active: bool = false

var protection_lines: Dictionary = {}

@onready var animation: AnimatedSprite2D = $AnimatedSprite2D
@onready var absorb_area: Area2D = $absorb_area


func _ready() -> void:
	current_health = max_health
	animation.play("default")
	home_position = global_position
	pick_new_wander_target()

	var absorb_shape := $absorb_area/CollisionShape2D.shape as CircleShape2D
	if absorb_shape:
		absorb_shape.radius = absorb_radius


func _process(_delta: float) -> void:
	if current_health <= 0:
		queue_free()
	update_protection_lines()


func update_protection_lines() -> void:
	for body in protection_lines.keys():
		if not is_instance_valid(body):
			protection_lines[body].queue_free()
			protection_lines.erase(body)
			continue
		var line: Line2D = protection_lines[body]
		line.points = [Vector2.ZERO, to_local(body.global_position)]
		var distance := global_position.distance_to(body.global_position)
		line.modulate.a = line_alpha_factor(distance)


func line_alpha_factor(distance: float) -> float:
	if distance <= 200.0:
		return 1.0
	if distance >= 500.0:
		return 0.2
	var t := (distance - 200.0) / (500.0 - 200.0)
	return lerp(1.0, 0.2, t)


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

	if aggro and chase_subject:
		velocity = (chase_subject.global_position - global_position).normalized() * speed
		if velocity.x > 0:
			set_facing(true)
		elif velocity.x < 0:
			set_facing(false)
	else:
		wander(delta)

	move_and_slide()


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
		set_facing(true)
	elif velocity.x < 0:
		set_facing(false)


func pick_new_wander_target() -> void:
	var random_offset := Vector2(randf_range(-wander_radius, wander_radius), randf_range(-wander_radius, wander_radius))
	wander_target = home_position + random_offset


func set_facing(flipped: bool) -> void:
	animation.flip_h = flipped
	animation.offset.x = -sprite_offset_x if flipped else sprite_offset_x


func _on_aggro_area_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	chase_subject = body
	aggro = true


func _on_aggro_area_body_exited(_body: Node2D) -> void:
	chase_subject = null
	aggro = false


func _on_absorb_area_body_entered(body: Node2D) -> void:
	if body == self:
		return
	if not body.is_in_group("enemy"):
		return
	if protection_lines.has(body):
		return
	var line := Line2D.new()
	line.width = 3.0
	line.default_color = Color(0.4, 1.0, 0.6, 0.8)
	line.z_index = -1
	add_child(line)
	protection_lines[body] = line


func _on_absorb_area_body_exited(body: Node2D) -> void:
	if protection_lines.has(body):
		protection_lines[body].queue_free()
		protection_lines.erase(body)


func absorb_damage(amount: float) -> void:
	current_health -= amount


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
	speed *= multiplier
	wander_speed *= multiplier
	await get_tree().create_timer(duration).timeout
	speed /= multiplier
	wander_speed /= multiplier
	slow_active = false
