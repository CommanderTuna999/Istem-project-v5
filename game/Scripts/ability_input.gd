extends Control 

@onready var action_button: Button = $Button
@onready var input_field: LineEdit = $LineEdit

var regex = RegEx.new()
var last_valid_text: String = ""

func _ready() -> void:
	# RegEx pattern: matches only letters (upper and lowercase)
	regex.compile("^[a-zA-Z_]*$")
	
	# Connect the text_changed signal strictly for filtering out invalid keys in real-time
	input_field.text_changed.connect(_on_line_edit_text_changed)

# STEP 1: User clicks the button
func _on_button_pressed() -> void:
	input_field.text = "" # Clear previous text
	last_valid_text = ""
	input_field.visible = true # Show the input box
	input_field.grab_focus() # Automatically place the typing cursor inside it
	action_button.disabled = true # Disable button while typing
	AbilityFolder.is_typing = true

# REAL-TIME FILTER: Prevents typing anything but letters
func _on_line_edit_text_changed(new_text: String) -> void:
	if regex.search(new_text):
		last_valid_text = new_text
	else:
		# Reject invalid characters instantly
		input_field.text = last_valid_text
		input_field.caret_column = last_valid_text.length()

# STEP 2: User presses Enter
func _on_line_edit_text_submitted(new_text: String) -> void:
	# Accessing the Global Autoload directly by its name
	AbilityFolder.ability = new_text
	
	# Clean up the UI
	input_field.visible = false
	action_button.disabled = false
	AbilityFolder.is_typing = false
	print("Saved global ability as: ", AbilityFolder.ability) # For debugging
