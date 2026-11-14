extends CharacterBody2D

@onready var head: Sprite2D = $Head
@onready var body: Sprite2D = $Body

@export var body_float_amplitude: float = 4.0
@export var body_float_speed: float = 2.0
@export var head_float_amplitude: float = 2.0
@export var head_float_speed: float = 3.0
@export var head_sway_angle: float = 2.0
@export var head_sway_speed: float = 1.5

var body_start_pos: Vector2
var head_start_pos: Vector2
var head_start_rotation: float

var _eye_angle: = 0.0
var _eye_tex: Texture2D
var _soft_tex: Texture2D
var _eyes: Array[Sprite2D] = []
var _eye_glows: Array[Sprite2D] = []

func _ready() -> void :
	body_start_pos = body.position
	head_start_pos = head.position
	head_start_rotation = head.rotation
	_build_enchant_eyes()

func _build_enchant_eyes() -> void :
	_eye_tex = _make_eye_texture()
	_soft_tex = _make_soft_texture()
	for i in range(3):
		var glow: = Sprite2D.new()
		glow.texture = _soft_tex
		glow.centered = true
		glow.z_index = 4
		glow.modulate = Color(0.45, 0.3, 1.0, 0.25)
		var mat: = CanvasItemMaterial.new()
		mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		glow.material = mat
		glow.scale = Vector2(0.75, 0.75)
		add_child(glow)
		_eye_glows.append(glow)

		var eye: = Sprite2D.new()
		eye.texture = _eye_tex
		eye.centered = true
		eye.z_index = 5
		eye.scale = Vector2(1.55, 1.55)
		add_child(eye)
		_eyes.append(eye)

func _process(delta: float) -> void :

	var time = Time.get_ticks_msec() / 1000.0


	var body_offset_y = sin(time * body_float_speed) * body_float_amplitude



	var head_offset_y = sin(time * head_float_speed) * head_float_amplitude
	head.position.y = head_start_pos.y + body_offset_y * 0.8 + head_offset_y


	head.rotation = head_start_rotation + deg_to_rad(sin(time * head_sway_speed) * head_sway_angle)


	body.scale.y = 1.0 + sin(time * body_float_speed) * 0.01


	_eye_angle += delta * 1.25
	var center: = Vector2(0, -120)
	for i in range(_eyes.size()):
		var ang: = _eye_angle + TAU * float(i) / float(_eyes.size())
		var pos: = center + Vector2(cos(ang) * 112.0, sin(ang) * 44.0)
		_eyes[i].position = pos
		_eyes[i].rotation = ang + PI
		_eyes[i].modulate = Color(0.7, 0.52, 1.0, 0.95)
		_eye_glows[i].position = pos
		_eye_glows[i].modulate = Color(0.42, 0.3, 1.0, 0.18 + 0.06 * sin(time * 3.0 + i))

func _make_eye_texture() -> Texture2D:
	var size: = 64
	var img: = Image.create(size, size, false, Image.FORMAT_RGBA8)
	var c: = size * 0.5
	for y in range(size):
		for x in range(size):
			var dx: float = x + 0.5 - c
			var dy: float = y + 0.5 - c
			var sclera: = (dx * dx) / (23.0 * 23.0) + (dy * dy) / (13.0 * 13.0)
			var color: = Color(0, 0, 0, 0)
			if sclera < 1.0:
				color = Color(0.78, 0.68, 1.0, 0.95)
			var iris: = Vector2(dx, dy).length()
			if iris < 11.0:
				color = Color(0.42, 0.22, 1.0, 1.0)
			if iris < 8.0:
				color = Color(0.55, 0.38, 1.0, 1.0)
			if absf(dx) < 2.4 and absf(dy) < 9.0:
				color = Color(0.04, 0.015, 0.12, 1.0)
			if dx < -4.0 and dx > -8.0 and dy < -3.0 and dy > -7.0:
				color = Color(1, 1, 1, 0.9)
			if color.a > 0.0:
				img.set_pixel(x, y, color)
	return ImageTexture.create_from_image(img)

func _make_soft_texture() -> Texture2D:
	var size: = 64
	var img: = Image.create(size, size, false, Image.FORMAT_RGBA8)
	var c: = size * 0.5
	for y in range(size):
		for x in range(size):
			var d: = Vector2(x + 0.5 - c, y + 0.5 - c).length() / c
			var a: = pow(maxf(0.0, 1.0 - d), 2.2)
			img.set_pixel(x, y, Color(1, 1, 1, a))
	return ImageTexture.create_from_image(img)
