extends Node2D


var _color: Color = Color(1.0, 0.84, 0.32, 1.0)
var _ring: Sprite2D
var _diamond: Sprite2D
var _t: float = 0.0

static var _ring_tex: Texture2D = null
static var _diamond_tex: Texture2D = null
static var _soft_tex: Texture2D = null

func setup(world_pos: Vector2, color: Color) -> void :
	global_position = world_pos
	_color = color
	_build()

func _build() -> void :
	z_index = 3
	_ring = Sprite2D.new()
	_ring.texture = _get_ring_texture()
	_ring.centered = true
	_ring.modulate = Color(_color.r, _color.g, _color.b, 0.32)
	_ring.scale = Vector2(2.2, 2.2)
	var ring_mat: = CanvasItemMaterial.new()
	ring_mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_ring.material = ring_mat
	add_child(_ring)

	_diamond = Sprite2D.new()
	_diamond.texture = _get_diamond_texture()
	_diamond.centered = true
	_diamond.position = Vector2(0, -58)
	_diamond.modulate = Color(_color.r, _color.g, _color.b, 0.9)
	_diamond.scale = Vector2(0.75, 0.75)
	var diamond_mat: = CanvasItemMaterial.new()
	diamond_mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_diamond.material = diamond_mat
	add_child(_diamond)

	var motes: = CPUParticles2D.new()
	motes.amount = 9
	motes.lifetime = 1.8
	motes.preprocess = 1.8
	motes.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	motes.emission_sphere_radius = 38.0
	motes.direction = Vector2.UP
	motes.spread = 28.0
	motes.gravity = Vector2(0, -24)
	motes.initial_velocity_min = 10.0
	motes.initial_velocity_max = 35.0
	motes.scale_amount_min = 0.12
	motes.scale_amount_max = 0.28
	motes.texture = _get_soft_texture()
	var ramp: = Gradient.new()
	ramp.set_color(0, Color(_color.r, _color.g, _color.b, 0.0))
	ramp.set_color(0.3, Color(_color.r, _color.g, _color.b, 0.7))
	ramp.set_color(1, Color(_color.r, _color.g, _color.b, 0.0))
	motes.color_ramp = ramp
	motes.z_index = 2
	add_child(motes)
	motes.emitting = true

func _process(delta: float) -> void :
	_t += delta
	if _ring:
		_ring.rotation += delta * 0.28
		_ring.scale = Vector2(2.2 + sin(_t * 1.8) * 0.08, 2.2 + sin(_t * 1.8) * 0.08)
		_ring.modulate.a = 0.24 + 0.1 * (0.5 + 0.5 * sin(_t * 2.1))
	if _diamond:
		_diamond.position.y = -58.0 + sin(_t * 2.2) * 5.0
		_diamond.rotation = sin(_t * 1.4) * 0.12
		_diamond.modulate.a = 0.72 + 0.18 * (0.5 + 0.5 * sin(_t * 2.8))

func _get_ring_texture() -> Texture2D:
	if _ring_tex:
		return _ring_tex
	var size: = 128
	var img: = Image.create(size, size, false, Image.FORMAT_RGBA8)
	var c: = size * 0.5
	for y in range(size):
		for x in range(size):
			var d: = Vector2(x + 0.5 - c, y + 0.5 - c).length() / c
			var a: = smoothstep(0.6, 0.7, d) * (1.0 - smoothstep(0.84, 0.96, d))
			img.set_pixel(x, y, Color(1, 1, 1, a))
	_ring_tex = ImageTexture.create_from_image(img)
	return _ring_tex

func _get_diamond_texture() -> Texture2D:
	if _diamond_tex:
		return _diamond_tex
	var size: = 64
	var img: = Image.create(size, size, false, Image.FORMAT_RGBA8)
	var c: = size * 0.5
	for y in range(size):
		for x in range(size):
			var p: = Vector2(x + 0.5 - c, y + 0.5 - c)
			var a: = maxf(0.0, 1.0 - (absf(p.x) + absf(p.y)) / (c * 0.72))
			a = pow(a, 0.7)
			img.set_pixel(x, y, Color(1, 1, 1, a))
	_diamond_tex = ImageTexture.create_from_image(img)
	return _diamond_tex

func _get_soft_texture() -> Texture2D:
	if _soft_tex:
		return _soft_tex
	var size: = 32
	var img: = Image.create(size, size, false, Image.FORMAT_RGBA8)
	var c: = size * 0.5
	for y in range(size):
		for x in range(size):
			var d: = Vector2(x + 0.5 - c, y + 0.5 - c).length() / c
			img.set_pixel(x, y, Color(1, 1, 1, pow(maxf(0.0, 1.0 - d), 2.0)))
	_soft_tex = ImageTexture.create_from_image(img)
	return _soft_tex
