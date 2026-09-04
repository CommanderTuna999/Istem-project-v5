extends Area2D
var thrower = null
var buffed_enemies = []
@onready var splash_timer: Timer = $effectimer
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

@export var spawn_growth_duration = 0.2
@export var spawn_start_scale = 0.0
@export var spawn_target_scale = 0.2

func _init() -> void:
	monitoring = false
	collision_layer = 0
	collision_mask = 8

func _ready() -> void:
	visible = false
	await get_tree().create_timer(2.5).timeout
	sprite.play("potion")
	scale = Vector2(0.2, 0.2) * spawn_start_scale
	visible = true
	splash_timer.start(0.85)
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2.ONE * spawn_target_scale, spawn_growth_duration)

func _on_effectimer_timeout() -> void:
	monitoring = true
	sprite.play("ragesplash")
	scale = Vector2(1.0, 1.0)
	sprite.modulate.a = 0.75
	fade_out_and_free()
	if is_instance_valid(thrower):
		thrower.rage_level += 1
		thrower.recalculate_stats()
		revert_thrower_bonus_rage()

func fade_out_and_free() -> void:
	var tween = create_tween()
	tween.tween_interval(9.0)
	tween.tween_property(sprite, "modulate:a", 0.0, 0.6)
	tween.tween_callback(clear_all_buffs_and_free)

func clear_all_buffs_and_free() -> void:
	for enemy in buffed_enemies.duplicate():
		remove_buff(enemy)
	queue_free()
func revert_thrower_bonus_rage() -> void:
	await get_tree().create_timer(5.0).timeout
	if is_instance_valid(thrower):
		thrower.rage_level = max(0, thrower.rage_level - 1)
		thrower.recalculate_stats()
func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemy") and body != thrower:
		apply_buff(body)
func _on_body_exited(body: Node2D) -> void:
	if body in buffed_enemies:
		remove_buff(body)
func apply_buff(enemy: Node) -> void:
	buffed_enemies.append(enemy)
	if enemy.has_method("recalculate_stats") and "external_speed_multiplier" in enemy:
		enemy.external_speed_multiplier = 1.2
		enemy.external_aggro_multiplier = 1.15
		enemy.recalculate_stats()
	else:
		if "speed" in enemy:
			enemy.speed *= 1.2
		#if "aggro_radius" in enemy:
			#enemy.aggro_radius *= 1.15
func remove_buff(enemy: Node) -> void:
	buffed_enemies.erase(enemy)
	if not is_instance_valid(enemy):
		return
	if enemy.has_method("recalculate_stats") and "external_speed_multiplier" in enemy:
		enemy.external_speed_multiplier = 1.0
		enemy.external_aggro_multiplier = 1.0
		enemy.recalculate_stats()
	else:
		if "speed" in enemy:
			enemy.speed /= 1.2
		#if "aggro_radius" in enemy:
			#enemy.aggro_radius /= 1.15
