extends Node

@export var search_radius: float = 600.0
@export var teleport_distance: float = 40.0
@export var explosion_radius: float = 90.0
@export var base_damage: float = 0.5
@export var knockback_strength: float = 1200.0
@export var shield_restore: float = 7.5
@export var health_restore: float = 5.0
@export var health_restore_delay: float = 3.0
@export var cooldown: float = 0.01

@export var mana_cost: float = 10.0
@export var max_mana: float = 100.0
@export var current_mana: float = 100.0
@export var mana_regeneration: float = 2.5

@export var teleport_symbol_texture: Texture2D
@export var teleport_symbol_scale: float = 0.045
@export var teleport_symbol_lifetime: float = 0.8
@export var teleport_symbol_growth: float = 1.25
@export var teleport_symbol_spin_turns: float = 1.5

@onready var mana_bar = %ManaBar

var on_cooldown: bool = false
var teleport_symbol_active: bool = false

func update_mana_bar() -> void:
	mana_bar.max_value = max_mana
	mana_bar.value = current_mana

func _ready() -> void:
	update_mana_bar()

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("Ability") and AbilityFolder.ability == "Tsunami_Impact" and not on_cooldown:
		if current_mana > 9.99:
			activate_tsunami_impact()
	if current_mana < max_mana:
		current_mana += mana_regeneration * delta
		current_mana = min(current_mana, max_mana)
		update_mana_bar()


func activate_tsunami_impact() -> void:
	var player := get_tree().get_first_node_in_group("player") as CharacterBody2D
	if player == null:
		return

	var target := find_nearest_enemy(player.global_position)
	if target == null:
		return

	on_cooldown = true
	var departure_position := player.global_position
	var approach_direction := player.global_position.direction_to(target.global_position)
	if approach_direction == Vector2.ZERO:
		approach_direction = Vector2.RIGHT
	player.global_position = target.global_position - approach_direction * teleport_distance
	player.velocity = Vector2.ZERO

	spawn_teleport_symbol(departure_position)
	explode(player)
	spawn_explosion_flash(player.global_position)
	restore_shield(player)
	restore_health_later(player)

	await get_tree().create_timer(cooldown).timeout
	on_cooldown = false


func find_nearest_enemy(from_position: Vector2) -> Node2D:
	var nearest: Node2D
	var nearest_distance := search_radius * search_radius
	for possible_enemy in get_tree().get_nodes_in_group("enemy"):
		var enemy := possible_enemy as Node2D
		if enemy == null or not is_instance_valid(enemy) or not enemy.has_method("take_damage"):
			continue
		var distance := from_position.distance_squared_to(enemy.global_position)
		if distance <= nearest_distance:
			nearest = enemy
			nearest_distance = distance
	return nearest


func explode(player: CharacterBody2D) -> void:
	current_mana -= mana_cost
	update_mana_bar()
	var damage_multiplier := float(player.total_damage_increase)
	for possible_enemy in get_tree().get_nodes_in_group("enemy"):
		var enemy := possible_enemy as Node2D
		if enemy == null or not is_instance_valid(enemy):
			continue
		if player.global_position.distance_to(enemy.global_position) > explosion_radius:
			continue
		if enemy.has_method("take_damage"):
			enemy.take_damage(base_damage * damage_multiplier)
		if enemy.has_method("take_kb"):
			enemy.take_kb(player.global_position)
			var knockback_direction := player.global_position.direction_to(enemy.global_position)
			if knockback_direction == Vector2.ZERO:
				knockback_direction = Vector2.RIGHT
			if enemy.get("kbvelocity") != null:
				enemy.set("kbvelocity", knockback_direction * knockback_strength)
			if enemy.get("kbtime") != null:
				enemy.set("kbtime", 0.22)


func restore_shield(player: CharacterBody2D) -> void:
	player.shield_health = minf(player.shield_health + shield_restore, player.shield_max_health)
	player.update_shield_bar()


func spawn_explosion_flash(position: Vector2) -> void:
	var flash := Polygon2D.new()
	var points := PackedVector2Array()
	var segments: int = 20
	for index in range(segments):
		var angle := TAU * float(index) / float(segments)
		points.append(Vector2(cos(angle), sin(angle)) * explosion_radius)

	flash.polygon = points
	flash.color = Color(1.0, 1.0, 1.0, 0.9)
	flash.global_position = position
	flash.z_index = 10
	get_tree().current_scene.add_child(flash)

	var flash_tween := flash.create_tween()
	flash_tween.tween_property(flash, "modulate:a", 0.0, 0.22)
	await flash_tween.finished
	flash.queue_free()


func spawn_teleport_symbol(position: Vector2) -> void:
	if teleport_symbol_active or teleport_symbol_texture == null:
		return

	teleport_symbol_active = true
	var symbol := Sprite2D.new()
	symbol.texture = teleport_symbol_texture
	symbol.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	symbol.global_position = position
	symbol.scale = Vector2.ONE * teleport_symbol_scale
	symbol.z_index = 9
	get_tree().current_scene.add_child(symbol)

	var symbol_tween := symbol.create_tween().set_parallel(true)
	symbol_tween.tween_property(symbol, "modulate:a", 0.0, teleport_symbol_lifetime)
	symbol_tween.tween_property(symbol, "scale", Vector2.ONE * teleport_symbol_scale * teleport_symbol_growth, teleport_symbol_lifetime)
	symbol_tween.tween_property(symbol, "rotation", TAU * teleport_symbol_spin_turns, teleport_symbol_lifetime)
	await symbol_tween.finished
	if is_instance_valid(symbol):
		symbol.queue_free()
	teleport_symbol_active = false


func restore_health_later(player: CharacterBody2D) -> void:
	await get_tree().create_timer(health_restore_delay).timeout
	if not is_instance_valid(player):
		return
	player.current_health = minf(player.current_health + health_restore, player.max_health)
	player.update_health_ui(0.0)
