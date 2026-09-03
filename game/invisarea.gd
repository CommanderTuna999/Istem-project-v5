extends Area2D

@onready var animated_sprite_2d = $AnimatedSprite2D

func _ready():
	animated_sprite_2d.play("idle") 

func _on_body_entered(body: Node2D):
	if body.is_in_group("enemy"):
		body.modulate.a = 0.5
