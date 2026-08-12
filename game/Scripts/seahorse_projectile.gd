extends CharacterBody2D

@export var speed = 900
var dir: Vector2
var SpawnPos : Vector2
var SpawnRot : float

func _ready() -> void:
	global_position = SpawnPos
	global_rotation = SpawnRot

	
	
func _physics_process(delta: float) -> void:
	velocity = speed * dir
	#velocity = Vector2(0, -speed).rotated(dir)
	move_and_slide()
	
