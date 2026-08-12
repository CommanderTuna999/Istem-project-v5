extends AnimationPlayer
@onready var animation_player: AnimationPlayer = $"."
@onready var sprite_2d: Sprite2D = $"../Sprite2D"
var direction = "right"
@onready var weapon: Node2D = $".."

func _ready() -> void:
	animation_player.play("RESET_right")


func _process(delta):
	#print(direction)
	if Input.is_action_just_pressed("left_click") and direction == "right":
		animation_player.play("slash_right")
	elif Input.is_action_just_pressed("left_click") and direction == "left":
			animation_player.play("slash_left")
	if Input.is_action_just_pressed("Left"):
		direction = "left"
		weapon.scale.x = -abs(weapon.scale.x)
		animation_player.play("RESET_left")
	if Input.is_action_just_pressed("Right"):
		direction = "right"
		weapon.scale = abs(weapon.scale)
		animation_player.play("RESET_right")
		
