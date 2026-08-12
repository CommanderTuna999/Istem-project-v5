extends CanvasLayer

func show_item_popup(item_name, message):
	$Panel.visible = true
	$Panel/Label.text = message

	await get_tree().create_timer(5.0).timeout

	$Panel.visible = false
