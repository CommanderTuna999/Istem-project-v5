extends CanvasLayer

signal finished(passed: bool)

var questions = [
	{
		"text": "Who are you?",
		"options": ["The Diver of Light.", "I don't know.", "Who are you?", "That doesn't matter."],
		"correct": 0
	},
	{
		"text": "Why are you here?",
		"options": ["You should be dead.", "To kill you.", "Not sure, why don't you tell me?", "No idea."],
		"correct": 1
	},
	{
		"text": "What is your purpose?",
		"options": ["To destroy Corruption.", "Just a swim.", "What is YOUR purpose?", "Stop asking me questions."],
		"correct": 0
	},
	{
		"text": "Strange. How do you plead?",
		"options": ["Guilty.", "Innocent.", "It wasn't me.", "It was you."],
		"correct": 0
	},
	{
		"text": "I will have you executed anyhow.",
		"options": ["Try me.", "It doesn't matter, none of it does…", "You'll die first.", "Sure, go AHEAD! Kill me!"],
		"correct": 0
	}
]

var current_question = 0

@onready var question_label: Label = $Panel/QuestionLabel
@onready var options_container: VBoxContainer = $Panel/OptionsContainer
@onready var dialogue_label: Label = $Panel/DialogueLabel


func _ready() -> void:
	dialogue_label.visible = false
	for i in range(options_container.get_child_count()):
		var button = options_container.get_child(i)
		button.pressed.connect(_on_option_pressed.bind(i))
	show_question(current_question)


func show_question(index: int) -> void:
	var q = questions[index]
	question_label.text = q["text"]
	for i in range(options_container.get_child_count()):
		var button = options_container.get_child(i)
		button.text = q["options"][i]
		button.disabled = false


func _on_option_pressed(option_index: int) -> void:
	var q = questions[current_question]
	if option_index == q["correct"]:
		current_question += 1
		if current_question >= questions.size():
			finish_success()
		else:
			show_question(current_question)
	else:
		fail_quiz()


func finish_success() -> void:
	disable_all_buttons()
	question_label.text = "..."
	await get_tree().create_timer(1.0).timeout
	finished.emit(true)
	queue_free()


func fail_quiz() -> void:
	disable_all_buttons()
	question_label.visible = false
	options_container.visible = false
	dialogue_label.visible = true
	dialogue_label.text = "The Dreadlord's blade finds you before you can speak again."

	await get_tree().create_timer(2.5).timeout
	finished.emit(false)
	queue_free()


func disable_all_buttons() -> void:
	for i in range(options_container.get_child_count()):
		options_container.get_child(i).disabled = true
