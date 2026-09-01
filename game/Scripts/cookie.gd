extends Node

signal cookie_boost_requested(speed_bonus: float, damage_bonus: float, passive_heal_bonus: float, duration: float)

var cookie_on_cooldown: bool = false

#@export var cookie_eat_sound: AudioStream
@onready var cookie_audio_player: AudioStreamPlayer = $cookie_audio_player

func _ready() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player and player.has_method("apply_cookie_boost"):
		cookie_boost_requested.connect(player.apply_cookie_boost)


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("Ability") and not cookie_on_cooldown:
		if AbilityFolder.ability == "Cookie":
			if not AbilityFolder.is_typing:
				trigger_cookie_boost()


func trigger_cookie_boost() -> void:
	if cookie_on_cooldown:
		return
	if cookie_audio_player != null:
		cookie_audio_player.play()

	cookie_on_cooldown = true
	cookie_boost_requested.emit(0.2, 0.2, 0.03, 10.0)
	print("Cookie boost emitted")
	await get_tree().create_timer(1.0).timeout
	cookie_on_cooldown = false
