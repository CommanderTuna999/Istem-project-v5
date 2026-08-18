#everyone will look at this script eventually so important info:
#Layer 1 = Player
#Layer 2 = Walls
#Layer 3 = HarpoonProjectile
#Layer 11 = Enemies hurtbox

extends CharacterBody2D
var speed = 750
var injured_speed = 150
var damage_occuring = false
var aggro = false
var chase_subject = null
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
var current_health = 10
var kbtime = 0.0
var kbvelocity = Vector2.ZERO
var rooted: bool = false
var root_timer: float = 0.0
	
#func _ready() -> void:
#		animated_sprite_2d.play("idle")
func _process(_delta): #x axis flipping for now
	
	if not chase_subject == null and chase_subject.position.x > position.x:
		animated_sprite_2d.flip_h = false
	elif not chase_subject == null and chase_subject.position.x < position.x:
		animated_sprite_2d.flip_h = true
	
	
	if current_health <= 0:
		queue_free()

	if rooted:
		return
		
	if kbtime > 0:
		kbtime 	-= _delta
		velocity = kbvelocity
		move_and_slide()
		return
		
		
func _on_aggro_area_body_entered(body):
	chase_subject = body
	aggro = true
	#animated_sprite_2d.play("aggro")
	print('entered')
	
	
	
func _on_aggro_area_body_exited(_body: Node2D) -> void:
	chase_subject = null
	aggro = false
#	animated_sprite_2d.play("idle")
	print("exited")



func _physics_process(_delta):
	if rooted:
		root_timer -= _delta
		velocity = Vector2.ZERO
		move_and_slide()
		if root_timer <= 0.0:
			rooted = false
		return
	if aggro and chase_subject:
		if current_health >= 8:
			velocity = (chase_subject.global_position - global_position).normalized() * speed
		elif current_health < 8:
			velocity = (chase_subject.global_position - global_position).normalized() * injured_speed
	else: 
		velocity = Vector2.ZERO
	move_and_slide()
	
	
#damage script below
func take_damage(amount: float):
	current_health -= amount
	animation_player.play("damaged")
	await get_tree().create_timer(0.1).timeout
	

# knockback script below
func take_kb(source_position: Vector2):
	var kbdirection = (global_position - source_position).normalized()
	kbvelocity = kbdirection * 600
	kbtime = 0.12

func set_rooted(duration: float) -> void:
	rooted = true
	root_timer = max(root_timer, duration)
#func _on_template_hurtbox_area_entered(area: Area2D) -> void:
	#var kbdirection = (global_position - area.global_position).normalized()
	#kbvelocity = kbdirection * 600
	#kbtime = 0.12




	
