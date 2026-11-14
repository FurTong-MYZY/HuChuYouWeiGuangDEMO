extends Node2D



const VIEW: = Vector2(1152, 648)
const WORLD_SCALE: = 4.73
const FONT_PATH: = "res://fonts/TitleFont.ttf"
const TITLE_SCENE: = "res://title_screen.tscn"

var _platforms: Array[Rect2] = []
var _stars: Array[Dictionary] = []
var _balloons: Array[Dictionary] = []
var _time: float = 0.0
var _started: = false
var _finale: = false
var _card_open: = false
var _checkin_done: = false
var _visits: = 0
var _last_checkin: = ""
var _collected: = 0
var _wish: = "愿你所愿，皆有回响。"
var _wish_color: = Color(1.0, 0.58, 0.62)

var player: CharacterBody2D
var _candles: Array[Node2D] = []
var _cake: Node2D
var _ui: CanvasLayer
var _count_label: Label
var _prompt_label: Label
var _toast: PanelContainer
var _toast_title: Label
var _toast_label: Label
var _toast_tween: Tween
var _intro_layer: CanvasLayer
var _intro_root: Control
var _fx_layer: CanvasLayer
var _sfx: AudioStreamPlayer
var _soft_tex: Texture2D
var _saved_label: Label
var _outfit_panel: PanelContainer
var _outfit_overlay: Node2D
var _camera: Camera2D
var _player_name: String = "流明"
var _name_input: LineEdit
var _intro_title: Label
var _chapter_label: Label
var _outfit_sub_label: Label
var _outfit_status: Label
var _hat: = "party"
var _outfit: = "scarf"
var _tint: = "warm"

var _memories: = [
	{"title": "第一段记忆", "text": "收容所里，你睁开眼，看见的是牢笼外的月光。"}, 
	{"title": "第二段记忆", "text": "城区高处，你穿越重重阻碍，发现原来自己也能跑得这么远。"}, 
	{"title": "第三段记忆", "text": "霓虹雨夜之中，你在雨水中行进，在那些闪烁的灯牌中穿行"}, 
	{"title": "第四段记忆", "text": "警报声里，你逃过重重追捕，奔向自由，奔向远方。"}, 
	{"title": "第五段记忆", "text": "谢谢你，感谢陪伴。"}, 
]
var _photo_texture: Texture2D = null

func _ready() -> void :
	var mc: = get_node_or_null("/root/MobileControls")
	if mc:
		mc.visible = mc.MOBILE
	_load_checkin()
	_load_player_name()
	_soft_tex = _make_soft_texture()
	_build_world()
	_load_outfit()
	_build_ui()
	_build_outfit_panel()
	_build_intro()
	_build_ambient()
	_add_music()
	queue_redraw()

func _randomize_decor() -> void :
	seed(20261112)
	for i in range(96):
		_stars.append({
			"p": Vector2(randf_range(20, 1132), randf_range(18, 420)), 
			"r": randf_range(0.7, 2.0), 
			"a": randf_range(0.25, 0.9), 
		})
	var colors: = [
		Color(1.0, 0.55, 0.62), Color(1.0, 0.78, 0.4), Color(0.6, 0.7, 1.0), 
		Color(0.7, 0.55, 1.0), Color(0.55, 0.9, 0.8)
	]
	for i in range(7):
		_balloons.append({
			"p": Vector2(70 + i * 166 + randf_range(-30, 30), 150 + randf_range(-55, 65)), 
			"c": colors[i % colors.size()], 
			"s": randf_range(0.75, 1.25), 
		})

func _load_checkin() -> void :
	var cfg: = ConfigFile.new()
	if cfg.load("user://birthday_checkin.cfg") == OK:
		_visits = int(cfg.get_value("birthday", "visits", 0))
		_last_checkin = String(cfg.get_value("birthday", "last_date", ""))

func _commit_checkin() -> void :
	if _checkin_done:
		return
	_checkin_done = true
	_visits += 1
	_last_checkin = _date_string()
	var cfg: = ConfigFile.new()
	cfg.load("user://birthday_checkin.cfg")
	cfg.set_value("birthday", "visits", _visits)
	cfg.set_value("birthday", "last_date", _last_checkin)
	cfg.save("user://birthday_checkin.cfg")

func _load_player_name() -> void :
	var cfg: = ConfigFile.new()
	if cfg.load("user://birthday_name.cfg") == OK:
		var n: = String(cfg.get_value("birthday", "name", "流明")).strip_edges()
		if not n.is_empty():
			_player_name = n

func _save_player_name() -> void :
	var cfg: = ConfigFile.new()
	cfg.set_value("birthday", "name", _player_name)
	cfg.save("user://birthday_name.cfg")

func _build_world() -> void :

	player = get_node("player")
	player.dialogue_locked = true
	player.global_position = Vector2(120, 596) * WORLD_SCALE
	var pui: = player.get_node_or_null("PlayerUI") as CanvasLayer
	if pui:
		pui.visible = false
	var danger: = player.get_node_or_null("DangerLayer") as CanvasLayer
	if danger:
		danger.visible = false
	_candles.clear()
	for c in get_node("WorldRoot/Candles").get_children():
		if c is Node2D:
			_candles.append(c)
	_cake = get_node("WorldRoot/Cake")
	_camera = get_node("BirthdayCamera")
	_camera.limit_left = 0
	_camera.limit_right = int(VIEW.x * WORLD_SCALE)
	_camera.limit_top = 0
	_camera.limit_bottom = int(VIEW.y * WORLD_SCALE)
	_outfit_overlay = get_node("OutfitLayer/OutfitOverlay")
	_outfit_overlay.player = player
	_outfit_overlay.set_outfit(_hat, _outfit, _tint)

func _build_ui() -> void :
	_ui = CanvasLayer.new()
	_ui.layer = 20
	add_child(_ui)
	var root: = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.add_child(root)

	var left: = VBoxContainer.new()
	left.position = Vector2(28, 24)
	left.add_theme_constant_override("separation", 4)
	root.add_child(left)
	var chapter: = Label.new()
	chapter.text = "BIRTHDAY CHAPTER  /  %s 的小小生日篇" % _player_name
	_chapter_label = chapter
	chapter.add_theme_font_override("font", load(FONT_PATH))
	chapter.add_theme_font_size_override("font_size", 15)
	chapter.add_theme_color_override("font_color", Color(1.0, 0.72, 0.64, 0.9))
	left.add_child(chapter)
	var sub: = Label.new()
	sub.text = "把今夜的五段记忆，留给一年后的你。"
	sub.add_theme_font_override("font", load(FONT_PATH))
	sub.add_theme_font_size_override("font_size", 12)
	sub.add_theme_color_override("font_color", Color(0.78, 0.7, 0.9, 0.7))
	left.add_child(sub)
	_count_label = Label.new()
	_count_label.text = "记忆蜡烛  0 / 5"
	_count_label.add_theme_font_override("font", load(FONT_PATH))
	_count_label.add_theme_font_size_override("font_size", 18)
	_count_label.add_theme_color_override("font_color", Color(1.0, 0.84, 0.56))
	left.add_child(_count_label)

	var back: = _make_button("退出  Esc" if OS.has_feature("birthday_dlc") else "返回标题  Esc", Vector2(28, 0), Vector2(170, 38))
	back.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	back.offset_left = -198
	back.offset_right = -28
	back.offset_top = 26
	back.offset_bottom = 64
	back.pressed.connect(_go_title)
	root.add_child(back)

	var dress: = _make_button("生日装扮", Vector2(28, 0), Vector2(170, 38))
	dress.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	dress.offset_left = -198
	dress.offset_right = -28
	dress.offset_top = 72
	dress.offset_bottom = 110
	dress.pressed.connect(_toggle_outfit)
	root.add_child(dress)

	_prompt_label = Label.new()
	_prompt_label.text = ""
	_prompt_label.add_theme_font_override("font", load(FONT_PATH))
	_prompt_label.add_theme_font_size_override("font_size", 18)
	_prompt_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.72))
	_prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt_label.position = Vector2(0, 528)
	_prompt_label.size = Vector2(VIEW.x, 32)
	root.add_child(_prompt_label)

	_toast = PanelContainer.new()
	_toast.position = Vector2(160, 86)
	_toast.custom_minimum_size = Vector2(840, 126)
	_toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toast.add_theme_stylebox_override("panel", _style(Color(0.08, 0.045, 0.11, 0.92), Color(1.0, 0.65, 0.52, 0.6), 1, 3))
	var margin: = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	_toast.add_child(margin)
	var v: = VBoxContainer.new()
	margin.add_child(v)
	_toast_title = Label.new()
	_toast_title.add_theme_font_override("font", load(FONT_PATH))
	_toast_title.add_theme_font_size_override("font_size", 12)
	_toast_title.add_theme_color_override("font_color", Color(1.0, 0.65, 0.55, 0.8))
	v.add_child(_toast_title)
	_toast_label = Label.new()
	_toast_label.add_theme_font_override("font", load(FONT_PATH))
	_toast_label.add_theme_font_size_override("font_size", 18)
	_toast_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.74))
	_toast_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_toast_label.custom_minimum_size = Vector2(790, 64)
	v.add_child(_toast_label)
	_toast.visible = false
	root.add_child(_toast)

	_fx_layer = CanvasLayer.new()
	_fx_layer.layer = 36
	add_child(_fx_layer)

func _build_outfit_panel() -> void :
	var layer: = CanvasLayer.new()
	layer.layer = 24
	add_child(layer)
	_outfit_panel = PanelContainer.new()
	_outfit_panel.position = Vector2(704, 142)
	_outfit_panel.custom_minimum_size = Vector2(420, 334)
	_outfit_panel.visible = false
	_outfit_panel.add_theme_stylebox_override("panel", _style(Color(0.07, 0.035, 0.1, 0.97), Color(0.65, 0.45, 1.0, 0.65), 1, 6))
	layer.add_child(_outfit_panel)
	var margin: = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_bottom", 14)
	_outfit_panel.add_child(margin)
	var v: = VBoxContainer.new()
	v.add_theme_constant_override("separation", 7)
	margin.add_child(v)
	var title: = Label.new()
	title.text = "BIRTHDAY DRESS-UP  /  生日装扮"
	title.add_theme_font_override("font", load(FONT_PATH))
	title.add_theme_font_size_override("font_size", 13)
	title.add_theme_color_override("font_color", Color(1.0, 0.72, 0.58))
	v.add_child(title)
	var sub: = Label.new()
	sub.text = "今天的%s，想戴什么出门？" % _player_name
	_outfit_sub_label = sub
	sub.add_theme_font_override("font", load(FONT_PATH))
	sub.add_theme_font_size_override("font_size", 12)
	sub.add_theme_color_override("font_color", Color(0.75, 0.7, 0.88, 0.8))
	v.add_child(sub)
	_outfit_row(v, "生日帽", [["无", "none"], ["彩帽", "party"], ["皇冠", "crown"], ["花环", "flower"]], "hat")
	_outfit_row(v, "配饰", [["无", "none"], ["星围巾", "scarf"], ["蝴蝶结", "bow"]], "outfit")
	_outfit_status = Label.new()
	_outfit_status.add_theme_font_override("font", load(FONT_PATH))
	_outfit_status.add_theme_font_size_override("font_size", 11)
	_outfit_status.add_theme_color_override("font_color", Color(1.0, 0.82, 0.6, 0.85))
	v.add_child(_outfit_status)
	var close: = _make_button("穿好了", Vector2.ZERO, Vector2(110, 30))
	close.size_flags_horizontal = Control.SIZE_SHRINK_END
	close.pressed.connect(_toggle_outfit)
	v.add_child(close)
	_update_outfit_status()

func _outfit_row(parent: VBoxContainer, title_text: String, options: Array, kind: String) -> void :
	var row: = HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	var lab: = Label.new()
	lab.text = title_text
	lab.custom_minimum_size = Vector2(72, 26)
	lab.add_theme_font_override("font", load(FONT_PATH))
	lab.add_theme_font_size_override("font_size", 12)
	lab.add_theme_color_override("font_color", Color(0.72, 0.65, 0.85))
	row.add_child(lab)
	for opt in options:
		var b: = Button.new()
		b.text = opt[0]
		b.add_theme_font_override("font", load(FONT_PATH))
		b.add_theme_font_size_override("font_size", 11)
		b.add_theme_color_override("font_color", Color(0.95, 0.86, 0.72))
		b.add_theme_stylebox_override("normal", _style(Color(0.14, 0.08, 0.2, 0.9), Color(0.5, 0.4, 0.8, 0.4), 1, 4))
		b.add_theme_stylebox_override("hover", _style(Color(0.28, 0.16, 0.38, 1.0), Color(1.0, 0.7, 0.5, 0.7), 1, 4))
		b.custom_minimum_size = Vector2(58, 26)
		b.pressed.connect(_apply_outfit.bind(kind, opt[1]))
		row.add_child(b)
	parent.add_child(row)

func _apply_outfit(kind: String, value: String) -> void :
	if kind == "hat":
		_hat = value
	elif kind == "outfit":
		_outfit = value
	else:
		_tint = value
	if _outfit_overlay:
		_outfit_overlay.set_outfit(_hat, _outfit, _tint)
	_update_outfit_status()
	_save_outfit()
	if player:
		_spark(player.global_position + Vector2(0, -80), Color(1.0, 0.7, 0.85))

func _update_outfit_status() -> void :
	if _outfit_status == null:
		return
	var hat_name: String = {"party": "彩帽", "crown": "皇冠", "flower": "花环", "none": "无"}.get(_hat, "彩帽")
	var outfit_name: String = {"scarf": "星围巾", "bow": "蝴蝶结", "none": "无"}.get(_outfit, "星围巾")
	_outfit_status.text = "当前：%s · %s" % [hat_name, outfit_name]

func _toggle_outfit() -> void :
	if _outfit_panel == null:
		return
	_outfit_panel.visible = not _outfit_panel.visible
	if _outfit_panel.visible:
		_outfit_panel.modulate.a = 0.0
		var tw: = create_tween()
		tw.tween_property(_outfit_panel, "modulate:a", 1.0, 0.18)

func _load_outfit() -> void :
	var cfg: = ConfigFile.new()
	if cfg.load("user://birthday_outfit.cfg") == OK:
		_hat = String(cfg.get_value("outfit", "hat", _hat))
		_outfit = String(cfg.get_value("outfit", "outfit", _outfit))
		_tint = String(cfg.get_value("outfit", "tint", _tint))
	if _outfit_overlay:
		_outfit_overlay.set_outfit(_hat, _outfit, _tint)

func _save_outfit() -> void :
	var cfg: = ConfigFile.new()
	cfg.set_value("outfit", "hat", _hat)
	cfg.set_value("outfit", "outfit", _outfit)
	cfg.set_value("outfit", "tint", _tint)
	cfg.save("user://birthday_outfit.cfg")

func _build_intro() -> void :
	_intro_layer = CanvasLayer.new()
	_intro_layer.layer = 40
	add_child(_intro_layer)
	_intro_root = Control.new()
	_intro_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_intro_root.mouse_filter = Control.MOUSE_FILTER_STOP
	_intro_layer.add_child(_intro_root)
	var dim: = ColorRect.new()
	dim.color = Color(0.018, 0.012, 0.035, 0.96)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_intro_root.add_child(dim)
	var center: = VBoxContainer.new()
	center.position = Vector2(0, 72)
	center.size = Vector2(VIEW.x, 540)
	center.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_theme_constant_override("separation", 9)
	_intro_root.add_child(center)
	var kicker: = Label.new()
	kicker.text = "A LITTLE BIRTHDAY CHAPTER"
	kicker.add_theme_font_override("font", load(FONT_PATH))
	kicker.add_theme_font_size_override("font_size", 13)
	kicker.add_theme_color_override("font_color", Color(1.0, 0.62, 0.54, 0.8))
	kicker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center.add_child(kicker)
	var title: = Label.new()
	_intro_title = title
	title.text = "给 %s" % _player_name
	title.add_theme_font_override("font", load(FONT_PATH))
	title.add_theme_font_size_override("font_size", 52)
	title.add_theme_color_override("font_color", Color(1.0, 0.9, 0.7))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center.add_child(title)
	var line: = Label.new()
	line.text = "一封没有署名的生日邀请，把你带进一个被微光点亮的小小世界。"
	line.add_theme_font_override("font", load(FONT_PATH))
	line.add_theme_font_size_override("font_size", 17)
	line.add_theme_color_override("font_color", Color(0.78, 0.72, 0.92))
	line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center.add_child(line)
	var story: = Label.new()
	story.text = "这里没有追捕，没有烦恼。只有一个由愿望折出的小小世界——\n以及五段记忆，和一盏等你吹灭的蜡烛。"
	story.add_theme_font_override("font", load(FONT_PATH))
	story.add_theme_font_size_override("font_size", 14)
	story.add_theme_color_override("font_color", Color(0.66, 0.62, 0.78, 0.9))
	story.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center.add_child(story)
	var name_row: = HBoxContainer.new()
	name_row.alignment = BoxContainer.ALIGNMENT_CENTER
	name_row.add_theme_constant_override("separation", 10)
	center.add_child(name_row)
	var name_label: = Label.new()
	name_label.text = "你的名字"
	name_label.add_theme_font_override("font", load(FONT_PATH))
	name_label.add_theme_font_size_override("font_size", 15)
	name_label.add_theme_color_override("font_color", Color(1.0, 0.78, 0.62))
	name_row.add_child(name_label)
	_name_input = LineEdit.new()
	_name_input.text = _player_name
	_name_input.placeholder_text = "流明"
	_name_input.max_length = 12
	_name_input.custom_minimum_size = Vector2(220, 34)
	_name_input.add_theme_font_override("font", load(FONT_PATH))
	_name_input.add_theme_font_size_override("font_size", 17)
	_name_input.add_theme_color_override("font_color", Color(1.0, 0.92, 0.78))
	_name_input.add_theme_stylebox_override("normal", _style(Color(0.1, 0.06, 0.14, 0.9), Color(1.0, 0.65, 0.48, 0.55), 1, 5))
	_name_input.add_theme_stylebox_override("focus", _style(Color(0.16, 0.09, 0.2, 0.95), Color(1.0, 0.82, 0.55, 0.9), 1, 5))
	name_row.add_child(_name_input)
	_name_input.text_changed.connect( func(t: String) -> void :
		var n: = t.strip_edges()
		_intro_title.text = "给 %s" % (n if not n.is_empty() else "流明")
	)
	var tip: = Label.new()
	tip.text = "收集五段记忆，回到蛋糕前吹灭蜡烛~"
	tip.add_theme_font_override("font", load(FONT_PATH))
	tip.add_theme_font_size_override("font_size", 14)
	tip.add_theme_color_override("font_color", Color(0.65, 0.62, 0.76, 0.85))
	tip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center.add_child(tip)
	var begin: = _make_button("开始这个夜晚", Vector2.ZERO, Vector2(220, 46))
	begin.custom_minimum_size = Vector2(220, 46)
	begin.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	begin.pressed.connect(_begin_intro)
	center.add_child(begin)

func _make_button(text: String, pos: Vector2, size: Vector2) -> Button:
	var b: = Button.new()
	b.text = text
	b.position = pos
	b.custom_minimum_size = size
	b.add_theme_font_override("font", load(FONT_PATH))
	b.add_theme_font_size_override("font_size", 15)
	b.add_theme_color_override("font_color", Color(1.0, 0.88, 0.7))
	b.add_theme_color_override("font_hover_color", Color(1.0, 0.98, 0.88))
	b.add_theme_stylebox_override("normal", _style(Color(0.16, 0.08, 0.13, 0.9), Color(1.0, 0.6, 0.5, 0.5), 1, 8))
	b.add_theme_stylebox_override("hover", _style(Color(0.28, 0.12, 0.19, 0.96), Color(1.0, 0.78, 0.55, 0.85), 1, 8))
	b.add_theme_stylebox_override("pressed", _style(Color(0.36, 0.16, 0.22, 1.0), Color(1.0, 0.85, 0.62, 1.0), 1, 8))
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	return b

func _style(bg: Color, border: Color, width: int, radius: int) -> StyleBoxFlat:
	var s: = StyleBoxFlat.new()
	s.bg_color = bg
	s.border_width_left = width
	s.border_width_top = width
	s.border_width_right = width
	s.border_width_bottom = width
	s.border_color = border
	s.set_corner_radius_all(radius)
	s.content_margin_left = 14
	s.content_margin_right = 14
	s.content_margin_top = 8
	s.content_margin_bottom = 8
	s.shadow_color = Color(0, 0, 0, 0.35)
	s.shadow_size = 8
	s.shadow_offset = Vector2(0, 4)
	return s

func _begin_intro() -> void :
	if _started:
		return
	var n: = ""
	if _name_input:
		n = _name_input.text.strip_edges()
	_player_name = n if not n.is_empty() else "流明"
	_save_player_name()
	if _intro_title:
		_intro_title.text = "给 %s" % _player_name
	if _chapter_label:
		_chapter_label.text = "BIRTHDAY CHAPTER  /  %s 的小小生日篇" % _player_name
	if _outfit_sub_label:
		_outfit_sub_label.text = "今天的%s，想戴什么出门？" % _player_name
	_started = true
	player.dialogue_locked = false
	var tw: = create_tween()
	tw.tween_property(_intro_root, "modulate:a", 0.0, 0.55)
	tw.tween_callback(_intro_layer.queue_free)

func _add_music() -> void :
	var m: Node = load("res://birthday_music.gd").new()
	add_child(m)
	_sfx = AudioStreamPlayer.new()
	_sfx.stream = load("res://sound/collect_light.wav")
	_sfx.volume_db = -5.0
	add_child(_sfx)

func _build_ambient() -> void :
	var p: = CPUParticles2D.new()
	p.amount = 34
	p.lifetime = 5.0
	p.preprocess = 3.0
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(570, 250)
	p.position = Vector2(576, 300)
	p.direction = Vector2(0, -1)
	p.spread = 60.0
	p.gravity = Vector2(0, -4)
	p.initial_velocity_min = 4.0
	p.initial_velocity_max = 16.0
	p.scale_amount_min = 0.03
	p.scale_amount_max = 0.09
	p.texture = _soft_tex
	var ramp: = Gradient.new()
	ramp.set_color(0, Color(1.0, 0.82, 0.5, 0.55))
	ramp.set_color(1, Color(1.0, 0.55, 0.6, 0.0))
	p.color_ramp = ramp
	p.emitting = true
	add_child(p)

func _process(delta: float) -> void :
	_time += delta
	if _camera and player:
		_camera.global_position = player.global_position
	if not _started or _finale:
		return
	_update_interactions()

func _update_interactions() -> void :
	if player == null or _card_open:
		return
	var nearest: Node2D = null
	var best: = 76.0 * WORLD_SCALE
	for c in _candles:
		if c.lit:
			continue
		var d: = player.global_position.distance_to(c.global_position)
		if d < best:
			best = d
			nearest = c
	if nearest:
		_prompt_label.text = "交互键  点亮这段记忆"
		if Input.is_action_just_pressed("interact"):
			_light_candle(nearest)
		return
	if _collected >= _candles.size() and _cake and player.global_position.distance_to(_cake.global_position) < 116.0 * WORLD_SCALE:
		_prompt_label.text = "交互键  吹灭蜡烛，收下祝福"
		if Input.is_action_just_pressed("interact"):
			_start_finale()
		return
	_prompt_label.text = ""

func _light_candle(candle: Node2D) -> void :
	candle.light_up()
	_collected += 1
	_count_label.text = "记忆蜡烛  %d / 5" % _collected
	_show_memory(candle.index)
	if _sfx:
		_sfx.play()
	_spark(candle.global_position + Vector2(0, -40), Color(1.0, 0.8, 0.45))
	if _collected >= _candles.size():
		_cake.light_up()
		_show_toast("五段记忆都已点亮", "回到蛋糕前，按 交互键 吹灭蜡烛。")

func _show_memory(index: int) -> void :
	if index < 0 or index >= _memories.size():
		return
	_show_toast(_memories[index]["title"], _memories[index]["text"])

func _show_toast(title: String, text: String) -> void :
	_toast_title.text = title
	_toast_label.text = text
	_toast.visible = true
	_toast.modulate.a = 0.0
	if _toast_tween and _toast_tween.is_valid():
		_toast_tween.kill()
	var tw: = create_tween()
	tw.tween_property(_toast, "modulate:a", 1.0, 0.2)
	tw.tween_interval(4.6)
	tw.tween_property(_toast, "modulate:a", 0.0, 0.35)
	tw.tween_callback( func() -> void : _toast.visible = false)
	_toast_tween = tw

func _spark(pos: Vector2, color: Color) -> void :
	var p: = CPUParticles2D.new()
	p.amount = 22
	p.one_shot = true
	p.emitting = true
	p.lifetime = 0.7
	p.direction = Vector2(0, -1)
	p.spread = 180.0
	p.gravity = Vector2(0, 120)
	p.initial_velocity_min = 40.0
	p.initial_velocity_max = 150.0
	p.scale_amount_min = 0.04
	p.scale_amount_max = 0.13
	p.texture = _soft_tex
	var ramp: = Gradient.new()
	ramp.set_color(0, color)
	ramp.set_color(1, Color(color.r, color.g, color.b, 0.0))
	p.color_ramp = ramp
	p.position = pos
	p.z_index = 9
	add_child(p)
	get_tree().create_timer(1.1).timeout.connect(p.queue_free)

func _capture_player_photo() -> void :

	var img: = get_viewport().get_texture().get_image()
	if img == null:
		return
	var screen: = get_viewport().get_canvas_transform() * player.global_position
	var rect: = Rect2(screen + Vector2(-150, -160), Vector2(300, 300))
	rect = rect.intersection(Rect2(Vector2.ZERO, img.get_size()))
	if rect.size.x < 20.0 or rect.size.y < 20.0:
		return
	_photo_texture = ImageTexture.create_from_image(img.get_region(Rect2i(rect)))
	var flash_layer: = CanvasLayer.new()
	flash_layer.layer = 80
	add_child(flash_layer)
	var flash: = ColorRect.new()
	flash.color = Color(1.0, 0.98, 0.92, 0.0)
	flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash_layer.add_child(flash)
	var tw: = create_tween()
	tw.tween_property(flash, "color:a", 0.55, 0.06)
	tw.tween_property(flash, "color:a", 0.0, 0.32)
	tw.tween_callback(flash_layer.queue_free)

func _start_finale() -> void :
	if _finale:
		return
	_finale = true
	player.dialogue_locked = true
	if _outfit_panel:
		_outfit_panel.visible = false
	if _intro_layer and is_instance_valid(_intro_layer):
		_intro_layer.visible = false
	_toast.visible = false
	_prompt_label.text = ""

	if _cake:
		player.global_position = _cake.global_position + Vector2(-300.0 * WORLD_SCALE, 0.0)
		_camera.global_position = player.global_position
	var ui_was_visible: = _ui.visible if _ui else false
	if _ui:
		_ui.visible = false
	await get_tree().process_frame
	await get_tree().process_frame
	_capture_player_photo()
	if _ui:
		_ui.visible = ui_was_visible
	_prompt_label.text = ""
	_toast.visible = false
	if _outfit_panel:
		_outfit_panel.visible = false
	_commit_checkin()
	var layer: = CanvasLayer.new()
	layer.layer = 35
	add_child(layer)
	var dim: = ColorRect.new()
	dim.color = Color(0.02, 0.01, 0.04, 0.0)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(dim)
	var tw: = create_tween()
	tw.tween_property(dim, "color:a", 0.82, 0.8)
	_fireworks_sequence()
	await get_tree().create_timer(1.3).timeout
	var letter: = _make_letter_panel(layer)
	letter.modulate.a = 0.0
	var tin: = create_tween()
	tin.tween_property(letter, "modulate:a", 1.0, 0.8)

func _make_letter_panel(layer: CanvasLayer) -> PanelContainer:
	var panel: = PanelContainer.new()
	panel.position = Vector2(270, 110)
	panel.custom_minimum_size = Vector2(612, 420)
	panel.add_theme_stylebox_override("panel", _style(Color(0.065, 0.035, 0.09, 0.97), Color(1.0, 0.66, 0.5, 0.8), 1, 5))
	layer.add_child(panel)
	var margin: = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 34)
	margin.add_theme_constant_override("margin_right", 34)
	margin.add_theme_constant_override("margin_top", 26)
	margin.add_theme_constant_override("margin_bottom", 22)
	panel.add_child(margin)
	var v: = VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	margin.add_child(v)
	var kicker: = Label.new()
	kicker.text = "BEFORE THE CANDLES GO OUT"
	kicker.add_theme_font_override("font", load(FONT_PATH))
	kicker.add_theme_font_size_override("font_size", 11)
	kicker.add_theme_color_override("font_color", Color(1.0, 0.6, 0.55, 0.75))
	v.add_child(kicker)
	var title: = Label.new()
	title.text = "给 %s" % _player_name
	title.add_theme_font_override("font", load(FONT_PATH))
	title.add_theme_font_size_override("font_size", 34)
	title.add_theme_color_override("font_color", Color(1.0, 0.88, 0.68))
	v.add_child(title)
	var body: = Label.new()
	body.text = "如果生日是一年一次的重启，\n愿你这次醒来，\n身边都是喜欢的人和事。\n\n那些没能说出口的愿望，\n就交给今晚的烛火吧。\n\n生日快乐。"
	body.add_theme_font_override("font", load(FONT_PATH))
	body.add_theme_font_size_override("font_size", 19)
	body.add_theme_color_override("font_color", Color(0.95, 0.88, 0.8))
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.custom_minimum_size = Vector2(540, 220)
	v.add_child(body)
	var spacer: = Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(spacer)
	var btn: = _make_button("收下这份祝福", Vector2.ZERO, Vector2(220, 44))
	btn.size_flags_horizontal = Control.SIZE_SHRINK_END
	btn.pressed.connect(_show_postcard)
	v.add_child(btn)
	return panel

func _fireworks_sequence() -> void :
	var colors: = [Color(1.0, 0.5, 0.62), Color(1.0, 0.78, 0.35), Color(0.55, 0.65, 1.0), Color(0.7, 0.5, 1.0)]
	for i in range(6):
		var delay: = 0.25 + i * 0.42
		get_tree().create_timer(delay).timeout.connect(_spawn_firework.bind(Vector2(220 + (i * 143) % 760, 150 + (i * 67) % 240), colors[i % colors.size()]))

func _spawn_firework(pos: Vector2, color: Color) -> void :
	if _fx_layer == null or not is_instance_valid(_fx_layer):
		return
	var p: = CPUParticles2D.new()
	p.amount = 38
	p.one_shot = true
	p.emitting = true
	p.lifetime = 1.3
	p.explosiveness = 1.0
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = 5.0
	p.direction = Vector2.UP
	p.spread = 180.0
	p.gravity = Vector2(0, 55)
	p.initial_velocity_min = 90.0
	p.initial_velocity_max = 270.0
	p.scale_amount_min = 0.04
	p.scale_amount_max = 0.13
	p.texture = _soft_tex
	var ramp: = Gradient.new()
	ramp.set_color(0, color)
	ramp.set_color(1, Color(color.r, color.g, color.b, 0.0))
	p.color_ramp = ramp
	p.position = pos
	p.z_index = 100
	_fx_layer.add_child(p)
	get_tree().create_timer(1.7).timeout.connect(p.queue_free)

func _show_postcard() -> void :
	if _card_open:
		return
	_card_open = true
	var layer: = CanvasLayer.new()
	layer.layer = 38
	add_child(layer)
	var dim: = ColorRect.new()
	dim.color = Color(0.02, 0.01, 0.035, 0.78)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(dim)
	var card: = PanelContainer.new()
	card.position = Vector2(214, 72)
	card.custom_minimum_size = Vector2(724, 514)
	card.rotation = -0.012
	var cs: = _style(Color(0.96, 0.9, 0.79, 0.98), Color(0.72, 0.46, 0.36, 0.7), 1, 3)
	cs.shadow_color = Color(0, 0, 0, 0.55)
	cs.shadow_size = 28
	cs.shadow_offset = Vector2(8, 14)
	card.add_theme_stylebox_override("panel", cs)
	layer.add_child(card)
	var margin: = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 32)
	margin.add_theme_constant_override("margin_right", 32)
	margin.add_theme_constant_override("margin_top", 22)
	margin.add_theme_constant_override("margin_bottom", 20)
	card.add_child(margin)
	var v: = VBoxContainer.new()
	v.add_theme_constant_override("separation", 5)
	margin.add_child(v)
	var head: = Label.new()
	head.text = "BIRTHDAY CHECK-IN  /  生日打卡"
	head.add_theme_font_override("font", load(FONT_PATH))
	head.add_theme_font_size_override("font_size", 13)
	head.add_theme_color_override("font_color", Color(0.6, 0.28, 0.27))
	v.add_child(head)
	var title: = Label.new()
	title.text = "给 %s" % _player_name
	title.add_theme_font_override("font", load(FONT_PATH))
	title.add_theme_font_size_override("font_size", 37)
	title.add_theme_color_override("font_color", Color(0.24, 0.12, 0.16))
	v.add_child(title)
	var date: = Label.new()
	date.text = "%s   ·   第 %d 次打卡   ·   5 / 5 段记忆" % [_last_checkin if not _last_checkin.is_empty() else _date_string(), _visits]
	date.add_theme_font_override("font", load(FONT_PATH))
	date.add_theme_font_size_override("font_size", 13)
	date.add_theme_color_override("font_color", Color(0.48, 0.33, 0.3))
	v.add_child(date)
	var line: = ColorRect.new()
	line.color = Color(0.68, 0.46, 0.4, 0.45)
	line.custom_minimum_size = Vector2(0, 1)
	v.add_child(line)
	var paragraph: = Label.new()
	paragraph.text = "谢谢你走到这里。\n今夜的五段记忆，已被这张卡片收好。\n下一次打开它的时候，希望你还是那个会为一点小事开心的人。\n\n如果今天还不是你的生日，就当它提前抵达。"
	paragraph.add_theme_font_override("font", load(FONT_PATH))
	paragraph.add_theme_font_size_override("font_size", 16)
	paragraph.add_theme_color_override("font_color", Color(0.28, 0.18, 0.19))
	paragraph.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	paragraph.custom_minimum_size = Vector2(650, 96)
	v.add_child(paragraph)
	var wish_head: = Label.new()
	wish_head.text = "今年，我想许愿——"
	wish_head.add_theme_font_override("font", load(FONT_PATH))
	wish_head.add_theme_font_size_override("font_size", 13)
	wish_head.add_theme_color_override("font_color", Color(0.55, 0.3, 0.28))
	v.add_child(wish_head)
	var wish_label: = Label.new()
	wish_label.text = _wish
	wish_label.add_theme_font_override("font", load(FONT_PATH))
	wish_label.add_theme_font_size_override("font_size", 20)
	wish_label.add_theme_color_override("font_color", _wish_color.darkened(0.35))
	v.add_child(wish_label)
	var wishes: = HBoxContainer.new()
	wishes.add_theme_constant_override("separation", 8)
	v.add_child(wishes)
	var options: = [["被爱", "愿被爱，也敢去爱。"], ["自由", "愿自由，去更远的地方。"], ["不再孤单", "愿不再孤单，被微光点亮。"], ["回响", "愿所愿，皆有回响。"]]
	for opt in options:
		var wb: = Button.new()
		wb.text = opt[0]
		wb.add_theme_font_override("font", load(FONT_PATH))
		wb.add_theme_font_size_override("font_size", 12)
		wb.add_theme_color_override("font_color", Color(0.35, 0.2, 0.19))
		wb.add_theme_stylebox_override("normal", _style(Color(0.9, 0.82, 0.7, 0.75), Color(0.65, 0.4, 0.33, 0.35), 1, 5))
		wb.add_theme_stylebox_override("hover", _style(Color(1.0, 0.9, 0.74, 1.0), Color(0.8, 0.45, 0.35, 0.7), 1, 5))
		wb.pressed.connect(_choose_wish.bind(opt[1], opt[0], wish_label))
		wishes.add_child(wb)
	var memory_row: = HBoxContainer.new()
	memory_row.add_theme_constant_override("separation", 7)
	var memory_tag: = Label.new()
	memory_tag.text = "五段记忆  "
	memory_tag.add_theme_font_override("font", load(FONT_PATH))
	memory_tag.add_theme_font_size_override("font_size", 12)
	memory_tag.add_theme_color_override("font_color", Color(0.55, 0.34, 0.3, 0.8))
	memory_row.add_child(memory_tag)
	for i in range(5):
		var star: = Label.new()
		star.text = "✦"
		star.add_theme_font_override("font", load(FONT_PATH))
		star.add_theme_font_size_override("font_size", 18)
		star.add_theme_color_override("font_color", [Color(1.0, 0.55, 0.62), Color(1.0, 0.78, 0.4), Color(0.6, 0.7, 1.0), Color(0.7, 0.55, 1.0), Color(0.55, 0.9, 0.8)][i])
		memory_row.add_child(star)
	v.add_child(memory_row)
	var stamp: = Label.new()
	stamp.text = "CHECKED IN\n%s" % _date_short()
	stamp.add_theme_font_override("font", load(FONT_PATH))
	stamp.add_theme_font_size_override("font_size", 12)
	stamp.add_theme_color_override("font_color", Color(0.65, 0.22, 0.24, 0.75))
	stamp.rotation = -0.14
	stamp.position = Vector2(586, 24)
	stamp.size = Vector2(120, 44)
	stamp.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var stamp_layer: = Control.new()
	stamp_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(stamp_layer)
	stamp_layer.add_child(stamp)
	var spacer: = Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(spacer)
	var actions: = HBoxContainer.new()
	actions.add_theme_constant_override("separation", 8)
	v.add_child(actions)
	var save: = _make_button("保存纪念卡", Vector2.ZERO, Vector2(160, 38))
	save.pressed.connect(_save_card)
	actions.add_child(save)
	var replay: = _make_button("再玩一次", Vector2.ZERO, Vector2(130, 38))
	replay.pressed.connect(_replay)
	actions.add_child(replay)
	var back: = _make_button("退出" if OS.has_feature("birthday_dlc") else "回到标题", Vector2.ZERO, Vector2(130, 38))
	back.pressed.connect(_go_title)
	actions.add_child(back)
	_saved_label = Label.new()
	_saved_label.text = ""
	_saved_label.add_theme_font_override("font", load(FONT_PATH))
	_saved_label.add_theme_font_size_override("font_size", 11)
	_saved_label.add_theme_color_override("font_color", Color(0.38, 0.25, 0.2, 0.8))
	_saved_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_saved_label.custom_minimum_size = Vector2(650, 22)
	v.add_child(_saved_label)

	if _photo_texture:
		var photo_layer: = Control.new()
		photo_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(photo_layer)
		var frame: = PanelContainer.new()
		frame.position = Vector2(500, 226)
		frame.custom_minimum_size = Vector2(176, 204)
		frame.rotation = -0.035
		var fs: = StyleBoxFlat.new()
		fs.bg_color = Color(1.0, 0.975, 0.91)
		fs.border_width_left = 1
		fs.border_width_top = 1
		fs.border_width_right = 1
		fs.border_width_bottom = 1
		fs.border_color = Color(0.62, 0.42, 0.35, 0.5)
		fs.set_corner_radius_all(2)
		fs.shadow_color = Color(0, 0, 0, 0.3)
		fs.shadow_size = 8
		fs.shadow_offset = Vector2(2, 5)
		frame.add_theme_stylebox_override("panel", fs)
		photo_layer.add_child(frame)
		var pm: = MarginContainer.new()
		pm.add_theme_constant_override("margin_left", 7)
		pm.add_theme_constant_override("margin_top", 7)
		pm.add_theme_constant_override("margin_right", 7)
		pm.add_theme_constant_override("margin_bottom", 5)
		frame.add_child(pm)
		var pv: = VBoxContainer.new()
		pv.add_theme_constant_override("separation", 3)
		pm.add_child(pv)
		var photo: = TextureRect.new()
		photo.texture = _photo_texture
		photo.custom_minimum_size = Vector2(160, 160)
		photo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		photo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		photo.clip_contents = true
		photo.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pv.add_child(photo)
		var caption: = Label.new()
		caption.text = "INSTANT PHOTO · %s" % _player_name
		caption.add_theme_font_override("font", load(FONT_PATH))
		caption.add_theme_font_size_override("font_size", 9)
		caption.add_theme_color_override("font_color", Color(0.42, 0.28, 0.24, 0.85))
		caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		pv.add_child(caption)

func _choose_wish(text: String, short: String, label: Label) -> void :
	_wish = text
	_wish_color = Color(1.0, 0.58, 0.62) if short == "被爱" else (Color(0.55, 0.7, 1.0) if short == "自由" else (Color(1.0, 0.82, 0.45) if short == "回响" else Color(0.72, 0.58, 1.0)))
	label.text = text
	label.add_theme_color_override("font_color", _wish_color.darkened(0.35))
	_spawn_firework(Vector2(400 + randf_range(0, 350), 160 + randf_range(-40, 80)), _wish_color)
	if _sfx:
		_sfx.play()

func _save_card() -> void :
	var img: = get_viewport().get_texture().get_image()
	var datetime: = Time.get_datetime_dict_from_system()
	var filename: = "birthday_card_%04d%02d%02d_%02d%02d%02d.png" % [
		datetime.year, datetime.month, datetime.day, datetime.hour, datetime.minute, datetime.second
	]
	var path: = "user://" + filename
	var err: = img.save_png(path)
	if _saved_label:
		if err == OK:
			_saved_label.text = "纪念卡已保存：%s" % ProjectSettings.globalize_path(path)
		else:
			_saved_label.text = "出了点小问题，保存失败..."

func _replay() -> void :
	get_tree().reload_current_scene()

func _go_title() -> void :
	if OS.has_feature("birthday_dlc"):
		get_tree().quit()
		return
	get_tree().change_scene_to_file(TITLE_SCENE)

func _date_string() -> String:
	var d: = Time.get_date_dict_from_system()
	return "%04d.%02d.%02d" % [d.year, d.month, d.day]

func _date_short() -> String:
	var d: = Time.get_date_dict_from_system()
	return "%02d.%02d" % [d.month, d.day]

func _unhandled_input(event: InputEvent) -> void :
	if event.is_action_pressed("ui_cancel"):
		if _outfit_panel and _outfit_panel.visible:
			_toggle_outfit()
			return
		_go_title()
		return

func _draw_legacy() -> void :

	for i in range(72):
		var t: = float(i) / 71.0
		var c: = Color(0.035, 0.035, 0.1).lerp(Color(0.2, 0.1, 0.23), t)
		draw_rect(Rect2(0, i * 9, VIEW.x, 10), c)

	for s in _stars:
		var a: float = s["a"] * (0.7 + 0.3 * sin(_time * 1.4 + s["p"].x))
		draw_circle(s["p"], s["r"], Color(1.0, 0.9, 0.75, a))

	draw_circle(Vector2(944, 112), 52.0, Color(1.0, 0.82, 0.56, 0.05))
	draw_circle(Vector2(944, 112), 34.0, Color(1.0, 0.9, 0.68, 0.2))
	draw_circle(Vector2(944, 112), 24.0, Color(1.0, 0.95, 0.78, 0.9))
	draw_circle(Vector2(954, 104), 5.0, Color(0.95, 0.85, 0.68, 0.5))
	draw_circle(Vector2(932, 120), 3.0, Color(0.95, 0.85, 0.68, 0.4))

	for k in range(3):
		var pts: = PackedVector2Array()
		for x in range(0, 1160, 18):
			var y: = 190.0 + k * 34.0 + sin(x * 0.008 + _time * 0.25 + k) * 22.0
			pts.append(Vector2(x, y))
		draw_polyline(pts, Color(0.35, 0.72, 0.75, 0.06 - k * 0.012), 18.0)

	for i in range(16):
		var bx: = i * 78.0 + 10.0
		var bh: = 40.0 + (i * 37 % 90)
		draw_rect(Rect2(bx, 560 - bh, 54, bh), Color(0.06, 0.05, 0.12, 0.6))
		for w in range(2):
			draw_rect(Rect2(bx + 11 + w * 20, 525 - bh, 4, 4), Color(1.0, 0.7, 0.4, 0.18))

	var bunting: = PackedVector2Array()
	for x in range(0, 1160, 32):
		bunting.append(Vector2(x, 46 + sin(x * 0.02) * 9))
	draw_polyline(bunting, Color(1.0, 0.72, 0.55, 0.35), 1.0)
	for i in range(0, 1160, 64):
		var y: = 46 + sin(i * 0.02) * 9
		draw_colored_polygon(PackedVector2Array([Vector2(i, y), Vector2(i + 18, y), Vector2(i + 9, y + 18)]), Color(1.0, 0.55, 0.55, 0.5) if i % 128 == 0 else Color(1.0, 0.78, 0.45, 0.45))

	for b in _balloons:
		var p: Vector2 = b["p"]
		var c: Color = b["c"]
		var sf: float = b["s"]
		draw_line(p + Vector2(0, 26 * sf), p + Vector2(sin(_time + p.x) * 8, 90), Color(0.85, 0.75, 0.7, 0.28), 1.0)
		draw_colored_polygon(_ellipse(p, Vector2(18, 23) * sf, 20), Color(c.r, c.g, c.b, 0.65))
		draw_colored_polygon(_ellipse(p + Vector2(-5, -6) * sf, Vector2(6, 8) * sf, 12), Color(1, 1, 1, 0.12))

	draw_rect(Rect2(0, 596, VIEW.x, 52), Color(0.12, 0.075, 0.13))
	draw_rect(Rect2(0, 596, VIEW.x, 4), Color(0.85, 0.55, 0.48, 0.35))
	_draw_ellipse(Vector2(560, 624), Vector2(440, 16), Color(0.3, 0.14, 0.22, 0.55))

	_draw_gift(Vector2(620, 596), Color(0.55, 0.35, 0.85), Color(1.0, 0.72, 0.5))
	_draw_gift(Vector2(950, 596), Color(0.85, 0.35, 0.45), Color(1.0, 0.85, 0.55))

	for i in range(1, _platforms.size()):
		var r: = _platforms[i]
		draw_rect(Rect2(r.position + Vector2(4, 7), r.size), Color(0, 0, 0, 0.25))
		draw_rect(r, Color(0.28, 0.18, 0.38))
		draw_rect(Rect2(r.position, Vector2(r.size.x, 5)), Color(0.58, 0.42, 0.72))
		draw_line(Vector2(r.position.x + r.size.x * 0.5, r.position.y), Vector2(r.position.x + r.size.x * 0.5, r.position.y + r.size.y), Color(1.0, 0.72, 0.55, 0.42), 2.0)
		draw_line(Vector2(r.position.x + 4, r.position.y + r.size.y * 0.5), Vector2(r.position.x + r.size.x - 4, r.position.y + r.size.y * 0.5), Color(1.0, 0.8, 0.6, 0.28), 1.0)

	draw_circle(Vector2(560, 80), 3.0, Color(1, 0.9, 0.7, 0.6))

func _draw_gift(p: Vector2, body: Color, ribbon: Color) -> void :
	draw_rect(Rect2(p.x - 30, p.y - 46, 60, 46), Color(0, 0, 0, 0.25))
	draw_rect(Rect2(p.x - 26, p.y - 44, 52, 44), body)
	draw_rect(Rect2(p.x - 4, p.y - 44, 8, 44), ribbon)
	draw_rect(Rect2(p.x - 26, p.y - 30, 52, 6), ribbon)
	draw_colored_polygon(PackedVector2Array([Vector2(p.x, p.y - 44), Vector2(p.x - 15, p.y - 56), Vector2(p.x - 2, p.y - 52)]), ribbon)
	draw_colored_polygon(PackedVector2Array([Vector2(p.x, p.y - 44), Vector2(p.x + 15, p.y - 56), Vector2(p.x + 2, p.y - 52)]), ribbon)

func _ellipse(c: Vector2, r: Vector2, steps: int) -> PackedVector2Array:
	var pts: = PackedVector2Array()
	for i in range(steps):
		var a: = TAU * float(i) / float(steps)
		pts.append(c + Vector2(cos(a) * r.x, sin(a) * r.y))
	return pts

func _draw_ellipse(c: Vector2, r: Vector2, color: Color) -> void :
	draw_colored_polygon(_ellipse(c, r, 28), color)

func _make_soft_texture() -> Texture2D:
	var size: = 64
	var img: = Image.create(size, size, false, Image.FORMAT_RGBA8)
	var c: = size * 0.5
	for y in range(size):
		for x in range(size):
			var d: = Vector2(x + 0.5 - c, y + 0.5 - c).length() / c
			var a: = pow(maxf(0.0, 1.0 - d), 2.4)
			img.set_pixel(x, y, Color(1, 1, 1, a))
	return ImageTexture.create_from_image(img)
