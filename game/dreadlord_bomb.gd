extends Area2D

var damage = 10.0
var explosion_radius = 120.0
var silence_duration = 0.5
var knockback_strength = 40.0
var fuse_time = 1.4
var travel_speed = 400.0
var direction = Vector2.ZERO
var flash_fade_time = 0.5

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var explosion_area: Area2D = $ExplosionArea
@onready var fuse_timer: Timer = $FuseTimer


func _ready() -> void:
	var shape := $CollisionShape2D.shape as CircleShape2D
	if shape != null:
		shape.radius = explosion_radius

	animated_sprite_2d.play("default")
	rotation = direction.angle()
	fuse_timer.start(fuse_time)


func _physics_process(delta: float) -> void:
	global_position += direction * travel_speed * delta


func _on_fuse_timer_timeout() -> void:
	explode()


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		explode()


func explode() -> void:
	var player := get_tree().get_first_node_in_group("player") as CharacterBody2D
	if player and is_instance_valid(player):
		if global_position.distance_to(player.global_position) <= explosion_radius:
			if player.has_method("take_player_damage"):
				player.take_player_damage(damage)
			if player.has_method("apply_silence"):
				player.apply_silence(silence_duration)
			var knockback_direction := global_position.direction_to(player.global_position)
			if knockback_direction == Vector2.ZERO:
				knockback_direction = Vector2.RIGHT
			if player.get("kbvelocity") != null:
				player.set("kbvelocity", knockback_direction * knockback_strength)
			if player.get("kbtime") != null:
				player.set("kbtime", 0.1)
	spawn_explosion_flash()
	visible = false
	await get_tree().create_timer(flash_fade_time).timeout
	queue_free()


func spawn_explosion_flash() -> void:
	var flash := Polygon2D.new()
	var points := PackedVector2Array()
	var segments := 20
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
