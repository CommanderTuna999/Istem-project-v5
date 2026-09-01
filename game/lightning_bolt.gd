extends Node2D

@export var strike_height: float = 400.0
@export var jaggedness: float = 64.0
@export var min_segment_length: float = 10.0
@export var bolt_lifetime: float = 0.8

@onready var bolt: Line2D = $Bolt
@onready var sparks: GPUParticles2D = $Sparks


func _ready() -> void:
	generate_bolt()
	sparks.restart()
	sparks.emitting = true
	await get_tree().create_timer(bolt_lifetime).timeout
	queue_free()


func generate_bolt() -> void:
	var start := Vector2(0, -strike_height)
	var end := Vector2.ZERO
	var points := PackedVector2Array()
	points.append(start)
	_displace(start, end, jaggedness, points)
	bolt.points = points


func _displace(p1: Vector2, p2: Vector2, displacement: float, points: PackedVector2Array) -> void:
	if p1.distance_to(p2) < min_segment_length or displacement < 2.0:
		points.append(p2)
		return
	var mid := (p1 + p2) / 2.0
	var normal := (p2 - p1).orthogonal().normalized()
	mid += normal * randf_range(-displacement, displacement)
	_displace(p1, mid, displacement * 0.5, points)
	_displace(mid, p2, displacement * 0.5, points)
