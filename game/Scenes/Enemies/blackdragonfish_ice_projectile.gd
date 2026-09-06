extends Area2D

@export_enum("ice", "fire") var effect_type: String = "ice"
@export var speed: float = 1000.0
@export var damage: float = 5.0
@export var lifetime: float = 5.0

@export var slow_duration: float = 3.0
@export var slow_multiplier: float = 0.5 

@export var burn_dps: float = 5.0
@export var burn_duration: float = 4.0

@onready var particles: GPUParticles2D = $GPUParticles2D

var dir: Vector2 = Vector2.RIGHT 
var already_hit: bool = false


func _ready() -> void:
	rotation = dir.angle()
	body_entered.connect(_on_body_entered)
	await get_tree().create_timer(lifetime).timeout
	
	if is_instance_valid(particles) and not already_hit:
		_cleanup_particles_and_free()
	elif not already_hit:
		queue_free()


func _physics_process(delta: float) -> void:
	global_position += dir * speed * delta


func _on_body_entered(body: Node2D) -> void:
	if already_hit:
		return
	if not body.is_in_group("player"):
		return

	already_hit = true

	if body.has_method("take_player_damage"):
		body.take_player_damage(damage)

	if effect_type == "ice":
		if body.has_method("apply_slow"):
			body.apply_slow(slow_duration, slow_multiplier)
	else:
		if body.has_method("apply_burn"):
			body.apply_burn(burn_dps, burn_duration)
	
	_cleanup_particles_and_free()


func _cleanup_particles_and_free() -> void:
	set_physics_process(false)
	
	remove_child(particles)
	get_tree().current_scene.add_child(particles)
	particles.global_position = global_position
	particles.emitting = true
	
	var p_timer = get_tree().create_timer(particles.lifetime)
	p_timer.timeout.connect(particles.queue_free)
	
	queue_free()
