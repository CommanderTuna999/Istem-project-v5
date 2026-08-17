extends Area2D

@export var speed: float = 1500.0
@export var base_damage: float = 0.5
@export var damage_multiplier: float = 1.0
@export var bonus_flat_damage: float = 0.0
@export var max_bounces: int = 3
@export var hit_distance: float = 12.0
@export var retarget_delay: float = 0.08
@export var lifetime: float = 6.0
@export var max_travel_distance: float = 1200.0
@export var spin_speed: float = 24.0

var caster: Node2D = null
var current_target: Node2D = null
var hit_enemies: Array[Node2D] = []
var bounces_used: int = 0
var can_hit: bool = true
var travel_distance: float = 0.0

var damage: float:
	get:
		return (base_damage + bonus_flat_damage) * damage_multiplier * (1.0 + PetalStats.bonus_damage)


func _ready() -> void:
	get_tree().create_timer(lifetime).timeout.connect(queue_free)

	if current_target == null:
		current_target = find_nearest_enemy(global_position)

	if current_target == null:
		queue_free()


func setup(new_caster: Node2D, shot_index: int = 0) -> void:
	caster = new_caster

	var spread_offset := Vector2(0, (shot_index - 1) * 10)
	global_position += spread_offset
	current_target = find_nearest_enemy(global_position)


func _physics_process(delta: float) -> void:
	if current_target == null or not is_instance_valid(current_target):
		current_target = find_nearest_enemy(global_position)
		if current_target == null:
			queue_free()
			return

	var target_position := current_target.global_position
	var direction := global_position.direction_to(target_position)
	var movement := direction * speed * delta
	global_position += movement
	rotation = direction.angle()
	$Sprite2D.rotation += spin_speed * delta

	travel_distance += movement.length()
	if travel_distance >= max_travel_distance:
		queue_free()
		return

	if global_position.distance_to(target_position) <= hit_distance:
		hit_enemy(current_target)


func hit_enemy(enemy: Node2D) -> void:
	if not can_hit:
		return

	if enemy == null or not is_instance_valid(enemy):
		return

	if hit_enemies.has(enemy):
		return

	can_hit = false
	hit_enemies.append(enemy)
	var bounce_position := enemy.global_position

	if enemy.has_method("take_damage"):
		enemy.take_damage(damage)

	if enemy.has_method("take_kb"):
		enemy.take_kb(global_position)

	if bounces_used >= max_bounces:
		queue_free()
		return

	bounces_used += 1
	await get_tree().create_timer(retarget_delay).timeout

	current_target = find_nearest_enemy(bounce_position)
	if current_target == null:
		queue_free()
		return

	can_hit = true


func find_nearest_enemy(from_position: Vector2) -> Node2D:
	var closest_distance := INF
	var closest_enemies: Array[Node2D] = []

	for possible_enemy in get_tree().get_nodes_in_group("enemy"):
		var enemy := possible_enemy as Node2D
		if enemy == null:
			continue
		if not is_instance_valid(enemy):
			continue
		if hit_enemies.has(enemy):
			continue
		if not enemy.has_method("take_damage"):
			continue

		var distance := from_position.distance_squared_to(enemy.global_position)
		if is_equal_approx(distance, closest_distance):
			closest_enemies.append(enemy)
		elif distance < closest_distance:
			closest_distance = distance
			closest_enemies = [enemy]

	if closest_enemies.is_empty():
		return null

	return closest_enemies.pick_random()
