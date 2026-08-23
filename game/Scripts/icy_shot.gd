extends Node

@export var projectile_scene: PackedScene = preload("res://Scenes/icy_projectile.tscn")
@export var cooldown: float = 1.0

var on_cooldown: bool = false


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("Ability") and AbilityFolder.ability == "Icy_Shot" and not on_cooldown:
		fire_icy_shot()


func fire_icy_shot() -> void:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null or projectile_scene == null:
		return

	on_cooldown = true
	var projectile := projectile_scene.instantiate() as Node2D
	if projectile != null:
		projectile.global_position = player.global_position
		get_tree().current_scene.add_child(projectile)
		if projectile.has_method("setup"):
			projectile.setup(player, player.get_global_mouse_position() - player.global_position)

	await get_tree().create_timer(cooldown).timeout
	on_cooldown = false
