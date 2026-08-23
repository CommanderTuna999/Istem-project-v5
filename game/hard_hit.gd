extends Node
@export var damage_multiplier: float = 2.0
@export var freeze_duration: float = 2.0
@export var knockback_window: float = 0.12
@export var cooldown: float = 1.0

var hard_hit_active: bool = false
var hard_hit_cooldown: bool = false

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("Ability") and AbilityFolder.ability == "Hard_Hit":
		if not hard_hit_active and not hard_hit_cooldown:
			activate_hard_hit()

func activate_hard_hit() -> void:
	hard_hit_active = true


func consume_hard_hit() -> float:
	if not hard_hit_active:
		return 1.0

	hard_hit_active = false
	hard_hit_cooldown = true
	start_cooldown()
	return damage_multiplier


func freeze_enemy_after_knockback(enemy: Node2D) -> void:
	if enemy == null or not is_instance_valid(enemy):
		return

	await get_tree().create_timer(knockback_window).timeout
	if is_instance_valid(enemy) and enemy.has_method("set_rooted"):
		enemy.set_rooted(freeze_duration)


func start_cooldown() -> void:
	await get_tree().create_timer(cooldown).timeout
	hard_hit_cooldown = false
