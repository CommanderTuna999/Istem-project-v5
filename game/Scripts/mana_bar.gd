extends ProgressBar # Or TextureProgressBar depending on your node type

func _ready() -> void:
	# Set up initial visual parameters from the global script
	max_value = Mana.max_mana

func _process(_delta: float) -> void:
	# Update the bar's value to match the global data tracking
	value = Mana.current_mana
