extends Area2D

@export var travel_time: float = 0.6

@export var bob_scale_min: float = 0.85
@export var bob_scale_max: float = 1.15
@export var bob_speed: float = 10.0  # how fast it grows/shrinks

@export var spin_speed: float = 750.0  # degrees per second

@export var explosion_radius: float = 120.0
@export var base_damage: float = 1.0
@export var knockback_strength: float = 900.0
@export var flash_fade_time: float = 0.33

var start_position: Vector2
var target_position: Vector2
var travel_timer: float = 0.0
var is_traveling: bool = false
var has_exploded: bool = false


func launch(landing_position: Vector2) -> void:
	start_position = global_position
	target_position = landing_position
	travel_timer = 0.0
	is_traveling = true


func _process(delta: float) -> void:
	if has_exploded or not is_traveling:
		return

	travel_timer += delta
	var t: float = clamp(travel_timer / travel_time, 0.0, 1.0)
	global_position = start_position.lerp(target_position, t)

	# Bob (grow/shrink) effect
	var bob_t := (sin(travel_timer * bob_speed) + 1.0) / 2.0
	var bob_scale := lerpf(bob_scale_min, bob_scale_max, bob_t)
	scale = Vector2.ONE * bob_scale

	# Spin
	rotation_degrees += spin_speed * delta

	if t >= 1.0:
		is_traveling = false
		explode()


# Connect this to your bomb's Area2D "body_entered" signal in the editor
# so the bomb explodes early if it touches an enemy mid-flight
func _on_hitbox_body_entered(body: Node2D) -> void:
	if has_exploded or not is_traveling:
		return
	if body.is_in_group("enemy"):
		explode()


func explode() -> void:
	if has_exploded:
		return
	has_exploded = true

	var player := get_tree().get_first_node_in_group("player") as CharacterBody2D
	var damage_multiplier := 1.0
	if player and player.get("total_damage_increase") != null:
		damage_multiplier = float(player.total_damage_increase)

	for possible_enemy in get_tree().get_nodes_in_group("enemy"):
		var enemy := possible_enemy as Node2D
		if enemy == null or not is_instance_valid(enemy):
			continue
		if global_position.distance_to(enemy.global_position) > explosion_radius:
			continue
		if enemy.has_method("take_damage"):
			enemy.take_damage(base_damage * damage_multiplier)
		if enemy.has_method("take_kb"):
			enemy.take_kb(global_position)
			var knockback_direction := global_position.direction_to(enemy.global_position)
			if knockback_direction == Vector2.ZERO:
				knockback_direction = Vector2.RIGHT
			if enemy.get("kbvelocity") != null:
				enemy.set("kbvelocity", knockback_direction * knockback_strength)
			if enemy.get("kbtime") != null:
				enemy.set("kbtime", 0.22)

	spawn_explosion_flash()

	# Hide the bomb sprite immediately, wait for the flash to finish, then free
	visible = false
	await get_tree().create_timer(flash_fade_time).timeout
	queue_free()


func spawn_explosion_flash() -> void:
	var flash := Polygon2D.new()
	var points := PackedVector2Array()
	var segments: int = 20
	for index in range(segments):
		var angle := TAU * float(index) / float(segments)
		points.append(Vector2(cos(angle), sin(angle)) * explosion_radius)

	flash.polygon = points
	flash.color = Color(1.0, 1.0, 1.0, 0.9)
	flash.global_position = global_position
	flash.z_index = 10
	get_tree().current_scene.add_child(flash)

	var flash_tween := flash.create_tween()
	flash_tween.tween_property(flash, "modulate:a", 0.0, flash_fade_time)
	await flash_tween.finished
	flash.queue_free()


func _on_body_entered(body: Node2D) -> void:
	pass # Replace with function body.
