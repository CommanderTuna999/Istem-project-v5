extends Sprite2D

func _ready() -> void:
	visible = false

func _process(delta: float) -> void:
	if get_parent().slowmo == true:
		visible = true
	else:
		visible = false
