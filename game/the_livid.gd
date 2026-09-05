extends CharacterBody2D

@export var max_health = 10.0
@export var contact_damage_base = 1
@export var speed_base = 125.0
@export var aggro_radius_base = 100.0
@export var dagger_damage_base = 5
@export var dagger_speed_base = 750.0
@export var dagger_shot_delay_base = 2.0
@export var dagger_spin_speed_base = 25.0
@export var dagger_size_base = 1.0
@export var wander_radius = 200.0

var shake_intensity:
	get:
		return 0.25 * rage_level
var rage_colour_max_level = 10.0

var current_health
var contact_damage
var speed
var aggro_radius
var dagger_damage
var dagger_speed
var dagger_shot_delay
var dagger_spin_speed
var dagger_size
var scale_multiplier = 1.0

var external_speed_multiplier = 1.0
var external_aggro_multiplier = 1.0

var rage_level = 0
var has_hit_rage_2 = false
var permanent_rage = false
var rage_decay_timer = 0.0

var chase_subject = null
var lock_on_timer = 0.0

var homeposition = Vector2.ZERO
var wander_target = Vector2.ZERO

var kbtime = 0.0
var kbvelocity = Vector2.ZERO
var rooted = false
var root_timer = 0.0
var slow_active = false

var shot_timer = 0.0

var dash_state = "idle"
var dash_charge_timer = 0.0
var dash_target = Vector2.ZERO
var dash_cooldown_timer = 0.0
var dash_count = 0
var dash_invincible = false
var dash_lockout_timer = 0.0

@export var dash_swipe_width = 40.0
@export var dash_swipe_forward_range = 60.0
@export var dash_swipe_knockback_strength = 500.0
var dash_hit_enemies = []


@export var contact_knockback_strength = 220.0

@export var dash_afterimage_interval = 0.035
@export var afterimage_fade_time = 0.35
var dash_afterimage_timer = 0.0

var dying = false

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var aggro_area: Area2D = $aggro_area
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D

@onready var dagger_scene = preload("res://Scenes/Enemies/dagger.tscn")
@onready var portal_scene = preload("res://Scenes/Enemies/portal.tscn")
@onready var rage_bottle_scene = preload("res://Scenes/Enemies/rage_bottle.tscn")


func _ready() -> void:
	homeposition = global_position
	current_health = max_health
	recalculate_stats()
	animated_sprite_2d.play("idle")
	pick_new_wander_target()


func _process(_delta: float) -> void:
	if not chase_subject == null and chase_subject.position.x > position.x:
		animated_sprite_2d.flip_h = true
	elif not chase_subject == null and chase_subject.position.x < position.x:
		animated_sprite_2d.flip_h = false

	if current_health <= 0 and not dying:
		dying = true
		queue_free()


func recalculate_stats() -> void:
	var r = float(rage_level)
	contact_damage = contact_damage_base + (10 * r)
	speed = speed_base * (1.0 + 0.05 * r) * external_speed_multiplier
	aggro_radius = aggro_radius_base * (1.0 + 0.10 * r) * external_aggro_multiplier
	scale_multiplier = 1.0 + 0.05 * r
	dagger_damage = dagger_damage_base
	dagger_speed = dagger_speed_base * (1.0 + 0.05 * r)
	dagger_shot_delay = max(0.3, dagger_shot_delay_base - 0.2 * r)
	dagger_spin_speed = dagger_spin_speed_base * (1.0 + 0.15 * r)
	dagger_size = dagger_size_base * (1.0 + 0.035 * r)

	scale = Vector2.ONE * scale_multiplier

	var aggro_shape := $aggro_area/CollisionShape2D.shape as CircleShape2D
	if aggro_shape != null:
		aggro_shape.radius = aggro_radius

	if rage_level >= 2 and not has_hit_rage_2:
		has_hit_rage_2 = true
		max_health += 1.0

	if rage_level >= 10 and not permanent_rage:
		permanent_rage = true
	update_rage_colour()


func gain_rage() -> void:
	rage_level += 1
	current_health = min(max_health, current_health + max_health * 0.09)
	recalculate_stats()
	rage_decay_timer = 15.0
	
	if rage_level == 6:
		trigger_rage_bottle_event()

	var base_speed = speed
	speed = base_speed * 1.3
	await get_tree().create_timer(2.0).timeout
	speed = base_speed



func lose_rage() -> void:
	if permanent_rage:
		return
	if rage_level <= 0:
		return
	rage_level -= 1
	recalculate_stats()


func _physics_process(delta: float) -> void:
	var random_offset = Vector2(
		randf_range(-shake_intensity, shake_intensity),
		randf_range(-shake_intensity, shake_intensity)
	)
	animated_sprite_2d.position = random_offset
	
	if is_instance_valid(chase_subject):
		if aggro_area.overlaps_body(chase_subject):
			lock_on_timer = 5.0
		else:
			lock_on_timer -= delta
			if lock_on_timer <= 0.0:
				chase_subject = null

	if not permanent_rage:
		rage_decay_timer -= delta
		if rage_decay_timer <= 0.0 and rage_level > 0:
			lose_rage()
			rage_decay_timer = 15.0

	if rooted:
		root_timer -= delta
		velocity = Vector2.ZERO
		move_and_slide()
		if root_timer <= 0.0:
			rooted = false
		return

	if kbtime > 0:
		kbtime -= delta
		velocity = kbvelocity
		move_and_slide()
		return

	if dash_lockout_timer > 0.0:
		dash_lockout_timer -= delta

	if dash_state == "charging":
		dash_charge_timer -= delta
		velocity = Vector2.ZERO
		if dash_charge_timer <= 0.0:
			dash_target = chase_subject.global_position if is_instance_valid(chase_subject) else global_position
			dash_state = "dashing"
			dash_invincible = true
		move_and_slide()
		return

	if dash_state == "dashing":
		var to_target = global_position.direction_to(dash_target)
		velocity = to_target * 900.0
		move_and_slide()

		# afterimage trail
		dash_afterimage_timer -= delta
		if dash_afterimage_timer <= 0.0:
			spawn_dash_afterimage()
			dash_afterimage_timer = dash_afterimage_interval

		# sideways swipe on nearby enemies
		var perp = to_target.rotated(PI / 2.0)
		for enemy in get_tree().get_nodes_in_group("enemy"):
			if enemy == self or enemy in dash_hit_enemies:
				continue
			var rel = enemy.global_position - global_position
			var along = rel.dot(to_target)
			var side = rel.dot(perp)
			if along >= 0.0 and along <= dash_swipe_forward_range and abs(side) <= dash_swipe_width:
				if enemy.has_method("take_kb"):
					var push_dir = perp * sign(side) if side != 0.0 else perp
					if "kbvelocity" in enemy:
						enemy.kbvelocity = push_dir * dash_swipe_knockback_strength
					elif "kb_velocity" in enemy:
						enemy.kb_velocity = push_dir * dash_swipe_knockback_strength
					if "kbtime" in enemy:
						enemy.kbtime = 0.2
					elif "kb_time" in enemy:
						enemy.kb_time = 0.2
					dash_hit_enemies.append(enemy)

		var hit_player = false
		for i in range(get_slide_collision_count()):
			var collision = get_slide_collision(i)
			var collider = collision.get_collider()
			if collider and collider.is_in_group("player"):
				hit_player = true
				break

		if hit_player or global_position.distance_to(dash_target) < 16.0:
			finish_dash(to_target)
		return

	if dash_state == "recovering":
		velocity = velocity.move_toward(Vector2.ZERO, 600.0 * delta)
		if velocity.length() < 5.0:
			dash_state = "idle"
		move_and_slide()
		return

	if dash_cooldown_timer > 0.0:
		dash_cooldown_timer -= delta

	if is_instance_valid(chase_subject):
		if rage_level >= 4 and dash_cooldown_timer <= 0.0 and dash_state == "idle":
			start_dash()

		if dash_lockout_timer <= 0.0 and dash_state == "idle":
			shot_timer -= delta
			if shot_timer <= 0.0:
				throw_dagger()
				shot_timer = dagger_shot_delay

		var direction_to_player = (chase_subject.global_position - global_position).normalized()
		velocity = direction_to_player * speed
	else:
		var direction_to_wander = wander_target - global_position
		if direction_to_wander.length() > 10:
			velocity = direction_to_wander.normalized() * (speed * 0.5)

			if velocity.x > 0:
				animated_sprite_2d.flip_h = true
			elif velocity.x <= 0:
				animated_sprite_2d.flip_h = false
		else:
			pick_new_wander_target()

	move_and_slide()


func finish_dash(dash_direction: Vector2) -> void:
	velocity = Vector2.ZERO

	if is_instance_valid(chase_subject):
		if chase_subject.has_method("take_player_damage"):
			chase_subject.take_player_damage(15)
		if "kbvelocity" in chase_subject and "kbtime" in chase_subject:
			chase_subject.kbvelocity = dash_direction * 900.0
			chase_subject.kbtime = 0.15

	dash_state = "recovering"
	dash_lockout_timer = 0.65
	await get_tree().create_timer(0.1).timeout
	dash_invincible = false


func pick_new_wander_target() -> void:
	var angle = randf_range(0, TAU)
	var distance = randf_range(10.0, wander_radius)
	wander_target = homeposition + Vector2(cos(angle), sin(angle)) * distance


func start_dash() -> void:
	if rage_level < 4:
		return

	var cost = 0
	if dash_count == 0:
		cost = 2
	elif dash_count == 1:
		cost = 1

	rage_level -= cost
	recalculate_stats()

	dash_count += 1
	dash_state = "charging"
	dash_charge_timer = 1
	dash_cooldown_timer = 4.0
	dash_hit_enemies.clear()


func throw_dagger() -> void:
	if not is_instance_valid(chase_subject):
		return

	var instance = dagger_scene.instantiate()
	var main = get_tree().current_scene
	var direction = (chase_subject.global_position - global_position).normalized()

	instance.direction = direction
	instance.speed = dagger_speed
	instance.damage = dagger_damage
	instance.spin_speed = dagger_spin_speed
	instance.scale = Vector2.ONE * dagger_size
	instance.thrower = self

	main.call_deferred("add_child", instance)
	instance.global_position = global_position


func trigger_rage_bottle_event() -> void:
	var main = get_tree().current_scene

	var portal_instance = portal_scene.instantiate()
	portal_instance.global_position = global_position
	main.call_deferred("add_child", portal_instance)

	var bottle_instance = rage_bottle_scene.instantiate()
	bottle_instance.global_position = global_position
	bottle_instance.thrower = self
	main.call_deferred("add_child", bottle_instance)


func take_damage(amount: float) -> void:
	if dash_invincible:
		return
	current_health -= amount
	#animation_player.play("damaged")


func take_kb(source_position: Vector2, strength: float = 600.0, duration: float = 0.12) -> void:
	if dash_invincible:
		return
	var kbdirection = (global_position - source_position).normalized()
	kbvelocity = kbdirection * strength
	kbtime = duration

func set_rooted(duration: float) -> void:
	rooted = true
	root_timer = max(root_timer, duration)


func set_slowed(duration: float, multiplier: float) -> void:
	if slow_active:
		return
	slow_active = true
	external_speed_multiplier *= multiplier
	recalculate_stats()
	await get_tree().create_timer(duration).timeout
	external_speed_multiplier /= multiplier
	recalculate_stats()
	slow_active = false


func _on_aggro_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		chase_subject = body
		lock_on_timer = 5.0

func update_rage_colour() -> void:
	var t = clamp(float(rage_level) / rage_colour_max_level, 0.0, 1.0)
	animated_sprite_2d.modulate = Color.WHITE.lerp(Color.RED, t)
	
func spawn_dash_afterimage() -> void:
	if animated_sprite_2d.sprite_frames == null:
		return

	var ghost = Sprite2D.new()
	ghost.texture = animated_sprite_2d.sprite_frames.get_frame_texture(
		animated_sprite_2d.animation, animated_sprite_2d.frame
	)
	ghost.global_position = animated_sprite_2d.global_position
	ghost.global_rotation = animated_sprite_2d.global_rotation
	ghost.scale = animated_sprite_2d.global_scale
	ghost.flip_h = animated_sprite_2d.flip_h
	ghost.modulate = Color(1.0, 0.25, 0.25, 0.55)
	ghost.z_index = z_index - 1

	get_tree().current_scene.add_child(ghost)

	var tween = create_tween()
	tween.tween_property(ghost, "modulate:a", 0.0, afterimage_fade_time)
	tween.tween_callback(ghost.queue_free)
