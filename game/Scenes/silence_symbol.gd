extends Sprite2D

@onready var player: CharacterBody2D = get_parent()

func _ready() -> void:
	visible = false

func _process(delta) -> void:
	if is_instance_valid(player):
		if player.is_silenced == true:
			visible = true
		else:
			visible = false
