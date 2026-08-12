extends Area2D
signal item_obtained(item_name, message)
@export var target_node: Node

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.name == "Player":
		target_node.activate()
		$"../UI/CanvasLayer".show_item_popup(
			"DoT Armour",
			"You obtained DoT Armour.\nGo to the shopkeeper to unequip, upgrade or change it!"
		)
		queue_free()
