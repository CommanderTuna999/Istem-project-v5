extends Node2D
class_name damage_number_template

@export var label_settings: LabelSettings
@export var crit_colour: Color = Color.RED

func spawn_label(number: float, crit: bool = false) -> void:
	var new_label: Label = Label.new()
	new_label.text = str(number if step_decimals(number) != 0 else number as int)
	new_label.label_settings = label_settings.duplicate() #label as a seperate copy so changing colour doesnt screw with other copies
	new_label.z_index = 1000 #show in front of stuff
	new_label.pivot_offset_ratio = Vector2(0.5, 1)
	
	if crit: #change colour on crit hit (might not use)
		new_label.label_settings.font_color = crit_colour
	
	call_deferred("add_child", new_label)
	await new_label.resized #wait til size change
	new_label.position -= Vector2(new_label.size.x / 2, new_label.size.y) #scale stuff on resize
	new_label.position += Vector2(randf_range(-8, 8), randf_range(-8, 8)) #add position offset so no overlap
	
	
	
	#floating, transitioning and animatipns below
	var target_rise_position: Vector2 = new_label.position + Vector2(randf_range(-8, 8), randf_range(-22, -16))
	var tween_length: float = 1.5 #text duration
	var label_tween: Tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	label_tween.tween_property(new_label, "position", target_rise_position, tween_length)
	label_tween.parallel().tween_property(new_label, "scale", Vector2.ONE * 1.35, tween_length)
	label_tween.parallel().tween_property(new_label, "modulate:a", 0, tween_length).connect("finished", new_label.queue_free)
