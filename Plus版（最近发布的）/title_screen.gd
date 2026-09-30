extends Control
const SAVE_PATH: = "user://progress.cfg"
const LIGHT_SAVE: = "user://collected_light.cfg"
const TOTAL_LIGHTS: = 22

var chapters = [
	{"id": "ch1", "button": "MainRow/Card1", "title": "收容所", "sub": "Chapter 01", "scene": "res://lab.tscn", "accent": Color(1.0, 0.85, 0.5)}, 
	{"id": "ch2", "button": "MainRow/Card2", "title": "城区高处", "sub": "Chapter 02", "scene": "res://city.tscn", "accent": Color(0.55, 0.7, 0.95)}, 
	{"id": "ch3", "button": "MainRow/Card3", "title": "雨水", "sub": "Chapter 03", "scene": "res://scene.tscn", "accent": Color(0.5, 0.85, 0.9)}, 
	{"id": "sp1", "button": "BranchRow/CardSP1", "title": "收容所", "sub": "Chapter SP1", "scene": "res://lab_B.tscn", "accent": Color(0.75, 0.6, 0.95)}, 
	{"id": "sp2", "button": "BranchRow/CardSP2", "title": "城区高处", "sub": "Chapter SP2", "scene": "res://city_B.tscn", "accent": Color(0.55, 0.9, 0.7)}, 
]

var _fade: ColorRect

func _ready() -> void :
	_fade = ColorRect.new()
	_fade.color = Color(0, 0, 0, 1)
	_fade.set_anchors_preset(PRESET_FULL_RECT)
	_fade.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(_fade)
	var tin: = create_tween()
	tin.tween_property(_fade, "color:a", 0.0, 0.6)
	_apply_unlocked_state()
	_update_light_count()
	_setup_dot()

func _is_unlocked(id: String) -> bool:
	if id == "ch1":
		return true
	var cfg: = ConfigFile.new()
	cfg.load(SAVE_PATH)
	return cfg.has_section_key("unlocked", id)

func _save_unlocked(id: String) -> void :
	var cfg: = ConfigFile.new()
	cfg.load(SAVE_PATH)
	cfg.set_value("unlocked", id, true)
	cfg.save(SAVE_PATH)

func _card_style(bg: Color, accent: Color) -> StyleBoxFlat:
	var s: = StyleBoxFlat.new()
	s.bg_color = bg
	s.set_corner_radius_all(12)
	s.set_border_width_all(1)
	s.border_color = accent * Color(1, 1, 1, 0.4)
	s.content_margin_left = 10
	s.content_margin_right = 10
	s.content_margin_top = 8
	s.content_margin_bottom = 8
	return s

func _apply_unlocked_state() -> void :
	for c in chapters:
		var btn: Button = get_node(c.button)
		var is_unlocked: = _is_unlocked(c.id)
		btn.disabled = not is_unlocked
		var sub_lbl: Label = btn.get_node("VBox/Sub")
		var name_lbl: Label = btn.get_node("VBox/Name")
		var acc: Color = c.accent
		if is_unlocked:
			sub_lbl.text = c.sub
			name_lbl.text = c.title
			sub_lbl.add_theme_color_override("font_color", Color(acc.r, acc.g, acc.b, 0.7))
			name_lbl.add_theme_color_override("font_color", Color(acc.r, acc.g, acc.b, 1.0))
			btn.add_theme_stylebox_override("normal", _card_style(Color(acc.r * 0.25, acc.g * 0.22, acc.b * 0.18, 0.92), acc))
			btn.add_theme_stylebox_override("hover", _card_style(Color(acc.r * 0.4, acc.g * 0.35, acc.b * 0.25, 0.95), acc))
			btn.add_theme_stylebox_override("pressed", _card_style(Color(acc.r * 0.55, acc.g * 0.48, acc.b * 0.35, 1.0), acc))
			btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		else:
			sub_lbl.text = "?"
			name_lbl.text = "?"
			sub_lbl.add_theme_color_override("font_color", Color(0.3, 0.3, 0.33))
			name_lbl.add_theme_color_override("font_color", Color(0.38, 0.38, 0.42))
			btn.add_theme_stylebox_override("normal", _card_style(Color(0.08, 0.08, 0.1, 0.9), Color(1, 1, 1, 0.05)))
			btn.add_theme_stylebox_override("hover", _card_style(Color(0.08, 0.08, 0.1, 0.9), Color(1, 1, 1, 0.05)))
			btn.add_theme_stylebox_override("pressed", _card_style(Color(0.08, 0.08, 0.1, 0.9), Color(1, 1, 1, 0.05)))
		btn.pressed.connect( func(): _on_selected(c))

func _update_light_count() -> void :
	var n: = 0
	var cfg: = ConfigFile.new()
	if cfg.load(LIGHT_SAVE) == OK and cfg.has_section("collected"):
		n = cfg.get_section_keys("collected").size()
	var pct: = int(float(n) / TOTAL_LIGHTS * 100.0)
	get_node("Bottom/LightCount").text = "已收集微光 x%d (%d%%)" % [n, pct]

func _make_glow_texture() -> Texture2D:
	var img: = Image.create(64, 64, false, Image.FORMAT_RGBA8)
	for y in range(64):
		for x in range(64):
			var dx: = x - 32.0
			var dy: = y - 32.0
			var d: = sqrt(dx * dx + dy * dy) / 32.0
			var a: = clampf(1.0 - d, 0.0, 1.0)
			a = a * a
			img.set_pixel(x, y, Color(1.0, 0.95, 0.7, a))
	return ImageTexture.create_from_image(img)

func _setup_dot() -> void :
	var dot_holder: Control = get_node("Bottom/Dot")
	for c in dot_holder.get_children():
		c.queue_free()

	var glow: = Sprite2D.new()
	glow.name = "Glow"
	glow.texture = _make_glow_texture()
	glow.scale = Vector2(0.35, 0.35)
	glow.modulate = Color(1.0, 0.95, 0.7, 1.0)
	glow.position = Vector2(14, 14)
	dot_holder.add_child(glow)

	var p: = CPUParticles2D.new()
	p.name = "Ambient"
	p.amount = 10
	p.lifetime = 1.5
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = 10.0
	p.spread = 180.0
	p.direction = Vector2(0, -1)
	p.gravity = Vector2(0, -10)
	p.initial_velocity_min = 5.0
	p.initial_velocity_max = 12.0
	p.scale_amount_min = 0.5
	p.scale_amount_max = 1.5
	p.color = Color(1.0, 0.95, 0.7, 1.0)
	p.emitting = true
	p.position = Vector2(14, 14)
	dot_holder.add_child(p)
	var tw: = create_tween()
	tw.set_loops()
	tw.tween_property(glow, "scale", Vector2(0.4, 0.4), 0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(glow, "scale", Vector2(0.3, 0.3), 0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _on_selected(c) -> void :
	_save_unlocked(c.id)
	_fade.mouse_filter = MOUSE_FILTER_STOP
	if c.id == "ch1":
		_show_intro_text(c.scene)
	else:
		var out: = create_tween()
		out.tween_property(_fade, "color:a", 1.0, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		out.tween_callback(_do_transition.bind(c.scene))

func _show_intro_text(scene_path: String) -> void :
	_fade.color = Color(0, 0, 0, 1)
	var label: = Label.new()
	label.text = ""
	label.add_theme_font_size_override("font_size", 36)
	label.add_theme_color_override("font_color", Color(1, 0.92, 0.7))
	label.add_theme_color_override("font_shadow_color", Color(1, 0.85, 0.5, 0.6))
	label.add_theme_constant_override("shadow_offset_x", 0)
	label.add_theme_constant_override("shadow_offset_y", 0)
	label.add_theme_constant_override("shadow_outline_size", 8)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.set_anchors_preset(PRESET_FULL_RECT)
	label.mouse_filter = MOUSE_FILTER_IGNORE
	label.modulate.a = 0.0
	add_child(label)

	var line1: = "你叫流明，生活在收容所中。"
	var line2: = "一天晚上，某个熟悉的身影帮你打开了笼锁……"

	var tw: = create_tween()

	tw.tween_property(label, "modulate:a", 1.0, 1.0)

	tw.tween_method( func(n: float):
		label.text = line1.substr(0, int(n)), 0, line1.length(), line1.length() * 0.06)

	tw.tween_interval(0.8)

	tw.tween_method( func(n: float):
		label.text = line1 + "\n" + line2.substr(0, int(n)), 0, line2.length(), line2.length() * 0.06)

	tw.tween_interval(1.5)

	tw.tween_property(label, "modulate:a", 0.0, 1.0)

	tw.tween_callback(_do_transition.bind(scene_path))

func _do_transition(scene_path: String) -> void :
	get_tree().change_scene_to_file(scene_path)
