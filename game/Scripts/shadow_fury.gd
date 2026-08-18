extends Node

@export var search_radius: float = 1000.0
@export var behind_distance: float = 22.0
@export var teleport_delay: float = 0.5  # time before teleporting to the next enemy
@export var slash_gap: float = 0.08      # time after the hit, before the next teleport starts
@export var cooldown: float = 1.0
@export var root_duration_buffer: float = 0.35
@export var damage_multiplier: float = 1.25

var on_cooldown: bool = false
var executing: bool = false


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("Ability"):
		if AbilityFolder.ability == "ShadowFury":
			execute_chain()


func execute_chain() -> void:
	var player := get_tree().get_first_node_in_group("player") as CharacterBody2D
	if player == null:
		return

	var targets := get_targets_in_range(player.global_position)
	if targets.is_empty():
		return

	# Reference to the player's spear so we can aim + animate it per hit.
	var spear := player.get_node_or_null("Spear")

	executing = true
	on_cooldown = true

	var origin_position := player.global_position
	var origin_velocity := player.velocity
	var original_invincible: bool = player.invincible
	var base_damage := compute_base_damage(player)

	# Each target now costs teleport_delay (travel) + slash_gap (post-hit pause)
	var total_root_duration := (targets.size() * (teleport_delay + slash_gap)) + root_duration_buffer
	var remaining_targets: Array[Node2D] = targets.duplicate()
	var current_position := origin_position

	player.velocity = Vector2.ZERO
	player.invincible = true
	root_targets(targets, total_root_duration)

	while not remaining_targets.is_empty():
		var target := pick_closest_target(current_position, remaining_targets)
		if target == null:
			break

		remaining_targets.erase(target)
		if not is_instance_valid(target):
			continue

		# Wait before teleporting so the jump to this enemy is visible
		await get_tree().create_timer(teleport_delay).timeout

		if not is_instance_valid(target):
			continue

		player.global_position = get_behind_position(player.global_position, target)

		if spear != null and spear.has_method("ability_point_and_thrust"):
			spear.ability_point_and_thrust(target.global_position)

		play_enemy_hit_animation(target)

		if target.has_method("take_damage"):
			target.take_damage(base_damage * damage_multiplier)

		if target.has_method("take_kb"):
			target.take_kb(player.global_position)

		current_position = player.global_position
		await get_tree().create_timer(slash_gap).timeout

	if spear != null and spear.has_method("ability_finish"):
		spear.ability_finish()

	player.global_position = origin_position
	player.velocity = origin_velocity
	player.invincible = original_invincible
	executing = false

	await get_tree().create_timer(cooldown).timeout
	on_cooldown = false


func get_targets_in_range(from_position: Vector2) -> Array[Node2D]:
	var targets: Array[Node2D] = []

	for candidate in get_tree().get_nodes_in_group("enemy"):
		var enemy := candidate as Node2D
		if enemy == null:
			continue
		if not is_instance_valid(enemy):
			continue
		if from_position.distance_to(enemy.global_position) <= search_radius:
			targets.append(enemy)

	return targets


func root_targets(targets: Array[Node2D], duration: float) -> void:
	for enemy in targets:
		if enemy == null or not is_instance_valid(enemy):
			continue
		if enemy.has_method("set_rooted"):
			enemy.set_rooted(duration)


func pick_closest_target(from_position: Vector2, targets: Array[Node2D]) -> Node2D:
	var closest_distance := INF
	var closest_targets: Array[Node2D] = []

	for enemy in targets:
		if enemy == null or not is_instance_valid(enemy):
			continue
		var distance := from_position.distance_squared_to(enemy.global_position)
		if is_equal_approx(distance, closest_distance):
			closest_targets.append(enemy)
		elif distance < closest_distance:
			closest_distance = distance
			closest_targets = [enemy]

	if closest_targets.is_empty():
		return null

	return closest_targets.pick_random()


func get_behind_position(from_position: Vector2, target: Node2D) -> Vector2:
	var behind_direction := Vector2.ZERO

	if target.has_method("get_facing_direction"):
		behind_direction = -target.get_facing_direction().normalized()
	else:
		var facing_value = target.get("facing_direction")
		if facing_value is Vector2 and facing_value != Vector2.ZERO:
			behind_direction = -facing_value.normalized()

	if behind_direction == Vector2.ZERO:
		behind_direction = (from_position - target.global_position).normalized()
		if behind_direction == Vector2.ZERO:
			behind_direction = Vector2.RIGHT

	return target.global_position + behind_direction * behind_distance


func compute_base_damage(player: CharacterBody2D) -> float:
	var hitbox := player.get_node_or_null("Spear/AttackPivot/TemplateHitbox") as TemplateHitbox
	if hitbox != null:
		return float(hitbox.damage) * float(player.total_damage_increase)

	return 1.0 * float(player.total_damage_increase)


func play_enemy_hit_animation(target: Node2D) -> void:
	var animation_player := target.get_node_or_null("AnimationPlayer") as AnimationPlayer
	if animation_player and animation_player.has_animation("damaged"):
		animation_player.play("damaged")
