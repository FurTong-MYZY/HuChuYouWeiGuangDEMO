extends CanvasLayer

func _ready() -> void :
	layer = 100
	var label: = Label.new()
	label.text = "demo plus"
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color(1, 1, 1, 0.5))
	label.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	label.position = Vector2(-90, -24)
	label.size = Vector2(80, 20)
	add_child(label)
