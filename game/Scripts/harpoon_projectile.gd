extends Area2D
var direction = Vector2.ZERO
var speed = 2500
var wowattached = false


signal attached(hitposition, hitbody)	
func _ready():
	$ColorRect.rotation = direction.angle()
	$HarpoonTip.rotation = direction.angle()


func _physics_process(delta: float) -> void:
	if wowattached:
		return
	var movement = direction * speed * delta
	
	$RayCast2D.target_position = movement
	$RayCast2D.force_raycast_update()
	
	if $RayCast2D.is_colliding():
		wowattached = true
		attached.emit($RayCast2D.get_collision_point(),
		$RayCast2D.get_collider())
		queue_free()
		return
	
	global_position += movement

	
func _on_body_entered(body):
	if wowattached:
		return
	wowattached = true
	attached.emit(global_position, body)
	queue_free()
