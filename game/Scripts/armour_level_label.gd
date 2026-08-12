extends Label

func show_level_up(level):
	text = "Level Up!\nYour DoT Armour level is now %d!" % (level + 1)

	visible = true

	await get_tree().create_timer(3.0).timeout

	visible = false
