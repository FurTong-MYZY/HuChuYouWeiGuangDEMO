extends CanvasLayer


var left_btn: Button
var right_btn: Button
var jump_btn: Button
var dash_btn: Button
var interact_btn: Button


var scale_slider: HSlider
var button_scale: float = 1.0


const BUTTON_SIZE: = Vector2(80, 80)
const BUTTON_SPACING: = 10
const GROUP_SPACING: = 500

func _ready() -> void :

	return
	_create_controls()
	_connect_signals()
	reset_layout()

func _create_controls() -> void :
	var screen_size = get_viewport().get_visible_rect().size


	left_btn = _create_button("←")
	add_child(left_btn)

	right_btn = _create_button("→")
	add_child(right_btn)

	jump_btn = _create_button("跳跃")
	add_child(jump_btn)

	dash_btn = _create_button("冲刺")
	add_child(dash_btn)

	interact_btn = _create_button("交互")
	add_child(interact_btn)


	_set_default_positions(screen_size)


	_create_scale_slider(screen_size)

func _set_default_positions(screen_size: Vector2) -> void :
	var start_x = 20
	var y_pos = screen_size.y - 200


	left_btn.position = Vector2(start_x, y_pos)
	right_btn.position = Vector2(start_x + BUTTON_SIZE.x + BUTTON_SPACING, y_pos)


	var group_start_x = start_x + (BUTTON_SIZE.x + BUTTON_SPACING) * 2 + GROUP_SPACING
	jump_btn.position = Vector2(group_start_x, y_pos)
	dash_btn.position = Vector2(group_start_x + BUTTON_SIZE.x + BUTTON_SPACING, y_pos)
	interact_btn.position = Vector2(group_start_x + (BUTTON_SIZE.x + BUTTON_SPACING) * 2, y_pos)

func _create_button(text: String) -> Button:
	var btn = Button.new()
	btn.text = text
	btn.size = BUTTON_SIZE
	btn.pivot_offset = BUTTON_SIZE / 2


	btn.add_theme_font_size_override("font_size", 18)
	btn.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	btn.add_theme_color_override("font_hover_color", Color(1, 1, 1, 1))
	btn.add_theme_color_override("font_pressed_color", Color(1, 1, 1, 1))
	btn.add_theme_color_override("font_focus_color", Color(1, 1, 1, 1))


	var normal_style = StyleBoxFlat.new()
	normal_style.bg_color = Color(0.2, 0.2, 0.2, 0.5)
	normal_style.border_color = Color(1, 1, 1, 0.8)
	normal_style.set_border_width_all(2)
	normal_style.corner_radius_top_left = 40
	normal_style.corner_radius_top_right = 40
	normal_style.corner_radius_bottom_left = 40
	normal_style.corner_radius_bottom_right = 40
	normal_style.shadow_color = Color(0, 0, 0, 0.5)
	normal_style.shadow_size = 4
	normal_style.shadow_offset = Vector2(0, 2)


	var pressed_style = StyleBoxFlat.new()
	pressed_style.bg_color = Color(0.4, 0.4, 0.4, 0.7)
	pressed_style.border_color = Color(1, 1, 1, 1)
	pressed_style.set_border_width_all(2)
	pressed_style.corner_radius_top_left = 40
	pressed_style.corner_radius_top_right = 40
	pressed_style.corner_radius_bottom_left = 40
	pressed_style.corner_radius_bottom_right = 40
	pressed_style.shadow_color = Color(0, 0, 0, 0.3)
	pressed_style.shadow_size = 2
	pressed_style.shadow_offset = Vector2(0, 1)


	var hover_style = StyleBoxFlat.new()
	hover_style.bg_color = Color(0.3, 0.3, 0.3, 0.6)
	hover_style.border_color = Color(1, 1, 1, 0.9)
	hover_style.set_border_width_all(2)
	hover_style.corner_radius_top_left = 40
	hover_style.corner_radius_top_right = 40
	hover_style.corner_radius_bottom_left = 40
	hover_style.corner_radius_bottom_right = 40
	hover_style.shadow_color = Color(0, 0, 0, 0.4)
	hover_style.shadow_size = 3
	hover_style.shadow_offset = Vector2(0, 1)


	btn.add_theme_stylebox_override("normal", normal_style)
	btn.add_theme_stylebox_override("pressed", pressed_style)
	btn.add_theme_stylebox_override("hover", hover_style)
	btn.add_theme_stylebox_override("focus", normal_style)

	return btn

func _create_scale_slider(screen_size: Vector2) -> void :

	var slider_bg = Panel.new()
	slider_bg.size = Vector2(200, 40)
	slider_bg.position = Vector2(screen_size.x - 220, screen_size.y - 50)

	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.1, 0.1, 0.1, 0.5)
	bg_style.corner_radius_top_left = 20
	bg_style.corner_radius_top_right = 20
	bg_style.corner_radius_bottom_left = 20
	bg_style.corner_radius_bottom_right = 20
	slider_bg.add_theme_stylebox_override("panel", bg_style)
	add_child(slider_bg)


	scale_slider = HSlider.new()
	scale_slider.min_value = 0.5
	scale_slider.max_value = 1.5
	scale_slider.step = 0.1
	scale_slider.value = button_scale
	scale_slider.size = Vector2(160, 20)
	scale_slider.position = Vector2(screen_size.x - 200, screen_size.y - 40)
	scale_slider.custom_minimum_size = Vector2(160, 20)
	add_child(scale_slider)


	var label = Label.new()
	label.text = "缩放"
	label.position = Vector2(screen_size.x - 210, screen_size.y - 35)
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	add_child(label)

	scale_slider.value_changed.connect(_on_scale_changed)

func _on_scale_changed(value: float) -> void :
	button_scale = value
	_apply_scale()
	save_layout()

func _apply_scale() -> void :
	for btn in [left_btn, right_btn, jump_btn, dash_btn, interact_btn]:
		btn.scale = Vector2(button_scale, button_scale)

func reset_layout() -> void :

	if FileAccess.file_exists("user://mobile_layout.cfg"):
		DirAccess.remove_absolute("user://mobile_layout.cfg")


	var screen_size = get_viewport().get_visible_rect().size
	_set_default_positions(screen_size)


	button_scale = 1.0
	scale_slider.value = 1.0
	_apply_scale()


	save_layout()

	print("布局已重置")

func _connect_signals() -> void :

	left_btn.button_down.connect(_on_left_down)
	left_btn.button_up.connect(_on_left_up)
	right_btn.button_down.connect(_on_right_down)
	right_btn.button_up.connect(_on_right_up)


	jump_btn.button_down.connect(_on_jump_down)
	jump_btn.button_up.connect(_on_jump_up)
	dash_btn.button_down.connect(_on_dash_down)
	dash_btn.button_up.connect(_on_dash_up)
	interact_btn.button_down.connect(_on_interact_down)
	interact_btn.button_up.connect(_on_interact_up)


func _on_left_down() -> void :
	Input.action_press("move_left")

func _on_left_up() -> void :
	Input.action_release("move_left")

func _on_right_down() -> void :
	Input.action_press("move_right")

func _on_right_up() -> void :
	Input.action_release("move_right")


func _on_jump_down() -> void :
	Input.action_press("jump")

func _on_jump_up() -> void :
	Input.action_release("jump")

func _on_dash_down() -> void :
	Input.action_press("dash")

func _on_dash_up() -> void :
	Input.action_release("dash")

func _on_interact_down() -> void :
	Input.action_press("interact")

func _on_interact_up() -> void :
	Input.action_release("interact")


func save_layout() -> void :
	var config = ConfigFile.new()
	config.set_value("layout", "left_pos", left_btn.position)
	config.set_value("layout", "right_pos", right_btn.position)
	config.set_value("layout", "jump_pos", jump_btn.position)
	config.set_value("layout", "dash_pos", dash_btn.position)
	config.set_value("layout", "interact_pos", interact_btn.position)
	config.set_value("layout", "button_scale", button_scale)
	config.save("user://mobile_layout.cfg")

func load_layout() -> void :
	var config = ConfigFile.new()
	if config.load("user://mobile_layout.cfg") == OK:
		left_btn.position = config.get_value("layout", "left_pos", left_btn.position)
		right_btn.position = config.get_value("layout", "right_pos", right_btn.position)
		jump_btn.position = config.get_value("layout", "jump_pos", jump_btn.position)
		dash_btn.position = config.get_value("layout", "dash_pos", dash_btn.position)
		interact_btn.position = config.get_value("layout", "interact_pos", interact_btn.position)
		button_scale = config.get_value("layout", "button_scale", 1.0)
		scale_slider.value = button_scale
		_apply_scale()
