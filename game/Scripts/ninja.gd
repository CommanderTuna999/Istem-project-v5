extends CharacterBody2D

@onready var shuriken_scene = preload("res://Scenes/Enemies/shuriken.tscn")

var damage_occuring = false
var aggro = false
var chase_subject = null
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var aggro_area: Area2D = $aggro_area
var current_health = 5.0
var kbtime = 0.06
var kbvelocity = Vector2.ZERO
var dying = false
var rooted = false
var root_timer = 0.0
var slow_active = false

var homeposition = Vector2.ZERO
var wander_teleport_radius = 200.0
var wander_wait_timer = 0.0

var retreating = false
var retreattimer = 0.0
var retreatcooldown = 0.0
var retreatspeed = 220.0
var retreatduration = 0.15
var retreatcooldowntime = 0.3
var retreatdistance = 150.0

var last_known_player_position = Vector2.ZERO

var shot_cooldown = 1.15
var shot_timer = 0.0
var shot_count = 0


func _ready() -> void:
	homeposition = global_position
	#animated_sprite_2d.play("idle")


func _process(_delta: float) -> void:
	if not chase_subject == null and chase_subject.position.x > position.x:
		animated_sprite_2d.flip_h = true
	elif not chase_subject == null and chase_subject.position.x < position.x:
		animated_sprite_2d.flip_h = false

	if current_health <= 0 and not dying:
		dying = true
		queue_free()

	if rooted:
		return


func _on_aggro_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		chase_subject = body
		aggro = true


func _on_aggro_area_body_exited(body: Node2D) -> void:
	if chase_subject == body:
		chase_subject = null
		aggro = false


func _physics_process(delta: float) -> void:

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

	if aggro and is_instance_valid(chase_subject):
		last_known_player_position = chase_subject.global_position

		shot_timer -= delta
		if shot_timer <= 0.0:
			throw_shuriken()
			shot_timer = shot_cooldown

		if retreatcooldown > 0.0:
			retreatcooldown -= delta

		if retreating:
			retreattimer -= delta
			if retreattimer <= 0.0:
				retreating = false
		else:
			var distancetoplayer = global_position.distance_to(chase_subject.global_position)
			if distancetoplayer < retreatdistance and retreatcooldown <= 0.0:
				var awayfromplayer = (global_position - chase_subject.global_position).normalized()
				var sideways = Vector2(-awayfromplayer.y, awayfromplayer.x)
				sideways *= randf_range(-0.35, 0.35)
				var retreatdirection = (awayfromplayer + sideways).normalized()
				velocity = retreatdirection * retreatspeed
				retreating = true
				retreattimer = retreatduration
				retreatcooldown = retreatcooldowntime
			else:
				velocity = velocity.move_toward(Vector2.ZERO, 500.0 * delta)
	else:
		if wander_wait_timer > 0.0:
			wander_wait_timer -= delta
			velocity = Vector2.ZERO
		else:
			pick_new_wander_teleport()
			wander_wait_timer = randf_range(1.5, 3.0)

	move_and_slide()


func pick_new_wander_teleport() -> void:
	var min_enemy_distance = 45.0
	var attempts = 10
	var chosen_position = global_position

	for i in range(attempts):
		var angle = randf_range(0, TAU)
		var distance = randf_range(wander_teleport_radius * 0.5, wander_teleport_radius)
		var offset = Vector2(cos(angle), sin(angle)) * distance
		var candidate_position = homeposition + offset

		var too_close = false
		for enemy in get_tree().get_nodes_in_group("enemy"):
			if enemy == self:
				continue
			if not is_instance_valid(enemy):
				continue
			if candidate_position.distance_to(enemy.global_position) < min_enemy_distance:
				too_close = true
				break

		chosen_position = candidate_position
		if not too_close:
			break

	var old_position = global_position
	global_position = chosen_position

	if chosen_position.x > old_position.x:
		animated_sprite_2d.flip_h = true
	elif chosen_position.x < old_position.x:
		animated_sprite_2d.flip_h = false


func throw_shuriken() -> void:
	if not is_instance_valid(chase_subject):
		return

	shot_count += 1
	var main = get_tree().current_scene
	var instance = shuriken_scene.instantiate()

	var direction = (last_known_player_position - global_position).normalized()
	instance.direction = direction

	var is_shiny = shot_count % 4 == 0
	if is_shiny:
		instance.speed *= 1.2
		instance.modulate = Color(1.5, 1.5, 1.5, 1.0)
		instance.bleed = true

	main.call_deferred("add_child", instance)
	instance.global_position = global_position


func take_damage(amount: float) -> void:
	current_health -= amount
	#animation_player.play("damaged")


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
	retreatspeed *= multiplier
	await get_tree().create_timer(duration).timeout
	retreatspeed /= multiplier
	slow_active = false
