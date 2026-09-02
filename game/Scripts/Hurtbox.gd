class_name TemplateHurtbox
extends Area2D



func _init() -> void:
	collision_layer = 0
	collision_mask = 1024 #11


func _ready() -> void:
	connect("area_entered", self._on_area_entered)



func _on_area_entered(hitbox: TemplateHitbox) -> void:
	if hitbox == null:
		return
	if owner.has_method("take_damage"):
		var final_damage = apply_turtle_absorb(hitbox.damage)
		owner.take_damage(final_damage)
	if owner.has_method("take_kb"):
		owner.take_kb(hitbox.global_position)
	if hitbox.get_parent().get_parent().has_method("successful_hit"):
		hitbox.get_parent().get_parent().successful_hit(self)


func apply_turtle_absorb(amount: float) -> float:
	var remaining_damage := amount
	for turtle in get_tree().get_nodes_in_group("turtle"):
		if not is_instance_valid(turtle):
			continue
		if turtle == owner:
			continue
		if not turtle.has_method("absorb_damage"):
			continue
		if owner.global_position.distance_to(turtle.global_position) <= turtle.absorb_radius:
			var absorbed: float = amount * turtle.absorb_percent
			turtle.absorb_damage(absorbed)
			remaining_damage -= absorbed
	return max(remaining_damage, 0.0)
