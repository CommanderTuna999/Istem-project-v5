extends Line2D
class_name LightningBolt

@export var length_min = 60.0
@export var length_max = 140.0
@export var segment_count = 8
@export var jitter_amount = 14.0
@export var base_width = 6.0
@export var lifetime = 0.35
@export var shrink_start_ratio = 0.5 


func _ready() -> void:
	generate_bolt()
	animate_and_free()

func generate_bolt() -> void:
	default_color = Color(1.0, 0.92, 0.3, 1.0)  
	var angle = randf_range(0, TAU)
	var length = randf_range(length_min, length_max)
	var end_point = Vector2(cos(angle), sin(angle)) * length

	var pts = PackedVector2Array()
	pts.append(Vector2.ZERO)

	for i in range(1, segment_count):
		var t = float(i) / float(segment_count)
		var base_point = Vector2.ZERO.lerp(end_point, t)
		var perp = end_point.normalized().rotated(PI / 2.0)
		var offset = perp * randf_range(-jitter_amount, jitter_amount) * (1.0 - t)
		pts.append(base_point + offset)

	pts.append(end_point)
	points = pts


	var curve = Curve.new()
	curve.add_point(Vector2(0.0, 1.0))
	curve.add_point(Vector2(1.0, 0.0))
	width_curve = curve
	width = base_width

	default_color = Color(0.75, 0.9, 1.0, 1.0)  
	joint_mode = Line2D.LINE_JOINT_ROUND
	begin_cap_mode = Line2D.LINE_CAP_ROUND
	end_cap_mode = Line2D.LINE_CAP_ROUND

func animate_and_free() -> void:
	var shrink_time = lifetime * (1.0 - shrink_start_ratio)
	var hold_time = lifetime - shrink_time

	var tween = create_tween()
	tween.tween_interval(hold_time)
	tween.tween_property(self, "width", 0.0, shrink_time)
	tween.parallel().tween_property(self, "modulate:a", 0.0, shrink_time)
	tween.tween_callback(queue_free)
