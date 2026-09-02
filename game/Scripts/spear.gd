extends Node2D

@onready var animated_sprite_2d: AnimatedSprite2D = $AttackPivot/AnimatedSprite2D
@onready var slash_sound_player: AudioStreamPlayer = $slash_sound_player
@onready var hit_effect = preload("res://hit_effect.tscn")
var direction = "right"
var restside = "right"
var attacking := false

# Stops one attack from wall-parrying multiple times.
var bounced_this_attack := false

# True only during the short period where a wall parry is allowed.
var wall_parry_active := false

var mouse_pos := Vector2.ZERO
var direction_to_mouse := Vector2.ZERO
var hard_hit_damage_multiplier: float = 1.0

const winduptime = 0.05
const attacktime := 0.18
const attackcooldown := 0.25
const spearoffset := 50
const handoffset := 8

# How far ahead of the player the ray searches for a wall.
const wall_parry_ray_length := 110.0

@onready var attackpivot = $AttackPivot
@onready var spearsprite = $AttackPivot/AnimatedSprite2D
@onready var hitboxshape = $AttackPivot/TemplateHitbox/CollisionShape2D


func _ready() -> void:
	animated_sprite_2d.frame = 0
	animated_sprite_2d.visible = false

	attackpivot.position = Vector2(handoffset, 0)
	hitboxshape.disabled = true


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("left_click") and not attacking:
		mouse_pos = get_global_mouse_position()

		direction_to_mouse = (
			mouse_pos - global_position
		).normalized()

		attack()


func _physics_process(_delta: float) -> void:
	# Instead of requiring one exact Area/body-entered frame,
	# repeatedly check for a wall while the visible attack is active.
	if wall_parry_active and not bounced_this_attack:
		check_for_wall_parry()


func attack():
	attacking = true
	bounced_this_attack = false
	wall_parry_active = false

	get_parent().facinglocked = true


	var hard_hit := get_node_or_null("/root/Game/AbilityFolder/HardHit")

	if hard_hit != null and hard_hit.has_method("consume_hard_hit"):
		hard_hit_damage_multiplier = hard_hit.consume_hard_hit()
		$AttackPivot/TemplateHitbox.damage *= hard_hit_damage_multiplier


	var random_pitch = randf_range(1.313, 1.687)

	slash_sound_player.pitch_scale = random_pitch
	slash_sound_player.play()


	# Aim toward the mouse.
	attackpivot.position = direction_to_mouse * spearoffset
	attackpivot.rotation = direction_to_mouse.angle()


	# Tiny windup while still invisible.
	await get_tree().create_timer(winduptime).timeout


	# ATTACK APPEARS.
	animated_sprite_2d.stop()
	animated_sprite_2d.frame = 0
	animated_sprite_2d.frame_progress = 0.0
	animated_sprite_2d.visible = true
	animated_sprite_2d.play("thrust")

	hitboxshape.disabled = false

	# Wall parrying is now allowed for the full visible attack window.
	wall_parry_active = true


	await get_tree().create_timer(attacktime).timeout


	# ATTACK DISAPPEARS.
	wall_parry_active = false
	hitboxshape.disabled = true
	animated_sprite_2d.visible = false


	$AttackPivot/TemplateHitbox.damage /= hard_hit_damage_multiplier
	hard_hit_damage_multiplier = 1.0


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

	if hard_hit_damage_multiplier > 1.0:
		var hard_hit := get_node_or_null("/root/Game/AbilityFolder/HardHit")

		if hard_hit != null and hard_hit.has_method("freeze_enemy_after_knockback"):
			hard_hit.freeze_enemy_after_knockback(
				hurtbox.owner as Node2D
			)


# Checks whether the spear currently appears to be striking a wall.
func check_for_wall_parry() -> void:
	var space_state := get_world_2d().direct_space_state

	var ray_start := global_position

	var ray_end := (
		global_position
		+ direction_to_mouse * wall_parry_ray_length
	)


	var query := PhysicsRayQueryParameters2D.create(
		ray_start,
		ray_end
	)

	# Layer 2 = Walls
	query.collision_mask = 2


	var result := space_state.intersect_ray(query)

	if result.is_empty():
		return


	var wall_normal: Vector2 = result["normal"]
	var hit_position: Vector2 = result["position"]
	
	spawn_hit_effect(hit_position - wall_normal * 4.0)


	bounced_this_attack = true

	get_parent().spear_wall_bounce(
		wall_normal,	
		hit_position,
		direction_to_mouse
	)


# We don't need body_entered to decide wall parries anymore.
func _on_body_entered(_body):
	pass


func _on_body_exited(_body):
	pass


# --- ShadowFury ability support -------------------------------------------

func ability_point_and_thrust(target_position: Vector2) -> void:
	attacking = true
	bounced_this_attack = false
	wall_parry_active = false

	get_parent().facinglocked = true

	direction_to_mouse = (
		target_position - global_position
	).normalized()

	attackpivot.position = direction_to_mouse * spearoffset
	attackpivot.rotation = direction_to_mouse.angle()

	animated_sprite_2d.visible = true
	animated_sprite_2d.play("thrust")


func ability_finish() -> void:
	wall_parry_active = false
	animated_sprite_2d.visible = false

	returntorest()

	get_parent().facinglocked = false
	attacking = false
	
	#Hit effect at position
func spawn_hit_effect(hit_position: Vector2) -> void:
	var effect = hit_effect.instantiate()

	get_tree().current_scene.add_child(effect)

	effect.global_position = hit_position
