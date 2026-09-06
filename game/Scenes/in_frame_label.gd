extends RichTextLabel


func _ready() -> void:
	var regular_font = load("res://fonts/GeistPixel-Regular-VariableFont_ELSH.ttf")
	

	var fake_bold_font = FontVariation.new()
	fake_bold_font.base_font = regular_font
	fake_bold_font.variation_embolden = 1.0 
	

	add_theme_font_override("normal_font", regular_font)
	add_theme_font_override("bold_font", fake_bold_font)

	bbcode_enabled = true
	text = "[b]STAY IN THE FRAME[/b]"
	visible = false

	visible = false


func _process(delta: float) -> void:
	if get_parent().boss_targeted == true:
		visible = true
	else:
		visible = false
