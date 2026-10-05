extends CanvasLayer


const ACCENT: = Color(0.835, 0.698, 0.42)
const PANEL_BG: = Color(0.075, 0.07, 0.085, 0.94)
const TEXT_COLOR: = Color(0.965, 0.94, 0.86)
const CONFIG_PATH: = "user://pause_settings.cfg"
const REBIND_ACTIONS: = ["move_left", "move_right", "jump", "dash", "interact"]
const ACTION_LABELS: = {"move_left": "左移", "move_right": "右移", "jump": "跳跃", "dash": "冲刺", "interact": "交互"}

var _dim: ColorRect
var _panel_main: PanelContainer
var _panel_settings: PanelContainer
var _volume_slider: HSlider
var _key_buttons: Dictionary = {}
var _is_open: = false
var _rebinding_action: = ""

func _ready() -> void :
	layer = 300
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_build_ui()
	_load_settings()


func _build_ui() -> void :
	_dim = ColorRect.new()
	_dim.color = Color(0, 0, 0, 0.55)
	_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_dim.visible = false
	add_child(_dim)


	_panel_main = _make_panel()
	add_child(_panel_main)
	var margin_m: = MarginContainer.new()
	margin_m.add_theme_constant_override("margin_left", 40)
	margin_m.add_theme_constant_override("margin_right", 40)
	margin_m.add_theme_constant_override("margin_top", 30)
	margin_m.add_theme_constant_override("margin_bottom", 30)
	_panel_main.add_child(margin_m)
	var vb: = VBoxContainer.new()
	vb.add_theme_constant_override("separation", 16)
	margin_m.add_child(vb)
	vb.add_child(_make_title("菜 单"))
	vb.add_child(_make_button("继续游戏", _on_continue))
	vb.add_child(_make_button("设 置", _on_open_settings))
	vb.add_child(_make_button("返回标题", _on_return_title))


	_panel_settings = _make_panel()
	_panel_settings.visible = false
	add_child(_panel_settings)
	var margin_s: = MarginContainer.new()
	margin_s.add_theme_constant_override("margin_left", 40)
	margin_s.add_theme_constant_override("margin_right", 40)
	margin_s.add_theme_constant_override("margin_top", 30)
	margin_s.add_theme_constant_override("margin_bottom", 30)
	_panel_settings.add_child(margin_s)
	var sb: = VBoxContainer.new()
	sb.add_theme_constant_override("separation", 16)
	margin_s.add_child(sb)
	sb.add_child(_make_title("设 置"))


	var vol_row: = HBoxContainer.new()
	vol_row.add_theme_constant_override("separation", 14)
	var vol_lbl: = Label.new()
	vol_lbl.text = "音量"
	vol_lbl.add_theme_font_size_override("font_size", 20)
	vol_lbl.add_theme_color_override("font_color", TEXT_COLOR)
	vol_row.add_child(vol_lbl)
	_volume_slider = HSlider.new()
	_volume_slider.min_value = 0.0
	_volume_slider.max_value = 100.0
	_volume_slider.value = 80.0
	_volume_slider.custom_minimum_size = Vector2(240, 20)
	_volume_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_volume_slider.value_changed.connect(_on_volume_changed)
	vol_row.add_child(_volume_slider)
	sb.add_child(vol_row)

	sb.add_child(_make_divider())


	for action in REBIND_ACTIONS:
		var row: = HBoxContainer.new()
		row.add_theme_constant_override("separation", 14)
		var lbl: = Label.new()
		lbl.text = ACTION_LABELS[action]
		lbl.custom_minimum_size = Vector2(70, 0)
		lbl.add_theme_font_size_override("font_size", 20)
		lbl.add_theme_color_override("font_color", TEXT_COLOR)
		var btn: = Button.new()
		btn.custom_minimum_size = Vector2(160, 40)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.add_theme_font_size_override("font_size", 18)
		btn.add_theme_color_override("font_color", ACCENT)
		btn.pressed.connect(_on_rebind_pressed.bind(action))
		_key_buttons[action] = btn
		row.add_child(lbl)
		row.add_child(btn)
		sb.add_child(row)


	var is_mobile: = OS.has_feature("android") or OS.has_feature("ios") or OS.has_feature("mobile")
	if is_mobile:
		sb.add_child(_make_divider())
		sb.add_child(_make_button("触屏布局：编辑位置", _on_touch_edit))
	sb.add_child(_make_button("返 回", _on_back_main))
	_refresh_key_labels()

func _make_panel() -> PanelContainer:
	var p: = PanelContainer.new()
	p.set_anchors_preset(Control.PRESET_CENTER)
	p.grow_horizontal = Control.GROW_DIRECTION_BOTH
	p.grow_vertical = Control.GROW_DIRECTION_BOTH
	var s: = StyleBoxFlat.new()
	s.bg_color = PANEL_BG
	s.set_corner_radius_all(16)
	s.set_border_width_all(1)
	s.border_color = Color(ACCENT.r, ACCENT.g, ACCENT.b, 0.55)
	s.shadow_color = Color(0, 0, 0, 0.55)
	s.shadow_size = 28
	s.shadow_offset = Vector2(0, 12)
	p.add_theme_stylebox_override("panel", s)
	return p

func _make_title(t: String) -> Label:
	var l: = Label.new()
	l.text = t
	l.add_theme_font_size_override("font_size", 28)
	l.add_theme_color_override("font_color", ACCENT)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return l

func _make_divider() -> ColorRect:
	var d: = ColorRect.new()
	d.color = Color(ACCENT.r, ACCENT.g, ACCENT.b, 0.35)
	d.custom_minimum_size = Vector2(0, 1)
	return d

func _make_button(t: String, cb: Callable) -> Button:
	var b: = Button.new()
	b.text = t
	b.custom_minimum_size = Vector2(220, 46)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.add_theme_font_size_override("font_size", 20)
	b.add_theme_color_override("font_color", TEXT_COLOR)
	b.add_theme_stylebox_override("normal", _btn_style(false))
	b.add_theme_stylebox_override("hover", _btn_style(true))
	b.add_theme_stylebox_override("pressed", _btn_style(false, true))
	b.pressed.connect(cb)
	return b

func _btn_style(hovered: bool, pressed: = false) -> StyleBoxFlat:
	var s: = StyleBoxFlat.new()
	s.bg_color = Color(0.12, 0.11, 0.13, 0.95) if not hovered else Color(0.2, 0.18, 0.2, 0.98)
	s.set_corner_radius_all(12)
	s.set_border_width_all(1)
	s.border_color = Color(ACCENT.r, ACCENT.g, ACCENT.b, 0.95 if hovered else 0.3)
	s.content_margin_left = 16
	s.content_margin_right = 16
	s.content_margin_top = 10
	s.content_margin_bottom = 10
	return s


func _unhandled_input(event: InputEvent) -> void :

	if _rebinding_action != "":
		if event is InputEventKey and event.pressed and not event.echo:
			if event.physical_keycode == KEY_ESCAPE:
				_cancel_rebind()
			else:
				_apply_key(_rebinding_action, event)
			get_viewport().set_input_as_handled()
			return
		return
	if event.is_action_pressed("ui_cancel"):
		_toggle()
		get_viewport().set_input_as_handled()

func _toggle() -> void :
	if _is_open:
		_close()
	else:
		_open()

func _open() -> void :
	var dm: = get_parent().get_node_or_null("DialogueManager")
	if dm and dm.active:
		return
	_is_open = true
	visible = true
	_dim.visible = true
	_panel_main.visible = true
	_panel_settings.visible = false
	get_tree().paused = true

func _close() -> void :
	_is_open = false
	visible = false
	_dim.visible = false
	get_tree().paused = false
	_cancel_rebind()
	_save_settings()

func _on_return_title() -> void :
	_close()
	get_tree().change_scene_to_file("res://title_screen.tscn")

func _on_continue() -> void :
	_close()

func _on_open_settings() -> void :
	_panel_main.visible = false
	_panel_settings.visible = true

func _on_back_main() -> void :
	_panel_settings.visible = false
	_panel_main.visible = true


func _on_volume_changed(v: float) -> void :
	AudioServer.set_bus_volume_db(0, linear_to_db(clampf(v, 0.1, 100.0) / 100.0))

func _on_rebind_pressed(action: String) -> void :
	_rebinding_action = action
	_key_buttons[action].text = "按新按键…"

func _cancel_rebind() -> void :
	_rebinding_action = ""
	_refresh_key_labels()

func _apply_key(action: String, key_event: InputEventKey) -> void :
	InputMap.action_erase_events(action)
	var e: = InputEventKey.new()
	e.physical_keycode = key_event.physical_keycode
	InputMap.action_add_event(action, e)
	_rebinding_action = ""
	_refresh_key_labels()
	_save_settings()

func _refresh_key_labels() -> void :
	for action in REBIND_ACTIONS:
		var name: = "未设置"
		for e in InputMap.action_get_events(action):
			if e is InputEventKey:
				name = OS.get_keycode_string(e.physical_keycode)
				break
		_key_buttons[action].text = name


func _save_settings() -> void :
	var cfg: = ConfigFile.new()
	cfg.set_value("audio", "master_volume", _volume_slider.value)
	for action in REBIND_ACTIONS:
		for e in InputMap.action_get_events(action):
			if e is InputEventKey:
				cfg.set_value("keys", action, int(e.physical_keycode))
				break
	cfg.save(CONFIG_PATH)

func _load_settings() -> void :
	var cfg: = ConfigFile.new()
	if cfg.load(CONFIG_PATH) != OK:
		return
	var v = cfg.get_value("audio", "master_volume", 80.0)
	_volume_slider.value = v
	_on_volume_changed(v)
	for action in REBIND_ACTIONS:
		if cfg.has_section_key("keys", action):
			var k = int(cfg.get_value("keys", action, 0))
			if k != 0:
				InputMap.action_erase_events(action)
				var e: = InputEventKey.new()
				e.physical_keycode = k
				InputMap.action_add_event(action, e)

var _touch_previewing: = false
var _touch_editing: = false

func _on_touch_edit() -> void :
	var mc: = get_node_or_null("/root/MobileControls")
	if mc:
		mc.set_edit_mode(true)
		_close()
