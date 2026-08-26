#everyone will look at this script eventually so important info:
#Layer 1 = Player
#Layer 2 = Walls
#Layer 3 = HarpoonProjectile
#Layer 4 = Enemy collision
#Layer 5 = Weapon
#Layer 6 = EnemyProjectile collision
#Layer 11 = Enemies hurtbox

extends CharacterBody2D
var harpooning = false
var currentharpoon = null
var harpoon_point = Vector2.ZERO
#var turnaccel = 725
var turnaccel = 1500
var accel = 360
var pivoting = false
var pivot_hit = false

#shield stuff below
var shield_max_health:
	get: 
		return 15.0 * total_shield_increase
var total_shield_increase = 1.0
var shield_health = shield_max_health
var shield_recharge: 
		get: 
			return (0.20 * shield_recharge_increase) / 5
var shield_recharge_increase = 1.0
var shield_can_recharge = false
var maxspeed:
	get: 
		return 250 * total_speed_increase
var highmode = false
var highmodeduration = 1
#var highmodespeedcap = 1740
var highmodespeedcap = 900
var highmodedrag = 150

#gear variables

var total_speed_increase = 1.0
var total_HP_increase = 1.0
var total_damage_increase = 1.0
var harpoon_target: Node2D = null
var harpoon_local_point = Vector2.ZERO

var normaldragaccel = 350
var harpoondragaccel = 150
var harpooncatchduration: float = 0.2
var harpooncatchpullaccel: float = 150.0
var harpooncatchtimer: float = 0.0
var harpoonpullactive: bool = false
var harpoonlaunchduration: float = 1
var harpoonlaunchtimer: float = 0.0

#spring tether
var harpoonrestlength = 70
var springstrength = 6
var harpoonhit = false
var minimumpullaccel = 1500
var maximumpullaccel = 3000
var normalharpoonmaxspeed: float =  600
var slingshotstretchthreshold = 600
@export var chargedharpoonspeed: float =  2500
@export var chargeduration: float = 2.0
@export var chargedecay: float = 3.0
var chargetimer: float = 0.0
var ropecharged = false
var wasoverstretched = false
var currentharpoonmaxspeed: float = normalharpoonmaxspeed
var maxropelength = 0.0

#the lower kbresistance the less kb you take
var kbresistance:
	get:
		return 1.0 - kbresistanceincrease
var kbresistanceincrease = 0.0

#defines absolute max extention
var maxstretchratio = 1.5
#defines how far through extention does charge activate
var chargeratio = 0.75

var bouncegracetimer = 0.0
var bouncegraceduration = 0.5
var can_bounce = false
var momentumboosttime = 0.0
var harpooonmaxrange = 500
var wasattachedthisshot = false
var facinglocked = false
var kbtime = 0.0
var kbvelocity = Vector2.ZERO
@export var harpoonprojectilescene: PackedScene
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

@onready var dash_bar: ProgressBar = get_tree().current_scene.find_child("dashbar", true, false) as ProgressBar
@onready var shield_bar = get_tree().current_scene.get_node("UI/CanvasLayer/ShieldBar")
@export var recharge_per_second: float = 20.0
@export var exhausted_recharge_per_second: float = 10.0
@export var recharge_delay: float = 1.85
#dash
@export var dash_max: float = 25.0
@export var dash_cost: float = 25.0
@export var dash_recharge_per_second: float = 5
@export var dash_recharge_delay: float = 0.5
@export var dash_speed_increase: float = 1.0
var dash_speed:
	get:
		return 825 * dash_speed_increase
@export var dash_duration: float = 0.1
@export var dash_bar_display_value: float = dash_max

var dash_value: float = dash_max
var dash_recharge_timer: float = 0.0
var is_dashing: bool = false
var dash_timer: float = 0.0
var dash_direction: Vector2 = Vector2.ZERO
var direction: Vector2 = Vector2.ZERO


var recharge_timer: float = 0.0
#test armour
var armour_DoT: bool = false
var DoT_strength: float = 0.2 + (armour_DoT_level * 0.05)
var armour_DoT_level: float = 0
var can_level_up_N: bool = false

#testing armour levels

#test save thin


var timer = 0.0
var timerrunning = true
var spawnposition = Vector2.ZERO

func _ready() -> void:
	update_shield_bar()
	$HarpoonLine.visible = false
	$HarpoonLine.width = 1
	if dash_bar:
		dash_bar.min_value = 0
		dash_bar.max_value = dash_max
		dash_bar.value = dash_value
		dash_bar.show_percentage = false
	if health_bar:
		health_bar.min_value = 0
		health_bar.max_value = max_health
		health_bar.value = current_health
		#health_bar.show_percentage = false
	spawnposition = global_position


func _on_harpoon_attached(hitposition, hitbody):
	wasattachedthisshot = true
	harpoonhit = true
	harpoon_point = hitposition
	harpoon_target = hitbody
	harpoon_local_point = harpoon_target.to_local(hitposition)
	
	harpoonrestlength = global_position.distance_to(harpoon_point)

	maxropelength = harpoonrestlength * maxstretchratio

	var maxextention = maxropelength - harpoonrestlength

	slingshotstretchthreshold = maxextention * chargeratio
	$HarpoonLine.points = [
	Vector2.ZERO,
	to_local(harpoon_point)
		]
	$HarpoonLine.visible = true
	currentharpoon = null
	
	harpooning = true

	harpooncatchtimer = harpooncatchduration
	harpoonpullactive = false
	harpoonlaunchtimer = 0.0
	
func _physics_process(delta: float) -> void:
	PetalStats.update_missing_health_bonus(current_health, max_health)

	if velocity.length() > 500:
		$MovementBubbles.rotation = velocity.angle() + PI
		$MovementBubbles.emitting = true
	else:
		$MovementBubbles.emitting = false
	#test
	if harpoonhit:
		if is_instance_valid(harpoon_target):
			harpoon_point = harpoon_target.to_global(harpoon_local_point)
			$HarpoonLine.points = [
			Vector2.ZERO,
			to_local(harpoon_point)
				]
		else:
			harpoonhit = false
			harpooning = false
			$HarpoonLine.visible = false
	
	
	var mouse_pos = get_global_mouse_position()
	var direction_to_mouse = (mouse_pos - global_position).normalized()
	$HarpoonRaycast.target_position = direction_to_mouse * 500
	
	if highmode:
		if velocity.length() > 700:
			$SuperMovementBurst.emitting = true
			
			$SuperMovementBubbles.rotation = velocity.angle() + PI
			$SuperMovementBubbles.emitting = true
			
			$SuperMovementTrails.rotation = velocity.angle() + PI
			$SuperMovementTrails.emitting = true
		else:
			$SuperMovementBubbles.emitting = false
			$SuperMovementTrails.emitting = false

		if not is_dashing and not harpooning:
			highmodeduration -= delta

		if highmodeduration <= 0.0:
			highmode = false
			$SuperMovementBubbles.emitting = false
			$SuperMovementTrails.emitting = false
			highmodeduration = 1
	else:
		$SuperMovementBubbles.emitting = false
		$SuperMovementTrails.emitting = false
		$AnimatedSprite2D.modulate = Color.WHITE
		
	if ropecharged:
		$HarpoonLine.modulate = "WHITE"
	if not ropecharged:
		$HarpoonLine.modulate = "RED"
	
	if kbtime > 0:
		kbtime -= delta
		velocity = kbvelocity
		move_and_slide()
		return
	#if momentumboosttime  > 0:
		#momentumboosttime -= delta
		
	if currentharpoon != null:
		var ropelength = global_position.distance_to(currentharpoon.global_position)
		if ropelength > harpooonmaxrange:
			currentharpoon.queue_free()
			currentharpoon = null
			harpooning = false
			$HarpoonLine.visible = false
		else:
				$HarpoonLine.visible = true
				$HarpoonLine.points = [
				Vector2.ZERO,
				to_local(currentharpoon.global_position)
			]
	elif harpooning:
		$HarpoonLine.visible = true
		$HarpoonLine.points = [
		Vector2.ZERO,
		to_local(harpoon_point)
		]
	else:
		$HarpoonLine.visible = false
		
	direction = Input.get_vector("Left", "Right", "Up", "Down")
	handle_dash(delta, direction)
	#if not is_on_floor():
		#velocity += get_gravity() * delta
#
	#if Input.is_action_just_pressed("Jump") and is_on_floor():
		#velocity.y = JUMP_VELOCITY

	if Input.is_action_just_pressed("Harpoon"):
		pivoting = highmode
		wasattachedthisshot = false
		var harpoon = harpoonprojectilescene.instantiate()
		harpoon.global_position = global_position		
		harpoon.direction = direction_to_mouse
		harpoon.attached.connect(_on_harpoon_attached)
		get_parent().add_child(harpoon)
		currentharpoon = harpoon
	if Input.is_action_just_released("Harpoon"):
		if ropecharged:
			highmode = true
			highmodeduration = 1
			start_highmode_flash()

		pivoting = false
		harpoonhit = false
		ropecharged = false
		chargetimer = 0
		wasoverstretched = false
		currentharpoonmaxspeed = normalharpoonmaxspeed
		harpooning = false
		harpooncatchtimer = 0.0
		harpoonlaunchtimer = 0.0
		harpoonpullactive = false
		$HarpoonLine.visible = false
		if wasattachedthisshot == true:
			#momentumboosttime = 0.1
			wasattachedthisshot = false

		if currentharpoon != null:
			currentharpoon.queue_free()
			currentharpoon = null
	var currentaccel = accel

	#sprite flipping stuff below
	if direction.x > 0: 
		faceside("left")
	elif direction.x < 0:
		faceside("right")
	#sprite flipping ends here, please depart from the train. Functions await below

	
	#if harpooning:
		##currentaccel = 1200
		#currentaccel = 720
	var currentmaxspeed = maxspeed
	if highmode:
		currentmaxspeed = highmodespeedcap

		
	if direction:
		var movementinputallowed = harpoonlaunchtimer <= 0.0

		if movementinputallowed and not (harpooning and harpooncatchtimer > 0.0):
			var movementdot = direction.dot(velocity.normalized()) if velocity.length() > 0 else 1.0

			if highmode and movementdot < -0.7:
				pass
			elif velocity.length() == 0 or movementdot > 0:
				velocity += direction * currentaccel * delta
			else:
				velocity += direction * turnaccel * delta
				
			#if not harpooning and momentumboosttime <= 0:
				#velocity = velocity.limit_length(maxspeed)
	
			
	else:
		var currentdragaccel = normaldragaccel
		if highmode:
			currentdragaccel = highmodedrag
		
		if harpooning:
			currentdragaccel = harpoondragaccel
			
		velocity = velocity.move_toward(
			Vector2.ZERO,
			currentdragaccel * delta
		)
		
	if not harpooning and not is_dashing:
		var currentspeed = velocity.length()
		if currentspeed > currentmaxspeed:
			var targetvelocity = velocity.normalized() * currentmaxspeed
			velocity = velocity.move_toward(
				targetvelocity, 
				1980 * delta
			)
		
	if harpooning:
		if harpooncatchtimer > 0.0:
			harpooncatchtimer -= delta

			if harpooncatchtimer <= 0.0:
				harpooncatchtimer = 0.0
				harpoonpullactive = true
				if not highmode:
					harpoonlaunchtimer = harpoonlaunchduration
		if harpoonlaunchtimer > 0.0:
			harpoonlaunchtimer -= delta
					
		var direction_to_point = (harpoon_point - global_position).normalized()
		
		var sidewaysdirection = direction_to_point.orthogonal()
		
		if harpooncatchtimer > 0.0 and direction != Vector2.ZERO:
			var sidewaysinput = direction.dot(sidewaysdirection)
			velocity += sidewaysdirection * sidewaysinput * turnaccel * delta
		
		var distancetopoint = global_position.distance_to(harpoon_point)
		#if distancetopoint > maxropelength:
			#global_position = harpoon_point + (global_position - harpoon_point).normalized() * maxropelength
			#distancetopoint = maxropelength
		var stretch = max(distancetopoint - harpoonrestlength, 0)
		
		var currentpullaccel = clamp(minimumpullaccel + stretch * springstrength, minimumpullaccel, maximumpullaccel)
		
		# Brief weak pull allows the player to pivot before the rope fully catches.
		if not harpoonpullactive:
			currentpullaccel = harpooncatchpullaccel
		
		velocity += (direction_to_point * currentpullaccel * delta)

		
		var overstretched = stretch >= slingshotstretchthreshold
		if overstretched and not wasoverstretched:
			ropecharged = true
			chargetimer = chargeduration
			currentharpoonmaxspeed = chargedharpoonspeed
			
		wasoverstretched = overstretched
		if ropecharged:
			if chargetimer > 0.0:
				chargetimer -= delta
				currentharpoonmaxspeed = chargedharpoonspeed
			else:
				currentharpoonmaxspeed = lerp(
					currentharpoonmaxspeed,
					normalharpoonmaxspeed,
					min(chargedecay * delta, 1.0)
				)
			
			if abs(currentharpoonmaxspeed - normalharpoonmaxspeed) < 1:
				currentharpoonmaxspeed = normalharpoonmaxspeed
				ropecharged = false
		else:
			currentharpoonmaxspeed = normalharpoonmaxspeed
			
		velocity = velocity.limit_length(currentharpoonmaxspeed)
		
		$HarpoonLine.points = [
			Vector2.ZERO,
			to_local(harpoon_point)
		]
	var crashed = false
	
	if Input.is_action_just_pressed("Restart"):
		if not AbilityFolder.is_typing:
			get_tree().call_deferred("change_scene_to_file", "res://Scenes/Game.tscn")
			get_tree().call_deferred("reload_current_scene")
	#for bounce
	if bouncegracetimer > 0.0:
		bouncegracetimer -= delta
	else:
		can_bounce = false
	var incomingvelocity := velocity
	move_and_slide()
	update_dash_bar(delta)
	

	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var normal = collision.get_normal()
		var impactspeed = incomingvelocity.dot(-normal)
		
		#print("impact: ", impactspeed, " can bounce: ", can_bounce)
		
		if impactspeed > 300:
			if can_bounce:
				bouncegracetimer = 0.0
				velocity = incomingvelocity.bounce(normal) * 1.1
				dash_value = dash_max

				if highmode:
					highmodeduration = 1
					play_parry_effect(collision.get_position(), collision.get_normal())
				else:
					$ParryBubbles.global_position = collision.get_position()
					$ParryBubbles.rotation = collision.get_normal().angle()
					$ParryBubbles.restart()
					$ParryBubbles.emitting = true
					
				break
			else:
				crashed = true
	if crashed:
		velocity *= 0.7

func faceside(side):
	if facinglocked:
		return
	if side == "right":
		animated_sprite_2d.flip_h = false
		$Spear.setrestside("right")
	elif side == "left":
		animated_sprite_2d.flip_h = true
		$Spear.setrestside("left")
	
func forcefaceside(side):
	if side == "right":
		animated_sprite_2d.flip_h = false
		$Spear.setrestside("right")
	elif side == "left":
		animated_sprite_2d.flip_h = true
		$Spear.setrestside("left")
		
func handle_dash(delta: float, direction: Vector2) -> void:
	if is_dashing:
		dash_timer -= delta
		if highmode:
			velocity = velocity.length() * dash_direction * 1.05
		else:
			velocity = dash_direction * dash_speed

		if dash_timer <= 0.0:
			is_dashing = false

		return

	if Input.is_action_just_pressed("Dash") and dash_value >= dash_cost:
		if not AbilityFolder.is_typing:
			start_dash(direction)

	if dash_recharge_timer > 0.0:
		dash_recharge_timer -= delta
	else:
		recharge_dash(delta)


func start_dash(direction: Vector2) -> void:
	if direction.length() > 0.0:
		dash_direction = direction.normalized()
	else:
		dash_direction = (get_global_mouse_position() - global_position).normalized()

	if dash_direction == Vector2.ZERO:
		return
	$DashParticles.rotation = dash_direction.angle()
	$DashParticles.restart()
	$DashParticles.emitting = true
	is_dashing = true
	dash_timer = dash_duration

	dash_value -= dash_cost
	dash_value = max(dash_value, 0.0)

	dash_recharge_timer = dash_recharge_delay
	velocity = dash_direction * dash_speed


func recharge_dash(delta: float) -> void:
	if dash_value >= dash_max:
		dash_value = dash_max
		return

	dash_value += dash_recharge_per_second * delta
	dash_value = min(dash_value, dash_max)


func update_dash_bar(delta: float) -> void:
	if dash_bar:
		dash_bar_display_value = move_toward(
			dash_bar_display_value,
			dash_value,
			60.0 * delta
		)

		dash_bar.value = dash_bar_display_value
func start_highmode_flash() -> void:
	$AnimatedSprite2D.modulate = Color.WHITE * 1.5
	await get_tree().create_timer(0.1).timeout
	$AnimatedSprite2D.modulate = Color(0.991, 1.0, 0.815, 1.0)


#actual health stuff below
@onready var health_label: Label = $"../UI/CanvasLayer/health_label"
@onready var health_bar: TextureProgressBar = get_tree().current_scene.find_child("HealthBeams", true, false) as TextureProgressBar
@onready var healthanim = get_tree().current_scene.find_child("HealthAnimationPlayer", true, false)
@onready var hitparticlesA: GPUParticles2D = get_tree().current_scene.find_child("HitParticlesA", true, false)
@onready var hitparticlesB: GPUParticles2D = get_tree().current_scene.find_child("HitParticlesB", true, false)
@onready var emptybeams = get_tree().current_scene.find_child("EmptyBeams", true, false)
var invincible = false
var regen_delay = 1
var regen_per_second = 0
var time_since_damage = 0.0
var displayed_health = 100
var total_heal_increase = 0.1
var passive_heal: float = 0.0
var passive_heal_increase: float = 0.01
var cookie_speed_bonus: float = 0.0
var cookie_damage_bonus: float = 0.0
var cookie_passive_heal_bonus: float = 0.01 
var cookie_boost_active: bool = false
var max_health:
	get:
		return 100 
		#* total_HP_increase
var can_heal = true
var heal_per_second:
	get:
		return (max_health * total_heal_increase) / 5

#defense stuff below
var defence:
	get:
		return total_defence_increase
@export var total_defence_increase = 0.0

var current_health = 100
var damage_occuring = false
var iframe_duration = 0.9
var starsaveused = false

#mob damages

var clownfish_damage = 5
var shark_damage = 25
var seahorse_projectile_damage = 10
var crab_damage = 45
var starfish_damage = 15
var crab_boss_damage = 75
var stealth_stalker_damage = 10

	


func _process(delta):
	handle_health_regen(delta)
	update_health_ui(delta)

		
	if current_health <= 0:
		get_tree().call_deferred("reload_current_scene")
		
func handle_health_regen(delta: float) -> void:
	if current_health >= max_health:
		current_health = max_health
		time_since_damage = 0.0
		return

	time_since_damage += delta

	if passive_heal > 0.0 and current_health < max_health:
		current_health += (max_health * passive_heal) * delta
		current_health = min(current_health, max_health)

	if not can_heal:
		return

	if time_since_damage >= regen_delay:
		current_health += regen_per_second * delta
		current_health = min(current_health, max_health)


func apply_cookie_boost(speed_bonus: float, damage_bonus: float, passive_heal_bonus: float, duration: float) -> void:
	cookie_speed_bonus = speed_bonus
	cookie_damage_bonus = damage_bonus
	cookie_passive_heal_bonus = passive_heal_bonus
	total_speed_increase += cookie_speed_bonus
	accel *= 1.2
	total_damage_increase += cookie_damage_bonus
	passive_heal += cookie_passive_heal_bonus

	if cookie_boost_active:
		return

	cookie_boost_active = true
	await get_tree().create_timer(duration).timeout
	total_speed_increase = max(1.0, total_speed_increase - cookie_speed_bonus)
	accel /= 1.2
	total_damage_increase = max(1.0, total_damage_increase - cookie_damage_bonus)
	passive_heal = max(0.0, passive_heal - cookie_passive_heal_bonus)
	cookie_boost_active = false

func update_health_ui(delta: float) -> void:
	displayed_health = current_health
	var healthpercent = float(displayed_health) / float(max_health)
	var visual = max_health
	#if displayed_health > current_health:
	if current_health <= 0:
		visual = 0
	elif starsaveused and current_health == 1:
		visual = 21
	else:
		visual = max_health * (0.25 + healthpercent * 0.75)
	#else:
		##displayed_health = move_toward(
			##displayed_health,
			##current_health,
			##regen_per_second * delta
		##)
	if health_label:
		health_label.text = str(roundi(displayed_health))

	if health_bar:
		health_bar.value = visual
		
func update_shield_bar():
	shield_bar.max_value = shield_max_health
	shield_bar.value = shield_health

func take_player_damage(amount: float) -> void:
	if invincible:
		return
	# ___________ SHIELD CODE ______________
	if shield_health > 0: 
		if shield_health <= shield_max_health * 0.5:
			shield_can_recharge = false
			$ShieldRechargeDelay.start()
		if amount <= shield_health:
			shield_health -= amount
			update_shield_bar()
			return
		else:
			amount -= shield_health
			shield_health = 0
			update_shield_bar()
			shield_can_recharge = false
			$ShieldRechargeDelay.start()
	if current_health - amount <= 0 and not starsaveused and current_health > 1:
		current_health = 1
		starsaveused = true
		emptybeams.visible = false
	else:
		current_health -= amount * (100.0 / (defence + 100.0))
		update_shield_bar()
		current_health = max(current_health, 0)
		can_heal = false
		time_since_damage = 0.0
		$HealDelayTimer.stop()
		if not TimeStop.time_stop_active == true:
			$HealDelayTimer.start()
	if healthanim:
		healthanim.stop()
		healthanim.play("damageflash")
	var healthpercent = float(current_health) / float(max_health)
	var startpos = health_bar.global_position
	var visualwidth = health_bar.size.x * health_bar.scale.x
	var visualheight = health_bar.size.y * health_bar.scale.y

	var beamstartx = startpos.x + visualwidth * 0.21
	var beamwidth = visualwidth * 0.79

	var beampercent = float(current_health) / float(max_health)

	var endx = beamstartx + beamwidth * beampercent
	var midy = startpos.y + visualheight / 2
	var distance_from_end = 1.0 - healthpercent
	var straight_part = 0.1
	var edgefade = clamp((distance_from_end - straight_part) * 100, 0.0, 1.0)
	var wave = sin(healthpercent * TAU * 3.5) * 18 * edgefade
	hitparticlesA.global_position = Vector2(endx, midy + wave)
	hitparticlesB.global_position = Vector2(endx, midy - wave)
	hitparticlesA.restart()
	hitparticlesB.restart()
	time_since_damage = 0.0
	invincible = true
	set_collision_mask_value(4, false)
	await get_tree().create_timer(iframe_duration).timeout
	set_collision_mask_value(4, true)
	invincible = false
	for body in $hurt_area.get_overlapping_bodies():
		if is_instance_valid(body):
			handleenemycontact(body)
			break
func _on_hurt_area_body_entered(body: Node2D) -> void:
	handleenemycontact(body)
		
	#if armour_DoT == false:
		#take_player_damage(damage)
		#await get_tree().create_timer(iframe_duration).timeout
	#else:
		#var maxdamage = damage
		#while damage >= maxdamage * DoT_strength:
			#take_player_damage(damage * DoT_strength)
			#damage -= damage * DoT_strength 
			#await get_tree().create_timer(DoT_strength * 4.0).timeout
func _on_hurt_area_body_exited(body: Node2D) -> void:
	damage_occuring = false
func activate():
	armour_DoT = true

func handleenemycontact(body: Node2D):
	if not is_instance_valid(body):
		return
	if invincible:
		return
		
	var damage = 0
	var kbstrength = 0

	
	#damage scripts
	if body.is_in_group("clownfish"):
		damage = clownfish_damage
		kbstrength = 500 * kbresistance
	elif body.is_in_group("shark"):
		damage = shark_damage
		kbstrength = 2000 * kbresistance
	elif body.is_in_group("seahorse_projectile"):
		damage = seahorse_projectile_damage
		kbstrength = 300 * kbresistance
		body.queue_free()
	elif body.is_in_group("crab"):
		damage = crab_damage
		kbstrength = 2000 * kbresistance
	elif body.is_in_group("starfish"):
		damage = starfish_damage
		kbstrength = 700 * kbresistance
	elif body.is_in_group("stealth_stalker"):
		damage = stealth_stalker_damage
		kbstrength = 500 * kbresistance
		
	elif body.is_in_group("crab_boss"):
		damage = crab_boss_damage
		kbstrength = 700
	
	else:
		return
	
	damage_occuring = true
	
	var kbdirection = (global_position - body.global_position)

	if kbdirection.length() < 1:
		kbdirection = -velocity.normalized()

	if kbdirection == Vector2.ZERO:
		kbdirection = Vector2(1, 0)

	kbdirection = kbdirection.normalized()
	kbvelocity = kbdirection * kbstrength
	kbtime = 0.12
	$damage_number_template.spawn_label(damage, false)
	take_player_damage(damage)
	
func on_spear_hit(hurtbox: TemplateHurtbox) -> void:
	var enemy = hurtbox.owner
	var normal = -(get_global_mouse_position() - global_position).normalized()
	var effect_normal = (global_position - hurtbox.global_position).normalized()
	velocity = velocity.bounce(normal)
	dash_value = dash_max
	bouncegracetimer = 0.0
	
	if highmode:
		highmodeduration = 1
		play_parry_effect(hurtbox.global_position, effect_normal)
	else:
		$ParryBubbles.global_position = hurtbox.global_position
		$ParryBubbles.rotation = (global_position - hurtbox.global_position).angle()
		$ParryBubbles.restart()
		$ParryBubbles.emitting = true
		
	


func setcanbounce(value):
	if value:
		can_bounce = true
		bouncegracetimer = bouncegraceduration
		
		
func play_parry_effect(effect_position: Vector2, effect_normal: Vector2) -> void:
	$ParryBubbles.global_position = effect_position
	$ParryBubbles.rotation = effect_normal.angle() + PI

	$ParrySparks.global_position = global_position

	$ParryBubbles.restart()
	$ParryBubbles.emitting = true

	$ParrySparks.restart()
	$ParrySparks.emitting = true
	
func _on_heal_delay_timer_timeout() -> void:
	can_heal = true


func _on_heal_timer_timeout() -> void:
	if TimeStop.time_stop_active == true:
		$HealDelayTimer.start()
		return
	if can_heal and current_health < max_health:
		current_health += heal_per_second
		current_health = min(current_health, max_health)


func _on_shield_recharge_delay_timeout() -> void:
	if TimeStop.time_stop_active == true:
		return
	shield_can_recharge = true

func _on_shield_recharge_timer_timeout() -> void:
	if TimeStop.time_stop_active == true:
		return
	if !shield_can_recharge:
		return
	if current_health < max_health:
		return
	if shield_health >= shield_max_health:
		return
	if shield_can_recharge:
		shield_health += shield_max_health * shield_recharge
		shield_health = min(shield_health, shield_max_health)
		update_shield_bar()
	
