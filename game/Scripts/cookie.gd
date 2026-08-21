extends Node

signal cookie_boost_requested(speed_bonus: float, damage_bonus: float, passive_heal_bonus: float, duration: float)

var cookie_on_cooldown: bool = false

func _ready() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player and player.has_method("apply_cookie_boost"):
		cookie_boost_requested.connect(player.apply_cookie_boost)


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("Ability"):
		if AbilityFolder.ability == "Cookie":
			trigger_cookie_boost()


func trigger_cookie_boost() -> void:
	if cookie_on_cooldown:
		return

	cookie_on_cooldown = true
	cookie_boost_requested.emit(0.2, 0.2, 0.03, 10.0)
	print("Cookie boost emitted")
	await get_tree().create_timer(1.0).timeout
	cookie_on_cooldown = false
