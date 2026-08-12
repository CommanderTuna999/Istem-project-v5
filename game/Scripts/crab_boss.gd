#everyone will look at this script eventually so important info:
#Layer 1 = Player
#Layer 2 = Walls
#Layer 3 = HarpoonProjectile
#Layer 11 = Enemies hurtbox

extends CharacterBody2D
var dash_speed = 2000
var dashing = false
var damage_occuring = false
var aggro = false
var chase_subject = null
var currently_attacking = false
var attack_number = null
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
var current_health = 200
var kbtime = 0.0
var kbvelocity = Vector2.ZERO
@onready var damage_number_template: damage_number_template = $damage_number_template
@onready var attack_timer: Timer = $"attack timer"

	
func _ready() -> void:
		animated_sprite_2d.play("idle")
func _process(_delta): #x axis flipping for now
	
	
	if current_health <= 0:
		queue_free()
		
		
func _on_aggro_area_body_entered(body):
	chase_subject = body
	aggro = true
	animated_sprite_2d.play("aggro")
	print('entered')
	
	
	



func _physics_process(_delta):
	if chase_subject and attack_timer.is_stopped():
		attack_number = randi_range(1, 4)
		currently_attacking = true
		choose_attack(attack_number)
		print("returning")
		attack_timer.start()
	
	if dashing:
		move_and_slide()
		return
		

func choose_attack(number):
	if currently_attacking == true:
		if number == 1:
			dash()
		if number == 2:
			smash()
		if number == 3:
			sweep()
		if number == 4:
			jump()
		
		

func sweep():
	print("sweep")


func jump():
	print("jump")
	

func smash():
	print("smash")


func dash():
	dashing = true
	print(rotation_degrees)
	print("dash")
	print(chase_subject)
	var player_pos = chase_subject.global_position
	await get_tree().create_timer(2).timeout
	rotation_degrees = 0.0
	velocity = (player_pos - global_position).normalized() * 700
	await get_tree().create_timer(1).timeout
	velocity = Vector2.ZERO
	currently_attacking = false
	
	
#damage script below
func take_damage(amount: int):
	current_health -= amount
	animation_player.play("damaged")
	damage_number_template.spawn_label(amount, false)
	await get_tree().create_timer(0.1).timeout
	

# knockback script below


	
