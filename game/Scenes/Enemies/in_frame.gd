extends Area2D

@export var damage_delay: float = 0.85
@export var out_of_bounds_damage: float = 100.0

var player: Node2D = null
var leave_timer: SceneTreeTimer = null

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") or body.name == "Player":
		player = body
		leave_timer = null 

func _on_body_exited(body: Node2D) -> void:
	if body == player:
		start_damage_countdown()

func start_damage_countdown() -> void:
	var current_timer = get_tree().create_timer(damage_delay)
	leave_timer = current_timer
	
	await current_timer.timeout
	
	if is_instance_valid(player) and leave_timer == current_timer:
		if player.has_method("take_player_damage"):
			player.take_player_damage(out_of_bounds_damage)
			
		start_damage_countdown()
