class_name TemplateHitbox
extends Area2D
@export var damage = 1
@onready var player = get_parent().get_parent().get_parent()


func _init() -> void:
	collision_layer = 1024 #11
	collision_mask = 2

func _process(delta: float) -> void:
	if player.velocity.length() >= 1000 and player.highmode:
		damage * 1.5
