extends Control

@onready var guide_button: Button = $GuideButton
@onready var guide: Label = $GuideLabel
@onready var guide2: Label = $GuideLabel2

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	guide.visible = false # Hide the guide at start
	guide2.visible = false
	guide_button.pressed.connect(_on_guide_button_pressed)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if guide.visible and guide2.visible and Input.is_action_just_pressed("close_guide"):
		guide.visible = false
		guide2.visible = false

func _on_guide_button_pressed() -> void:
	guide.visible = true
	guide2.visible = true
