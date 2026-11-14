extends CanvasLayer


var _panel: PanelContainer
var _deco: Control
var _scan: ColorRect
var _accent: ColorRect
var _title: Label
var _body: Label
var _footer: Label
var _kill: Label
var _panel_home: Vector2
var _panel_size: = Vector2(520, 164)
var _finished: = false

func _ready() -> void :
	layer = 9
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	_play()

func _build() -> void :
	var root: = Control.new()
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root)
	var view: = get_viewport().get_visible_rect().size

	_panel = PanelContainer.new()
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.clip_contents = true
	_panel.size = _panel_size
	_panel_home = Vector2(26.0, view.y - _panel_size.y - 26.0)
	_panel.position = _panel_home + Vector2(-60, 0)
	_panel.modulate.a = 0.0
	_panel.add_theme_stylebox_override("panel", _panel_style())
	root.add_child(_panel)

	var margin: = MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_left", 22)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_bottom", 14)
	_panel.add_child(margin)

	var box: = VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", 6)
	margin.add_child(box)

	var header: = HBoxContainer.new()
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.add_theme_constant_override("separation", 8)
	box.add_child(header)

	var icon: = Label.new()
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.text = "!"
	icon.add_theme_font_override("font", _font())
	icon.add_theme_font_size_override("font_size", 26)
	icon.add_theme_color_override("font_color", Color(1.0, 0.18, 0.08))
	header.add_child(icon)

	var warn: = Label.new()
	warn.mouse_filter = Control.MOUSE_FILTER_IGNORE
	warn.text = "WARNING  //  警报"
	warn.add_theme_font_override("font", _font())
	warn.add_theme_font_size_override("font_size", 16)
	warn.add_theme_color_override("font_color", Color(1.0, 0.28, 0.16))
	header.add_child(warn)

	var spacer: = Control.new()
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)

	var live: = Label.new()
	live.mouse_filter = Control.MOUSE_FILTER_IGNORE
	live.text = "LIVE"
	live.add_theme_font_override("font", _font())
	live.add_theme_font_size_override("font_size", 11)
	live.add_theme_color_override("font_color", Color(1.0, 0.55, 0.25, 0.9))
	header.add_child(live)

	_title = Label.new()
	_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_title.text = "警告，目标已离开核心城区。"
	_title.add_theme_font_override("font", _font())
	_title.add_theme_font_size_override("font_size", 22)
	_title.add_theme_color_override("font_color", Color(1.0, 0.9, 0.82))
	_title.add_theme_color_override("font_shadow_color", Color(0.35, 0.01, 0.01, 0.75))
	_title.add_theme_constant_override("shadow_outline_size", 6)
	_title.visible_characters = 0
	box.add_child(_title)

	_body = Label.new()
	_body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_body.text = "该地区平民已确认撤离。"
	_body.add_theme_font_override("font", _font())
	_body.add_theme_font_size_override("font_size", 16)
	_body.add_theme_color_override("font_color", Color(0.78, 0.72, 0.65))
	_body.visible_characters = 0
	box.add_child(_body)

	var footer_row: = HBoxContainer.new()
	footer_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	footer_row.add_theme_constant_override("separation", 10)
	box.add_child(footer_row)
	_footer = Label.new()
	_footer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_footer.text = "授权使用致命武力"
	_footer.add_theme_font_override("font", _font())
	_footer.add_theme_font_size_override("font_size", 15)
	_footer.add_theme_color_override("font_color", Color(1.0, 0.62, 0.22))
	_footer.visible_characters = 0
	footer_row.add_child(_footer)
	var dash: = Label.new()
	dash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dash.text = "——"
	dash.add_theme_font_override("font", _font())
	dash.add_theme_font_size_override("font_size", 15)
	dash.add_theme_color_override("font_color", Color(0.9, 0.2, 0.08))
	footer_row.add_child(dash)
	_kill = Label.new()
	_kill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_kill.text = "猎杀程序启动"
	_kill.add_theme_font_override("font", _font())
	_kill.add_theme_font_size_override("font_size", 18)
	_kill.add_theme_color_override("font_color", Color(1.0, 0.2, 0.08))
	_kill.add_theme_color_override("font_shadow_color", Color(0.4, 0.01, 0.0, 0.6))
	_kill.add_theme_constant_override("shadow_outline_size", 3)
	_kill.modulate.a = 0.0
	footer_row.add_child(_kill)

	_deco = Control.new()
	_deco.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(_deco)
	_accent = ColorRect.new()
	_accent.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_accent.color = Color(1.0, 0.12, 0.05, 0.95)
	_accent.position = Vector2(0, 0)
	_accent.size = Vector2(4, _panel_size.y)
	_deco.add_child(_accent)

	_scan = ColorRect.new()
	_scan.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_scan.color = Color(1.0, 0.3, 0.15, 0.12)
	_scan.position = Vector2(0, 8)
	_scan.size = Vector2(_panel_size.x, 2)
	_deco.add_child(_scan)

	for corner in [Vector2(10, 10), Vector2(_panel_size.x - 18, 10), Vector2(10, _panel_size.y - 12), Vector2(_panel_size.x - 18, _panel_size.y - 12)]:
		var mark: = ColorRect.new()
		mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
		mark.color = Color(1.0, 0.28, 0.12, 0.9)
		mark.position = corner
		mark.size = Vector2(8, 2)
		_deco.add_child(mark)

func _play() -> void :
	_shake_camera(3.0)
	var tw: = create_tween()
	tw.set_parallel(true)
	tw.tween_property(_panel, "position", _panel_home, 0.34).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(_panel, "modulate:a", 1.0, 0.24)

	var type_tw: = create_tween()
	type_tw.tween_interval(0.18)
	type_tw.tween_method( func(n: float) -> void :
		_title.visible_characters = int(n)
	, 0.0, float(_title.text.length()), 0.85)
	type_tw.tween_interval(0.08)
	type_tw.tween_method( func(n: float) -> void :
		_body.visible_characters = int(n)
	, 0.0, float(_body.text.length()), 0.62)
	type_tw.tween_interval(0.08)
	type_tw.tween_method( func(n: float) -> void :
		_footer.visible_characters = int(n)
	, 0.0, float(_footer.text.length()), 0.55)
	type_tw.tween_property(_kill, "modulate:a", 1.0, 0.14)

	var out_tw: = create_tween()
	out_tw.tween_interval(4.1)
	out_tw.tween_property(_panel, "position", _panel_home + Vector2(-580, 0), 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	out_tw.parallel().tween_property(_panel, "modulate:a", 0.0, 0.3)
	out_tw.tween_callback(queue_free)

func _process(_delta: float) -> void :
	if _finished:
		return
	var t: = Time.get_ticks_msec() * 0.001
	_scan.position.y = 14.0 + fmod(t * 46.0, _panel_size.y - 24.0)
	_scan.color.a = 0.06 + 0.05 * (0.5 + 0.5 * sin(t * 4.0))
	_accent.color.a = 0.55 + 0.45 * (0.5 + 0.5 * sin(t * 3.2))
	if _kill.modulate.a > 0.1:
		_kill.modulate.a = 0.78 + 0.22 * (0.5 + 0.5 * sin(t * 8.0))

func _panel_style() -> StyleBoxFlat:
	var s: = StyleBoxFlat.new()
	s.bg_color = Color(0.055, 0.012, 0.012, 0.92)
	s.border_width_left = 1
	s.border_width_top = 1
	s.border_width_right = 1
	s.border_width_bottom = 1
	s.border_color = Color(1.0, 0.18, 0.08, 0.5)
	s.corner_radius_top_left = 3
	s.corner_radius_top_right = 3
	s.corner_radius_bottom_left = 3
	s.corner_radius_bottom_right = 3
	s.shadow_color = Color(0.0, 0.0, 0.0, 0.55)
	s.shadow_size = 16
	s.shadow_offset = Vector2(0, 6)
	return s

func _font() -> Font:
	return load("res://fonts/TitleFont.ttf") as Font

func _shake_camera(amount: float) -> void :
	var cam: = get_viewport().get_camera_2d()
	if cam == null:
		return
	var base: = cam.offset
	var tw: = create_tween()
	for i in range(3):
		var a: = amount * (1.0 - float(i) / 3.0)
		tw.tween_property(cam, "offset", base + Vector2(randf_range( - a, a), randf_range( - a * 0.5, a * 0.5)), 0.025)
	tw.tween_property(cam, "offset", base, 0.05)
