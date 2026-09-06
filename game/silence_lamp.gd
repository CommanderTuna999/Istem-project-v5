extends Area2D

var _player_inside: Node2D = null

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	queue_redraw()

func _draw() -> void:
	for child in get_children():
		if child is CollisionShape2D and child.shape is CircleShape2D:
			var radius = child.shape.radius
			draw_circle(child.position, radius, Color(0, 1, 1, 0.3))

func _physics_process(_delta: float) -> void:
	if _player_inside and "is_silenced" in _player_inside:
		_player_inside.is_silenced = true

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") or body.name == "Player":
		_player_inside = body
		if "is_silenced" in body:
			body.is_silenced = true

func _on_body_exited(body: Node2D) -> void:
	if body == _player_inside:
		if "is_silenced" in _player_inside:
			_player_inside.is_silenced = false
		_player_inside = null
