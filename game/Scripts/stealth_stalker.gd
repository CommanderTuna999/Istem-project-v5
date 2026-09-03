extends CharacterBody2D

@export var speed: float = 185.0
@export var max_health: float = 4.0
@export var aggro_radius: float = 360.0
@export var reveal_distance: float = 165.0
@export var wander_radius: float = 160.0
@export var wander_speed: float = 60.0

var current_health: float
var aggro: bool = false
var chase_subject: Node2D
var home_position: Vector2
var wander_target: Vector2
var wander_wait_time: float = 0.0
var kb_time: float = 0.0
var kb_velocity: Vector2 = Vector2.ZERO
var rooted: bool = false
var root_timer: float = 0.0
var slow_active: bool = false

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var animation_template: AnimatedSprite2D = $AnimationGSHARK
@onready var navigation_agent: NavigationAgent2D = $NavigationAgent2D
@onready var aggro_area: Area2D = $aggro_area


func _ready() -> void:
	current_health = max_health
	home_position = global_position
	var aggro_shape := $aggro_area/CollisionShape2D.shape as CircleShape2D
	if aggro_shape != null:
		aggro_shape.radius = aggro_radius
	pick_new_wander_target()
	animation_template.play("aggro")
	update_visibility()


func _process(_delta: float) -> void:
	if current_health <= 0.0:
		queue_free()
		return

	update_visibility()


func _physics_process(delta: float) -> void:
	refresh_aggro_target()

	if kb_time > 0.0:
		kb_time -= delta
		velocity = kb_velocity
		move_and_slide()
		return

	if is_instance_valid(chase_subject):
		aggro = true
		steer_toward(chase_subject.global_position, speed)
	else:
		aggro = false
		wander(delta)

	update_facing(velocity.x)
	move_and_slide()


func refresh_aggro_target() -> void:
	chase_subject = null
	for body in aggro_area.get_overlapping_bodies():
		if body.is_in_group("player"):
			chase_subject = body as Node2D
			return


func steer_toward(target_position: Vector2, movement_speed: float) -> void:
	navigation_agent.target_position = target_position
	var next_position := target_position
	if navigation_agent.get_navigation_map().is_valid() and not navigation_agent.is_navigation_finished():
		var path_position := navigation_agent.get_next_path_position()
		if path_position.distance_to(global_position) > 1.0:
			next_position = path_position
	velocity = global_position.direction_to(next_position) * movement_speed


func wander(delta: float) -> void:
	if wander_wait_time > 0.0:
		wander_wait_time -= delta
		velocity = Vector2.ZERO
		play_template_animation("idle")
		return
	if global_position.distance_to(wander_target) < 10.0:
		wander_wait_time = randf_range(0.6, 1.8)
		pick_new_wander_target()
		return

	steer_toward(wander_target, wander_speed)
	play_template_animation("move")


func pick_new_wander_target() -> void:
	var random_offset := Vector2(randf_range(-wander_radius, wander_radius), randf_range(-wander_radius, wander_radius))
	wander_target = home_position + random_offset
	navigation_agent.target_position = wander_target


func update_facing(horizontal_speed: float) -> void:
	if is_zero_approx(horizontal_speed):
		return
	animation_template.flip_h = horizontal_speed > 0.0


func update_visibility() -> void:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		animation_template.modulate.a = 0.0
		return

	var distance := global_position.distance_to(player.global_position)
	var reveal_amount := clampf(1.0 - (distance / reveal_distance), 0.0, 1.0)
	animation_template.modulate.a = reveal_amount


func play_template_animation(animation_name: StringName) -> void:
	if animation_template.sprite_frames and animation_template.sprite_frames.has_animation(animation_name):
		animation_template.play(animation_name)


func take_damage(amount: float) -> void:
	current_health -= amount


func take_kb(source_position: Vector2) -> void:
	if kb_time > 0.0:
		return
	print("knockback")
	kb_velocity = (global_position - source_position).normalized() * 600.0
	kb_time = 0.12


func _on_aggro_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		chase_subject = body


func _on_aggro_area_body_exited(body: Node2D) -> void:
	if body == chase_subject:
		chase_subject = null
