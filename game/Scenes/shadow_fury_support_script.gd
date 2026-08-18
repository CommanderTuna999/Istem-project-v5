extends Node

@onready var shadowfury_ability_active = false

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("Ability"):
		if AbilityFolder.ability == "ShadowFury":
			shadowfury_ability_active = true
			await get_tree().create_timer(3.0).timeout
			shadowfury_ability_active = false
