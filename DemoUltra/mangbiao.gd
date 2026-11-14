extends Area2D



var activated: bool = false
var _t: float = 0.0
var _soft_tex: Texture2D
var _sfx: AudioStreamPlayer
var _float: Node2D
var _beam: Polygon2D
var _glow: Sprite2D
var _ground: Line2D
var _ring1: Line2D
var _ring2: Line2D
var _diamond: Polygon2D
var _inner: Polygon2D
var _motes: Array[Sprite2D] = []
var _icon_layer: CanvasLayer
var _icon: TextureRect

func _ready() -> void :
	collision_layer = 0
	collision_mask = 3
	monitoring = true
	z_index = 100
	_soft_tex = _make_soft_texture()
	body_entered.connect(_on_body_entered)
	_build_visual()
	_build_screen_icon()
	_sfx = AudioStreamPlayer.new()
	_sfx.stream = load("res://sound/collect_light.wav")
	_sfx.volume_db = -6.0
	add_child(_sfx)

func _build_visual() -> void :
	var shadow: = Polygon2D.new()
	shadow.polygon = PackedVector2Array([
		Vector2(-48, 0), Vector2(-30, 10), Vector2(30, 10), Vector2(48, 0), 
		Vector2(32, -8), Vector2(-32, -8)
	])
	shadow.color = Color(0, 0, 0, 0.28)
	shadow.z_index = 900
	add_child(shadow)

	_beam = Polygon2D.new()
	_beam.polygon = PackedVector2Array([
		Vector2(-18, -2), Vector2(-8, -150), Vector2(8, -150), Vector2(18, -2)
	])
	_beam.z_index = 900
	add_child(_beam)

	_ground = _make_ring(36.0, 2.4)
	_ground.position = Vector2(0, -2)
	_ground.z_index = 920
	add_child(_ground)

	_float = Node2D.new()
	_float.position = Vector2(0, -170)
	_float.z_index = 1000
	add_child(_float)

	_glow = Sprite2D.new()
	_glow.texture = _soft_tex
	_glow.centered = true
	_glow.scale = Vector2(1.7, 1.7)
	var mat: = CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_glow.material = mat
	_glow.z_index = -1
	_float.add_child(_glow)

	_ring1 = _make_ring(31.0, 1.8)
	_float.add_child(_ring1)
	_ring2 = _make_ring(44.0, 1.2)
	_float.add_child(_ring2)

	_diamond = Polygon2D.new()
	_diamond.polygon = PackedVector2Array([
		Vector2(0, -25), Vector2(18, 0), Vector2(0, 25), Vector2(-18, 0)
	])
	_diamond.z_index = 2
	_float.add_child(_diamond)
	_inner = Polygon2D.new()
	_inner.polygon = PackedVector2Array([
		Vector2(0, -13), Vector2(9, 0), Vector2(0, 13), Vector2(-9, 0)
	])
	_inner.z_index = 3
	_float.add_child(_inner)
	for i in range(5):
		var mote: = Sprite2D.new()
		mote.texture = _soft_tex
		mote.centered = true
		mote.scale = Vector2(0.1, 0.1)
		mote.z_index = 1
		_float.add_child(mote)
		_motes.append(mote)
	_apply_color()

func _process(delta: float) -> void :
	_t += delta
	if _float:
		_float.position.y = -170.0 + sin(_t * 2.0) * 5.0
		_ring1.rotation += delta * 0.5
		_ring2.rotation -= delta * 0.3
		for i in range(_motes.size()):
			var a: = _t * 0.7 + TAU * float(i) / float(_motes.size())
			_motes[i].position = Vector2(cos(a) * 54.0, sin(a) * 54.0)
			_motes[i].modulate.a = 0.3 + 0.4 * (0.5 + 0.5 * sin(_t * 2.2 + i))
	if _icon:
		var xf: = get_viewport().get_canvas_transform()
		var screen: = xf * global_position
		_icon.position = screen + Vector2(-80, -158 + sin(_t * 1.8) * 3.0)
		_icon.modulate = Color(1.0, 1.0, 1.0, 0.98) if not activated else Color(0.72, 0.94, 1.0, 1.0)

func _build_screen_icon() -> void :

	_icon_layer = CanvasLayer.new()
	_icon_layer.layer = 65
	add_child(_icon_layer)
	_icon = TextureRect.new()
	_icon.texture = load("res://spr/场景/主题/mangbiao.png")
	_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_icon.size = Vector2(160, 163)
	_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_icon_layer.add_child(_icon)

func _apply_color() -> void :
	var main: = Color(1.0, 0.8, 0.4) if not activated else Color(0.55, 0.9, 1.0)
	if _beam:
		_beam.color = Color(main.r, main.g, main.b, 0.055)
	if _ground:
		_ground.default_color = Color(main.r, main.g, main.b, 0.9)
	if _ring1:
		_ring1.default_color = Color(main.r, main.g, main.b, 0.8)
	if _ring2:
		_ring2.default_color = Color(0.55, 0.85, 1.0, 0.45)
	if _glow:
		_glow.modulate = Color(main.r, main.g, main.b, 0.3)
	if _diamond:
		_diamond.color = Color(main.r, main.g, main.b, 0.95)
	if _inner:
		_inner.color = Color(1.0, 0.98, 0.86, 0.95)

func _make_ring(radius: float, width: float) -> Line2D:
	var ring: = Line2D.new()
	ring.width = width
	var pts: = PackedVector2Array()
	for i in range(65):
		var a: = TAU * float(i) / 64.0
		pts.append(Vector2(cos(a), sin(a)) * radius)
	ring.points = pts
	ring.antialiased = true
	return ring

func _on_body_entered(body: Node) -> void :
	if activated:
		return
	if not body.is_in_group("player"):
		return
	if not body.has_method("heal_full_from_mangbiao"):
		return
	activated = true
	body.heal_full_from_mangbiao()
	body.set_scene_checkpoint(global_position, self)
	_apply_color()
	_burst(Color(1.0, 0.84, 0.4), 30)
	if _sfx:
		_sfx.play()
	_show_toast()

func play_respawn_effect() -> void :
	_burst(Color(0.55, 0.9, 1.0), 36)
	_apply_color()
	var layer: = CanvasLayer.new()
	layer.layer = 70
	add_child(layer)
	var flash: = ColorRect.new()
	flash.color = Color(0.55, 0.85, 1.0, 0.0)
	flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(flash)
	var tw: = create_tween()
	tw.tween_property(flash, "color:a", 0.2, 0.08)
	tw.tween_property(flash, "color:a", 0.0, 0.45)
	tw.tween_callback(layer.queue_free)

func _burst(color: Color, amount: int) -> void :
	var p: = CPUParticles2D.new()
	p.amount = amount
	p.one_shot = true
	p.emitting = true
	p.lifetime = 1.1
	p.explosiveness = 1.0
	p.direction = Vector2.UP
	p.spread = 180.0
	p.gravity = Vector2(0, 120)
	p.initial_velocity_min = 60.0
	p.initial_velocity_max = 220.0
	p.scale_amount_min = 0.04
	p.scale_amount_max = 0.14
	p.texture = _soft_tex
	var ramp: = Gradient.new()
	ramp.set_color(0, color)
	ramp.set_color(1, Color(color.r, color.g, color.b, 0.0))
	p.color_ramp = ramp
	p.position = Vector2(0, -100)
	p.z_index = 1100
	add_child(p)
	get_tree().create_timer(1.5).timeout.connect(p.queue_free)

func _show_toast() -> void :
	var layer: = CanvasLayer.new()
	layer.layer = 65
	add_child(layer)
	var panel: = PanelContainer.new()
	panel.position = Vector2(0, 46)
	panel.custom_minimum_size = Vector2(get_viewport().get_visible_rect().size.x, 0)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style: = StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.03, 0.07, 0.0)
	style.border_width_top = 0
	style.border_width_bottom = 0
	style.border_color = Color(1.0, 0.75, 0.38, 0.0)
	panel.add_theme_stylebox_override("panel", style)
	layer.add_child(panel)
	var label: = Label.new()
	label.text = "检查点已点亮    ·    生命已回满    ·    下一次倒下会在这里醒来"
	label.add_theme_font_override("font", load("res://fonts/TitleFont.ttf"))
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.68))
	label.add_theme_color_override("font_shadow_color", Color(0.12, 0.04, 0.02, 0.95))
	label.add_theme_constant_override("shadow_outline_size", 5)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.custom_minimum_size = Vector2(get_viewport().get_visible_rect().size.x, 30)
	panel.add_child(label)
	panel.modulate.a = 0.0
	var tw: = create_tween()
	tw.tween_property(panel, "modulate:a", 1.0, 0.22)
	tw.tween_interval(2.4)
	tw.tween_property(panel, "modulate:a", 0.0, 0.45)
	tw.tween_callback(layer.queue_free)

func _make_soft_texture() -> Texture2D:
	var size: = 64
	var img: = Image.create(size, size, false, Image.FORMAT_RGBA8)
	var c: = size * 0.5
	for y in range(size):
		for x in range(size):
			var d: = Vector2(x + 0.5 - c, y + 0.5 - c).length() / c
			var a: = pow(maxf(0.0, 1.0 - d), 2.0)
			img.set_pixel(x, y, Color(1, 1, 1, a))
	return ImageTexture.create_from_image(img)
