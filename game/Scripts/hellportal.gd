extends Node2D

const LightningBoltScript = preload ("res://Scripts/portal_lightning.gd")

@export var lightning_spawn_interval = 0.15
@export var lightning_bolts_per_burst = 3
var lightning_timer = 0.0
var lightning_active = false

@export var grow_duration = 0.4
@export var target_scale = 5.0
@export var start_scale = 0.0
@export var lifetime = 2.0
@export var shrink_duration = 0.4

@onready var sprite: Sprite2D = $Sprite2D
@onready var particles: GPUParticles2D = $GPUParticles2D

func _ready() -> void:
	sprite.scale = Vector2.ONE * start_scale
	particles.one_shot = false
	particles.emitting = false

	var tween = create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(sprite, "scale", Vector2.ONE * target_scale, grow_duration)
	tween.tween_callback(start_particles)
	tween.tween_interval(lifetime)
	tween.tween_callback(shrink_and_free)
	
func _process(delta: float) -> void:
	if not lightning_active:
		return
	lightning_timer -= delta
	if lightning_timer <= 0.0:
		lightning_timer = lightning_spawn_interval
		for i in range(lightning_bolts_per_burst):
			spawn_lightning_bolt()

func spawn_lightning_bolt() -> void:
	var bolt = Line2D.new()
	bolt.set_script(LightningBoltScript)
	bolt.position = sprite.position
	add_child(bolt)

func start_particles() -> void:
	particles.emitting = true
	lightning_active = true

func shrink_and_free() -> void:
	particles.emitting = false
	lightning_active = false
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(sprite, "scale", Vector2.ONE * start_scale, shrink_duration)
	tween.tween_callback(queue_free)
