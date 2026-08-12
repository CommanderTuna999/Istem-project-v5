#everyone will look at this script eventually so important info:
#Layer 1 = Player
#Layer 2 = Walls
#Layer 3 = HarpoonProjectile
#Layer 11 = Enemies hurtbox

extends CharacterBody2D
var speed = 200
var damage_occuring = false
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
var current_health = 6
@onready var ray_cast_left: RayCast2D = $RayCastLeft
@onready var ray_cast_right: RayCast2D = $RayCastRight
var direction = 1



func _process(_delta):


	if current_health <= 0:
		queue_free()
	





func _physics_process(_delta):
	if ray_cast_left.is_colliding():
		direction = 1
	if ray_cast_right.is_colliding():
		direction = -1
	position.x += direction * speed * _delta
	move_and_slide()

	
#damage script below
func take_damage(amount: int):
	current_health -= amount
	animation_player.play("damaged")
	await get_tree().create_timer(0.1).timeout
	

	
