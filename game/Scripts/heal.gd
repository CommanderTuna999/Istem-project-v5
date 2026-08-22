extends Node

@onready var player = get_tree().get_first_node_in_group("player")
@onready var heal_audio_player: AudioStreamPlayer = $"/root/Game/AbilityFolder/Heal/heal_audio_player"

var heal_cooldown = false

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("Ability"):
		if AbilityFolder.ability == "Heal":
			if not heal_cooldown:
				heal()

func heal() -> void:
	heal_cooldown = true
	var lost_health = player.max_health - player.current_health
	player.current_health += lost_health * 0.5
	heal_audio_player.pitch_scale = 1.5
	heal_audio_player.play()
	await get_tree().create_timer(1.0).timeout
	heal_cooldown = false
