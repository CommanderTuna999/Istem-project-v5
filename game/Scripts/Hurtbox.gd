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
		owner.take_damage(hitbox.damage)

	if owner.has_method("take_kb"):
		owner.take_kb(hitbox.global_position)
	if hitbox.get_parent().get_parent().has_method("successful_hit"):
		hitbox.get_parent().get_parent().successful_hit(self)
