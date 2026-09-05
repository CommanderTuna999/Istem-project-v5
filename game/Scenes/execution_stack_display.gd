extends Node2D

@onready var count_label: Label = $CountLabel

func _ready() -> void:
	visible = false

func update_stacks(current: int, max_stacks: int) -> void:
	if current <= 0:
		visible = false
		return
	visible = true
	count_label.text = str(current) + "/" + str(max_stacks)
