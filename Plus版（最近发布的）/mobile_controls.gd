extends CanvasLayer


const ACCENT: = Color(0.835, 0.698, 0.42)
const JOY_RADIUS: = 72.0
const CONFIG_PATH: = "user://touch_layout.cfg"

var move_x: = 0.0
var MOBILE: = false

var _joy_base: PanelContainer
var _joy_knob: PanelContainer
var _joy_id: = -1
var _joy_center: = Vector2.ZERO
var _buttons: Dictionary = {}
var _labels: = {"jump": "跳", "dash": "冲", "interact": "交互", "menu": "≡"}
var _sizes: = {"jump": 112.0, "dash": 76.0, "interact": 76.0, "menu": 54.0}
var _edit_mode: = false
var _drag_name: = ""
var _selected_name: = ""
var _drag_grab: = Vector2.ZERO
var _done_btn: Button
var _btn_plus: Button
var _btn_minus: Button
var _bursts: Dictionary = {}
var _scrub_overlay: ColorRect
var _edit_fingers: Dictionary = {}

var dash_queued: = 0
var interact_queued: = 0

func _ready() -> void :
	layer = 250
	process_mode = Node.PROCESS_MODE_ALWAYS
	MOBILE = OS.has_feature("android") or OS.has_feature("ios") or OS.has_feature("mobile")

	visible = MOBILE
	_build()
	_load_layout()
	_place_static_joy()


func _circle_style(d: float, bg: Color, border_w: int, border_col: Color, glow: = false) -> StyleBoxFlat:
	var s: = StyleBoxFlat.new()
	s.bg_color = bg
	s.set_corner_radius_all(int(d / 2.0))
	s.set_border_width_all(border_w)
	s.border_color = border_col
	s.shadow_color = Color(ACCENT.r, ACCENT.g, ACCENT.b, 0.35 if glow else 0.25)
	s.shadow_size = 22 if glow else 12
	s.shadow_offset = Vector2(0, 4)
	s.content_margin_left = 0
	s.content_margin_right = 0
	s.content_margin_top = 0
	s.content_margin_bottom = 0
	return s

func _build() -> void :

	_scrub_overlay = ColorRect.new()
	_scrub_overlay.color = Color(0.0, 0.0, 0.0, 0.55)
	_scrub_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_scrub_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_scrub_overlay.visible = false
	add_child(_scrub_overlay)

	_joy_base = PanelContainer.new()
	_joy_base.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_joy_base)
	_joy_knob = PanelContainer.new()
	_joy_knob.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_joy_knob)

	for name in _labels:
		var d: float = _sizes[name]
		var is_primary: bool = name == "jump"
		var b: = PanelContainer.new()
		b.custom_minimum_size = Vector2(d, d)
		b.size = Vector2(d, d)
		b.mouse_filter = Control.MOUSE_FILTER_STOP
		var bg: = Color(0.06, 0.055, 0.075, 0.55) if not is_primary else Color(0.14, 0.1, 0.05, 0.65)
		var bc: = Color(ACCENT.r, ACCENT.g, ACCENT.b, 0.6) if not is_primary else Color(ACCENT.r, ACCENT.g, ACCENT.b, 0.95)
		b.add_theme_stylebox_override("panel", _circle_style(d, bg, 1, bc, is_primary))
		var label: = Label.new()
		label.text = _labels[name]
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", int(d * (0.34 if is_primary else 0.3)))
		label.add_theme_color_override("font_color", Color(ACCENT.r, ACCENT.g, ACCENT.b, 0.95))
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(label)

		var p: = CPUParticles2D.new()
		p.amount = 26
		p.one_shot = true
		p.explosiveness = 1.0
		p.lifetime = 0.6
		p.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
		p.emission_sphere_radius = d * 0.45
		p.spread = 180.0
		p.direction = Vector2(0, -1)
		p.initial_velocity_min = 90.0
		p.initial_velocity_max = 240.0
		p.gravity = Vector2(0, 220)
		p.scale_amount_min = 0.4
		p.scale_amount_max = 1.0
		p.color = Color(1.0, 0.88, 0.55, 1.0)
		p.emitting = false
		p.position = Vector2(d / 2.0, d / 2.0)
		b.add_child(p)
		_bursts[name] = p
		b.gui_input.connect(_on_button_gui_input.bind(name))
		add_child(b)
		_buttons[name] = b


	_done_btn = Button.new()
	_done_btn.text = "完成布局"
	_done_btn.custom_minimum_size = Vector2(160, 48)
	_done_btn.add_theme_font_size_override("font_size", 20)
	_done_btn.add_theme_color_override("font_color", Color(ACCENT.r, ACCENT.g, ACCENT.b, 1.0))
	_done_btn.visible = false
	_done_btn.pressed.connect( func(): set_edit_mode(false))
	add_child(_done_btn)
	var vp: = get_viewport().get_visible_rect().size
	_done_btn.position = Vector2(vp.x / 2.0 - 80, 20)


	_btn_plus = Button.new()
	_btn_plus.text = "+"
	_btn_plus.custom_minimum_size = Vector2(64, 64)
	_btn_plus.add_theme_font_size_override("font_size", 32)
	_btn_plus.add_theme_color_override("font_color", Color(ACCENT.r, ACCENT.g, ACCENT.b, 1.0))
	_btn_plus.visible = false
	_btn_plus.pressed.connect( func(): _nudge_size(10.0))
	add_child(_btn_plus)

	_btn_minus = Button.new()
	_btn_minus.text = "-"
	_btn_minus.custom_minimum_size = Vector2(64, 64)
	_btn_minus.add_theme_font_size_override("font_size", 32)
	_btn_minus.add_theme_color_override("font_color", Color(ACCENT.r, ACCENT.g, ACCENT.b, 1.0))
	_btn_minus.visible = false
	_btn_minus.pressed.connect( func(): _nudge_size(-10.0))
	add_child(_btn_minus)

func _nudge_size(delta: float) -> void :
	if _selected_name == "":
		return
	_set_button_size(_selected_name, _buttons[_selected_name].size.x + delta)
	_place_size_controls()
	_save_layout()

func _place_size_controls() -> void :
	if _selected_name == "" or not _buttons.has(_selected_name):
		_btn_plus.visible = false
		_btn_minus.visible = false
		return
	var b: Control = _buttons[_selected_name]
	_btn_plus.visible = true
	_btn_minus.visible = true
	_btn_plus.position = b.position + Vector2(b.size.x + 16, b.size.y / 2.0 - 32.0)
	_btn_minus.position = b.position + Vector2(b.size.x + 16, b.size.y / 2.0 + 40.0)

func _place_static_joy() -> void :
	var vp: = get_viewport().get_visible_rect().size
	_joy_center = Vector2(130, vp.y - 160)
	var bd: = JOY_RADIUS * 2.0
	_joy_base.size = Vector2(bd, bd)
	_joy_base.position = _joy_center - Vector2(JOY_RADIUS, JOY_RADIUS)
	_joy_base.add_theme_stylebox_override("panel", _circle_style(bd, Color(1, 1, 1, 0.05), 2, Color(ACCENT.r, ACCENT.g, ACCENT.b, 0.5)))
	var kd: = JOY_RADIUS * 1.15
	_joy_knob.size = Vector2(kd, kd)
	_joy_knob.add_theme_stylebox_override("panel", _circle_style(kd, Color(ACCENT.r, ACCENT.g, ACCENT.b, 0.85), 0, Color.TRANSPARENT, true))
	_joy_knob.position = _joy_center - Vector2(kd / 2.0, kd / 2.0)

func _update_joy(at: Vector2) -> void :
	var delta: = at - _joy_center
	if delta.length() > JOY_RADIUS:
		delta = delta.normalized() * JOY_RADIUS
	var kd: = JOY_RADIUS * 1.15
	_joy_knob.position = _joy_center + delta - Vector2(kd / 2.0, kd / 2.0)
	move_x = clampf(delta.x / JOY_RADIUS, -1.0, 1.0)

func _reset_joy() -> void :
	var kd: = JOY_RADIUS * 1.15
	_joy_knob.position = _joy_center - Vector2(kd / 2.0, kd / 2.0)
	move_x = 0.0


func _input(event: InputEvent) -> void :
	if not visible:
		return
	if _edit_mode:
		_handle_edit_input(event)
		return
	if event is InputEventScreenTouch or event is InputEventMouseButton:
		var pressed: bool = event.pressed
		var pos: Vector2 = event.position
		if pressed and not _hit_button(pos) and pos.distance_to(_joy_center) < JOY_RADIUS * 1.8:
			_joy_id = event.index if event is InputEventScreenTouch else 0
			_update_joy(pos)
			return
		if _joy_id != -1:
			if event is InputEventScreenTouch and event.index != _joy_id:
				return
			if pressed:
				_update_joy(pos)
			else:
				_joy_id = -1
				_reset_joy()
	elif event is InputEventScreenDrag:
		if _joy_id != -1 and event.index == _joy_id:
			_update_joy(event.position)
	elif event is InputEventMouseMotion and _joy_id == 0:
		_update_joy(event.position)

func _hit_button(pos: Vector2) -> bool:
	for b in _buttons.values():
		if b.get_global_rect().has_point(pos):
			return true
	return false

func _button_at(pos: Vector2) -> String:
	for name in _buttons:
		if _buttons[name].get_global_rect().has_point(pos):
			return name
	return ""


func _handle_edit_input(event: InputEvent) -> void :

	var pos: = Vector2(-1.0, -1.0)
	if event is InputEventScreenTouch or event is InputEventMouseButton or event is InputEventScreenDrag or event is InputEventMouseMotion:
		pos = event.position
	if _done_btn.visible and pos.x >= 0.0 and _done_btn.get_global_rect().has_point(pos):
		return

	if pos.x >= 0.0:
		if (_btn_plus.visible and _btn_plus.get_global_rect().has_point(pos)) or (_btn_minus.visible and _btn_minus.get_global_rect().has_point(pos)):
			return
	if event is InputEventScreenTouch:
		var idx: int = event.index
		if event.pressed:
			_edit_fingers[idx] = event.position
			var hit: = _button_at(event.position)
			if hit != "":
				_drag_name = hit
				_selected_name = hit
				_drag_grab = event.position - _buttons[hit].position
				_buttons[hit].scale = Vector2(0.94, 0.94)
				_place_size_controls()
		else:
			_edit_fingers.erase(idx)
			_drag_name = ""
			for b in _buttons.values():
				b.scale = Vector2.ONE
			_save_layout()
		get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag:
		if not _edit_fingers.has(event.index):
			return
		_edit_fingers[event.index] = event.position
		if _drag_name == "":
			return
		var vp: = get_viewport().get_visible_rect().size
		var b: Control = _buttons[_drag_name]
		b.position = event.position - _drag_grab
		b.position = Vector2(clampf(b.position.x, 0.0, vp.x - b.size.x), clampf(b.position.y, 0.0, vp.y - b.size.y))
		_place_size_controls()
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_edit_fingers[-1] = event.position
				var hit: = _button_at(event.position)
				if hit != "":
					_drag_name = hit
					_selected_name = hit
					_drag_grab = event.position - _buttons[hit].position
					_buttons[hit].scale = Vector2(0.94, 0.94)
					_place_size_controls()
			else:
				_edit_fingers.erase(-1)
				_drag_name = ""
				for b in _buttons.values():
					b.scale = Vector2.ONE
				_save_layout()
			get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and _drag_name != "":
		var vp: = get_viewport().get_visible_rect().size
		var b: Control = _buttons[_drag_name]
		b.position = event.position - _drag_grab
		b.position = Vector2(clampf(b.position.x, 0.0, vp.x - b.size.x), clampf(b.position.y, 0.0, vp.y - b.size.y))
		get_viewport().set_input_as_handled()

func _on_button_gui_input(event: InputEvent, name: String) -> void :
	if not visible:
		return
	if _edit_mode:
		return
	if event is InputEventScreenTouch or event is InputEventMouseButton:
		var b: PanelContainer = _buttons[name]
		if event.pressed:
			b.scale = Vector2(0.88, 0.88)
			b.modulate = Color(1.15, 1.1, 1.0, 1.0)
			_bursts[name].restart()
			_press_action(name, true)
		else:
			b.scale = Vector2.ONE
			b.modulate = Color.WHITE
			_press_action(name, false)

func _press_action(name: String, on: bool) -> void :
	match name:
		"jump":
			if on: Input.action_press("jump")
			else: Input.action_release("jump")
		"dash":
			if on: Input.action_press("dash")
			else: Input.action_release("dash")
		"interact":
			if on: Input.action_press("interact")
			else: Input.action_release("interact")
		"menu":
			if on:
				var pm: = get_node_or_null("/root/PauseMenu")
				if pm: pm._toggle()

func _tap(action: String) -> void :
	Input.action_press(action)
	await get_tree().process_frame
	Input.action_release(action)


func _set_button_size(name: String, d: float) -> void :
	d = clampf(d, 50.0, 200.0)
	var b: PanelContainer = _buttons[name]
	b.size = Vector2(d, d)
	b.custom_minimum_size = Vector2(d, d)
	var is_primary: bool = name == "jump"
	var bg: = Color(0.06, 0.055, 0.075, 0.55) if not is_primary else Color(0.14, 0.1, 0.05, 0.65)
	var bc: = Color(ACCENT.r, ACCENT.g, ACCENT.b, 0.6) if not is_primary else Color(ACCENT.r, ACCENT.g, ACCENT.b, 0.95)
	b.add_theme_stylebox_override("panel", _circle_style(d, bg, 1, bc, is_primary))
	var lbl: = b.get_child(0) as Label
	if lbl:
		lbl.add_theme_font_size_override("font_size", int(d * (0.34 if is_primary else 0.3)))
	var p: CPUParticles2D = _bursts[name]
	if p:
		p.position = Vector2(d / 2.0, d / 2.0)
		p.emission_sphere_radius = d * 0.45

func set_edit_mode(v: bool) -> void :
	_edit_mode = v
	_done_btn.visible = v
	_scrub_overlay.visible = v
	if not v:
		_edit_fingers.clear()
		_drag_name = ""
		_selected_name = ""
		_btn_plus.visible = false
		_btn_minus.visible = false
		for b in _buttons.values():
			b.scale = Vector2.ONE
			b.modulate = Color.WHITE
		_save_layout()

func set_debug_visible(v: bool) -> void :
	visible = v


func _load_layout() -> void :
	var vp: = get_viewport().get_visible_rect().size
	var defaults: = {
		"jump": Vector2(vp.x - 160, vp.y - 180), 
		"dash": Vector2(vp.x - 270, vp.y - 120), 
		"interact": Vector2(vp.x - 140, vp.y - 310), 
		"menu": Vector2(22, 22), 
	}
	var cfg: = ConfigFile.new()
	var has: = cfg.load(CONFIG_PATH) == OK
	for name in _buttons:
		var pos: Vector2 = defaults[name]
		if has and cfg.has_section_key("pos", name):
			var fv: Vector2 = cfg.get_value("pos", name, Vector2.ZERO)
			pos = Vector2(fv.x * vp.x, fv.y * vp.y)
		_buttons[name].position = pos
		if has and cfg.has_section_key("size", name):
			_set_button_size(name, float(cfg.get_value("size", name, _buttons[name].size.x)))

func _save_layout() -> void :
	var vp: = get_viewport().get_visible_rect().size
	var cfg: = ConfigFile.new()
	for name in _buttons:
		var p: Vector2 = _buttons[name].position
		cfg.set_value("pos", name, Vector2(p.x / vp.x, p.y / vp.y))
		cfg.set_value("size", name, _buttons[name].size.x)
	cfg.save(CONFIG_PATH)
