extends CharacterBody2D
@export var speed: float = 150.0
@export var max_health: float = 4.0
@export var aggro_radius: float = 90.0
var current_health: float
var aggro: bool = false
var chase_subject: Node2D
var home_position: Vector2
var kb_time: float = 0.0
var kb_velocity: Vector2 = Vector2.ZERO
@onready var placeholder_sprite: Sprite2D = $PlaceholderSprite
@onready var aggro_area: Area2D = $aggro_area
func _ready() -> void:
	current_health = max_health
	home_position = global_position
	var aggro_shape := $aggro_area/CollisionShape2D.shape as CircleShape2D
	if aggro_shape != null:
		aggro_shape.radius = aggro_radius
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
		update_facing(velocity.x)
		move_and_slide()
		return
	if is_instance_valid(chase_subject):
		aggro = true
		steer_toward(chase_subject.global_position, speed)
	else:
		aggro = false
		velocity = Vector2.ZERO
	update_facing(velocity.x)
	move_and_slide()
func refresh_aggro_target() -> void:
	chase_subject = null
	for body in aggro_area.get_overlapping_bodies():
		if body.is_in_group("player"):
			chase_subject = body as Node2D
			return
func steer_toward(target_position: Vector2, movement_speed: float) -> void:
	velocity = global_position.direction_to(target_position) * movement_speed
func update_facing(horizontal_speed: float) -> void:
	if is_zero_approx(horizontal_speed):
		return
	placeholder_sprite.flip_h = horizontal_speed > 0.0
func update_visibility() -> void:
	# No fade - only visible while actively aggro'd on the player.
	placeholder_sprite.modulate.a = 1.0 if aggro else 0.0
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
