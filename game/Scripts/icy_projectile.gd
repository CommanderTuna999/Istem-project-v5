extends Node2D

@export var speed: float = 900.0
@export var lifetime: float = 1.4
@export var hit_radius: float = 18.0
@export var base_damage: float = 0.5
@export_range(0.4, 0.5, 0.01) var slow_multiplier: float = 0.45
@export var slow_duration: float = 3.0
@export var trail_interval: float = 0.045
@export var trail_lifetime: float = 0.22

var direction: Vector2 = Vector2.RIGHT
var caster: Node2D
var hit_enemies: Array[Node2D] = []
var trail_timer: float = 0.0


func _ready() -> void:
	queue_redraw()
	get_tree().create_timer(lifetime).timeout.connect(queue_free)


func setup(new_caster: Node2D, aim_direction: Vector2) -> void:
	caster = new_caster
	if aim_direction != Vector2.ZERO:
		direction = aim_direction.normalized()
	rotation = direction.angle()


func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta
	trail_timer -= delta
	if trail_timer <= 0.0:
		spawn_trail_pixel()
		trail_timer = trail_interval

	for possible_enemy in get_tree().get_nodes_in_group("enemy"):
		var enemy := possible_enemy as Node2D
		if enemy == null or not is_instance_valid(enemy) or hit_enemies.has(enemy):
			continue
		if global_position.distance_to(enemy.global_position) > hit_radius:
			continue

		hit_enemies.append(enemy)
		if enemy.has_method("take_damage"):
			var damage_multiplier := 1.0
			if is_instance_valid(caster):
				var player_multiplier: Variant = caster.get("total_damage_increase")
				if player_multiplier != null:
					damage_multiplier = float(player_multiplier)
			enemy.take_damage(base_damage * damage_multiplier)
		if enemy.has_method("set_slowed"):
			enemy.set_slowed(slow_duration, slow_multiplier)


func spawn_trail_pixel() -> void:
	var pixel := Polygon2D.new()
	var pixel_size := randf_range(2.0, 4.0)
	pixel.polygon = PackedVector2Array([
		Vector2(-pixel_size, -pixel_size),
		Vector2(pixel_size, -pixel_size),
		Vector2(pixel_size, pixel_size),
		Vector2(-pixel_size, pixel_size),
	])
	pixel.color = Color("54bff5")
	pixel.global_position = global_position - direction * randf_range(4.0, 14.0)
	pixel.global_position += direction.orthogonal() * randf_range(-5.0, 5.0)
	pixel.z_index = 1
	get_tree().current_scene.add_child(pixel)

	var pixel_tween := pixel.create_tween()
	pixel_tween.tween_property(pixel, "modulate:a", 0.0, trail_lifetime)
	await pixel_tween.finished
	if is_instance_valid(pixel):
		pixel.queue_free()


func _draw() -> void:
	# Hard-edged rectangles keep the projectile deliberately pixel-art styled.
	draw_rect(Rect2(-20, -4, 12, 8), Color("54bff5"))
	draw_rect(Rect2(-8, -8, 16, 16), Color("8ee8ff"))
	draw_rect(Rect2(8, -4, 12, 8), Color("54bff5"))
	draw_rect(Rect2(-4, -4, 12, 8), Color("f4feff"))
