extends Node
@export var hard_hit_active = false
@export var hard_hit_cooldown = false

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("Ability"):
		if AbilityFolder.ability == "hardhit":
			if not hard_hit_active and not hard_hit_cooldown:
				activate_hard_hit()

func activate_hard_hit() -> void:
	return
