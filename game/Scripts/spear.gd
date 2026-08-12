extends Node2D

@onready var animated_sprite_2d: AnimatedSprite2D = $AttackPivot/AnimatedSprite2D


var direction = "right"
var restside = "right"
var attacking:= false
var mouse_pos := Vector2.ZERO
var direction_to_mouse := Vector2.ZERO
const winduptime = 0.05
const attacktime := 0.1
const attackcooldown := 0.25
const spearoffset := 20
const handoffset := 8
@onready var attackpivot = $AttackPivot
@onready var spearsprite = $AttackPivot/AnimatedSprite2D
@onready var hitboxshape = $AttackPivot/TemplateHitbox/CollisionShape2D
func _ready() -> void:
	animated_sprite_2d.frame = 0
	attackpivot.position = Vector2(handoffset, 0)
	hitboxshape.disabled = true
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("left_click") and not attacking:
		mouse_pos = get_global_mouse_position()
		direction_to_mouse = (mouse_pos - global_position).normalized()
		#if abs(direction_to_mouse.x) > abs(direction_to_mouse.y):
			#if direction_to_mouse.x >= 0:
				#direction = "right"
				#get_parent().forcefaceside("right")
				#restside = "right"
			#else:
				#direction = "left"
				#get_parent().forcefaceside("left")
				#restside = "left"
		#else:
			#if direction_to_mouse.y >= 0:
				#direction = "down"
			#else:
				#direction = "up"
		attack()
		

func attack():
	attacking = true
	get_parent().facinglocked = true
	#match direction:
		#"right":
			#$AttackPivot.position = Vector2(spearoffset, 0)
			#$AttackPivot.rotation = deg_to_rad(0)
		#"left":
			#$AttackPivot.position = Vector2(-spearoffset, 0)
			#$AttackPivot.rotation = deg_to_rad(180)
		#"up":
			#$AttackPivot.position = Vector2(0,-spearoffset)
			#$AttackPivot.rotation = deg_to_rad(-90)
		#"down":
			#$AttackPivot.position = Vector2(0, spearoffset)
			#$AttackPivot.rotation = deg_to_rad(90)
			#no match direction instead follow mouse
	$AttackPivot.position = direction_to_mouse * spearoffset
	$AttackPivot.rotation = direction_to_mouse.angle()
	await get_tree().create_timer(winduptime).timeout
	$AttackPivot/AnimatedSprite2D.play("thrust")
	$AttackPivot/TemplateHitbox/CollisionShape2D.disabled = false
	await get_tree().create_timer(attacktime).timeout
	hitboxshape.disabled = true
	await get_tree().create_timer(attackcooldown).timeout
	returntorest()
	get_parent().facinglocked = false
	attacking = false
	
func returntorest():
	if restside == "right":
		attackpivot.position = Vector2(handoffset, 0)
		attackpivot.rotation = deg_to_rad(0)
	else:
		attackpivot.position = Vector2(-handoffset, 0)
		attackpivot.rotation = deg_to_rad(180)
		
		
func setrestside(newside: String):
	if attacking:
		return
	
	restside = newside
	returntorest()

func successful_hit(hurtbox: TemplateHurtbox) -> void:
	get_parent().on_spear_hit(hurtbox)
	
func _on_body_entered(body):
	print("entered")
	get_parent().setcanbounce(true)
	
func _on_body_exited(body):
	get_parent().setcanbounce(false)
