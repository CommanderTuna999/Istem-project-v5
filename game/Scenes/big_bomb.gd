extends Node

# Assign your Bomb projectile scene (the one with bomb_projectile.gd attached) in the inspector
@export var bomb_scene: PackedScene

@export var search_radius: float = 800.0
@export var throw_distance_ratio: float = 0.8  # lands 80% of the way to the enemy
@export var cooldown: float = 1.0  # testing value, per your request


var on_cooldown: bool = false


func _process(delta: float) -> void:
	if Input.is_action_just_pressed("Ability") and AbilityFolder.ability == "Bomb" and not on_cooldown:
		throw_bomb()


func throw_bomb() -> void:
	var player := get_tree().get_first_node_in_group("player") as CharacterBody2D
	if player == null:
		return

	var target := find_nearest_enemy(player.global_position)
	if target == null:
		return

	on_cooldown = true

	var distance := player.global_position.distance_to(target.global_position)
	var direction := player.global_position.direction_to(target.global_position)
	if direction == Vector2.ZERO:
		direction = Vector2.RIGHT

	# Lands ~80% of the way there, so slightly in front of the enemy
	var landing_position := player.global_position + direction * (distance * throw_distance_ratio)

	var bomb := bomb_scene.instantiate()
	get_tree().current_scene.add_child(bomb)
	bomb.global_position = player.global_position
	bomb.launch(landing_position)

	await get_tree().create_timer(cooldown).timeout
	on_cooldown = false


func find_nearest_enemy(from_position: Vector2) -> Node2D:
	var nearest: Node2D
	var nearest_distance := search_radius * search_radius
	for possible_enemy in get_tree().get_nodes_in_group("enemy"):
		var enemy := possible_enemy as Node2D
		if enemy == null or not is_instance_valid(enemy):
			continue
		var d := from_position.distance_squared_to(enemy.global_position)
		if d <= nearest_distance:
			nearest = enemy
			nearest_distance = d
	return nearest
