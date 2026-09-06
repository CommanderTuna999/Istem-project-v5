extends Node2D

@export var travel_time: float = 0.5
@export var grow_time: float = 0.25
@export var flash_hold_time: float = 0.15
@export var fade_time: float = 0.6
@export var damage: float = 20.0
@export var stun_duration: float = 1.2

var target_position: Vector2 = Vector2.ZERO

@onready var animation: AnimatedSprite2D = $AnimatedSprite2D
@onready var strike_area: Area2D = $StrikeArea


func _ready() -> void:
	animation.play("dragging")
	var move_tween := create_tween()
	move_tween.tween_property(self, "global_position", target_position, travel_time)
	await move_tween.finished

	animation.play("growth")
	await get_tree().create_timer(grow_time).timeout
	animation.play("flashing")
	strike()


func strike() -> void:
	animation.modulate = Color(3.0, 3.0, 3.0, 1.0)

	for body in strike_area.get_overlapping_bodies():
		if body.is_in_group("player"):
			if body.has_method("take_player_damage"):
				body.take_player_damage(damage)
			if body.has_method("camera_stun"):
				body.camera_stun(stun_duration)

	await get_tree().create_timer(flash_hold_time).timeout

	var fade_tween := create_tween()
	fade_tween.tween_property(animation, "modulate:a", 0.0, fade_time)
	await fade_tween.finished
	queue_free()
