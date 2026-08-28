extends Node

@export var petal_projectile_scene: PackedScene = preload("res://Scenes/petal_projectile.tscn")
@export var startup_delay: float = 0.1
@export var shot_count: int = 3
@export var shot_interval: float = 0.35
@export var cooldown: float = 1.0

var is_casting: bool = false
var on_cooldown: bool = false

@onready var petal_audio_player: AudioStreamPlayer = $"/root/Game/AbilityFolder/Petals/petal_audio_player"

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("Ability"):
		if AbilityFolder.ability == "Petals" and not is_casting and not on_cooldown:
			if not AbilityFolder.is_typing:
				cast_petals()


func cast_petals() -> void:
	is_casting = true

	await get_tree().create_timer(startup_delay).timeout

	for shot_index in range(shot_count):
		fire_petal(shot_index)
		if petal_audio_player != null:
			petal_audio_player.pitch_scale = 0.65
			petal_audio_player.play()

		if shot_index < shot_count - 1:
			await get_tree().create_timer(shot_interval).timeout

	is_casting = false
	on_cooldown = true
	await get_tree().create_timer(cooldown).timeout
	on_cooldown = false


func fire_petal(shot_index: int) -> void:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return

	var petal := petal_projectile_scene.instantiate() as Node2D
	if petal == null:
		return

	petal.global_position = player.global_position
	get_tree().current_scene.add_child(petal)

	if petal.has_method("setup"):
		petal.setup(player, shot_index)
