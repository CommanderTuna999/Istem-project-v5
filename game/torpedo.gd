extends CharacterBody2D

@export var speed: float = 666.0

@export var detonate_range: float = 60.0
@export var fuse_time: float = 2.0
@export var explosion_radius: float = 150.0
@export var damage: float = 15.0
@export var knockback_strength: float = 900.0
@export var flash_fade_time: float = 0.167

var max_health: float = 4.0
var current_health: float

var aggro: bool = false
var chase_subject: Node2D = null

var armed: bool = false
var invincible: bool = false
var fuse_timer: float = 0.0

var kbtime: float = 0.0
var kbvelocity: Vector2 = Vector2.ZERO
var rooted: bool = false
var root_timer: float = 0.0
var slow_active: bool = false

@onready var animation: AnimatedSprite2D = $AnimatedSprite2D
@onready var detonate_area: Area2D = $detonate_area


func _ready() -> void:
	current_health = max_health
	animation.play("default")

	var detonate_shape := $detonate_area/CollisionShape2D.shape as CircleShape2D
	if detonate_shape:
		detonate_shape.radius = detonate_range


func _process(_delta: float) -> void:
	if not armed and chase_subject != null:
		if chase_subject.global_position.x > global_position.x:
			animation.flip_h = true
		elif chase_subject.global_position.x < global_position.x:
			animation.flip_h = false

	if current_health <= 0 and not armed:
		queue_free()


func _physics_process(delta: float) -> void:
	if armed:
		velocity = Vector2.ZERO
		move_and_slide()
		fuse_timer -= delta
		if fuse_timer <= 0.0:
			explode()
		return

	if rooted:
		root_timer -= delta
		velocity = Vector2.ZERO
		move_and_slide()
		if root_timer <= 0.0:
			rooted = false
		return

	if kbtime > 0.0:
		kbtime -= delta
		velocity = kbvelocity
		move_and_slide()
		return

	if aggro and chase_subject:
		velocity = (chase_subject.global_position - global_position).normalized() * speed
	else:
		velocity = Vector2.ZERO

	move_and_slide()


func _on_aggro_area_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	chase_subject = body
	aggro = true


func _on_aggro_area_body_exited(_body: Node2D) -> void:
	if armed:
		return
	chase_subject = null
	aggro = false


func _on_detonate_area_body_entered(body: Node2D) -> void:
	if armed or not body.is_in_group("player"):
		return
	arm()


func arm() -> void:
	armed = true
	invincible = true
	fuse_timer = fuse_time
	animation.play("armed")


func explode() -> void:
	var player := get_tree().get_first_node_in_group("player") as CharacterBody2D
	if player and is_instance_valid(player):
		if global_position.distance_to(player.global_position) <= explosion_radius:
			if player.has_method("take_player_damage"):
				player.take_player_damage(damage)
			var knockback_direction := global_position.direction_to(player.global_position)
			if knockback_direction == Vector2.ZERO:
				knockback_direction = Vector2.RIGHT
			if player.get("kbvelocity") != null:
				player.set("kbvelocity", knockback_direction * knockback_strength)
			if player.get("kbtime") != null:
				player.set("kbtime", 0.22)
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


func take_damage(amount: float) -> void:
	if invincible:
		return
	current_health -= amount


func take_kb(source_position: Vector2) -> void:
	if invincible:
		return
	var kbdirection = (global_position - source_position).normalized()
	kbvelocity = kbdirection * 600
	kbtime = 0.12


func set_rooted(duration: float) -> void:
	if invincible:
		return
	rooted = true
	root_timer = max(root_timer, duration)


func set_slowed(duration: float, multiplier: float) -> void:
	if invincible or slow_active:
		return
	slow_active = true
	speed *= multiplier
	await get_tree().create_timer(duration).timeout
	speed /= multiplier
	slow_active = false
