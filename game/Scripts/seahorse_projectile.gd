#everyone will look at this script eventually so important info:
#Layer 1 = Player
#Layer 6 (value 32) = Enemy projectile
#
#One script, two scenes: blackdragonfish_ice_projectile.tscn and
#blackdragonfish_fire_projectile.tscn both use this script and differ only
#by the effect_type value set in the Inspector.

extends CharacterBody2D

@export_enum("ice", "fire") var effect_type: String = "fire"
@export var speed: float = 500.0
@export var damage: float = 5.0
@export var lifetime: float = 4.0

# ice effect
@export var slow_duration: float = 2.0
@export var slow_multiplier: float = 0.5 

# fire effect
@export var burn_dps: float = 5.0
@export var burn_duration: float = 4.0

var dir: Vector2 = Vector2.RIGHT 
var already_hit: bool = false
var SpawnPos: Vector2 = Vector2.ZERO
var SpawnRot: float = 0.0


func _ready() -> void:
	global_position = SpawnPos
	global_rotation = SpawnRot
	rotation = dir.angle()

	await get_tree().create_timer(lifetime).timeout
	queue_free()


func _physics_process(delta: float) -> void:
	global_position += dir * speed * delta


func _on_body_entered(body: Node2D) -> void:
	if already_hit:
		return
	if not body.is_in_group("player"):
		return

	already_hit = true

	if body.has_method("take_damage"):
		body.take_damage(damage)

	if effect_type == "ice":
		if body.has_method("apply_slow"):
			body.apply_slow(slow_duration, slow_multiplier)
	else:
		if body.has_method("apply_burn"):
			body.apply_burn(burn_dps, burn_duration)
