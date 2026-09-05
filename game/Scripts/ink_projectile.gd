extends CharacterBody2D

@export var gravity_strength: float = 1200.0
@export var lifetime: float = 4.0

var starting_velocity: Vector2 = Vector2.ZERO
var life_timer: float = 0.0


func _ready() -> void:
	velocity = starting_velocity


func _physics_process(delta: float) -> void:
	life_timer += delta

	if life_timer >= lifetime:
		queue_free()
		return

	# Strong downward curve immediately.
	velocity.y += gravity_strength * delta

	move_and_slide()

	if get_slide_collision_count() > 0:
		queue_free()
