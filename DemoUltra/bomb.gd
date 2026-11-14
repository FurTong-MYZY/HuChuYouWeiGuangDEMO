extends Area2D
class_name Bomb




static var _body_cache: Dictionary = {}
static var _tex_lamp: Texture2D = null
static var _tex_soft: Texture2D = null

@export var fall_gravity: float = 11200.0
@export var max_fall: float = 9600.0
@export var core_radius: float = 384.0
@export var outer_radius: float = 736.0
@export var explosion_damage: float = 50.0

var _velocity: Vector2 = Vector2.ZERO
var _ray: RayCast2D
var _rot: float = 0.0
var _pulse: float = 0.0
var _sprite: Sprite2D
var _lamp: Sprite2D
var _glow: Sprite2D
var _trail: CPUParticles2D
var _tex_body: Texture2D

func _ready() -> void :
	collision_layer = 0
	collision_mask = 3
	z_index = 8

	var cs: = CollisionShape2D.new()
	var c: = CircleShape2D.new()
	c.radius = 10.0 * PixelArt.SCALE
	cs.shape = c
	add_child(cs)

	_ray = RayCast2D.new()
	_ray.target_position = Vector2(0, 12.0 * PixelArt.SCALE)
	_ray.collision_mask = 1
	add_child(_ray)

	_tex_soft = _get_soft_texture()

	_glow = Sprite2D.new()
	_glow.centered = true
	_glow.texture = _tex_soft
	_glow.material = _additive_material()
	_glow.modulate = Color(1.0, 0.25, 0.08, 0.35)
	_glow.scale = Vector2(2.2, 2.8)
	_glow.z_index = -1
	add_child(_glow)

	_sprite = Sprite2D.new()
	_sprite.centered = true
	add_child(_sprite)

	_lamp = Sprite2D.new()
	_lamp.centered = true
	_lamp.position = Vector2(0, -7 * PixelArt.SCALE)
	add_child(_lamp)

	_trail = CPUParticles2D.new()
	_trail.amount = 10
	_trail.lifetime = 0.38
	_trail.one_shot = false
	_trail.local_coords = false
	_trail.direction = Vector2.UP
	_trail.spread = 26.0
	_trail.initial_velocity_min = 25.0
	_trail.initial_velocity_max = 70.0
	_trail.gravity = Vector2(0, -18)
	_trail.scale_amount_min = 0.22
	_trail.scale_amount_max = 0.55
	_trail.texture = _tex_soft
	var ramp: = Gradient.new()
	ramp.set_color(0, Color(1.0, 0.6, 0.18, 0.55))
	ramp.set_color(1, Color(0.35, 0.08, 0.02, 0.0))
	_trail.color_ramp = ramp
	_trail.z_index = -2
	add_child(_trail)
	_trail.emitting = true

	var key: = Vector2i(int(core_radius), int(outer_radius))
	if not _body_cache.has(key):
		_body_cache[key] = await PixelArt.bake_texture(_bake_body, Vector2i(32 * PixelArt.SCALE, 40 * PixelArt.SCALE), self)
	_tex_body = _body_cache[key]
	if _tex_body == null:
		_body_cache.erase(key)
		queue_redraw()
	if _tex_lamp == null:
		_tex_lamp = await PixelArt.bake_texture(_bake_lamp, Vector2i(10 * PixelArt.SCALE, 10 * PixelArt.SCALE), self)
	if _tex_body:
		_sprite.texture = _tex_body
	if _tex_lamp:
		_lamp.texture = _tex_lamp

func _bake_body(ci: CanvasItem) -> void :
	var s: = PixelArt.SCALE
	ci.draw_set_transform(Vector2(16 * s, 20 * s), 0.0, Vector2(s, s))


	ci.draw_rect(Rect2(-9, -16, 4, 9), Color(0.1, 0.12, 0.18))
	ci.draw_rect(Rect2(5, -16, 4, 9), Color(0.1, 0.12, 0.18))
	ci.draw_rect(Rect2(-12, -14, 5, 3), Color(0.2, 0.23, 0.34))
	ci.draw_rect(Rect2(7, -14, 5, 3), Color(0.2, 0.23, 0.34))
	ci.draw_rect(Rect2(-2, -18, 4, 5), Color(0.18, 0.2, 0.3))


	ci.draw_circle(Vector2(0, 0), 12.0, Color(0.08, 0.09, 0.15))
	ci.draw_circle(Vector2(0, 0), 10.5, Color(0.17, 0.19, 0.28))
	ci.draw_circle(Vector2(-3.5, -3.5), 6.0, Color(0.3, 0.33, 0.46))
	ci.draw_circle(Vector2(-4.5, -4.5), 2.8, Color(0.62, 0.68, 0.84, 0.6))
	ci.draw_rect(Rect2(-10, 7, 20, 4), Color(0.06, 0.06, 0.1))
	ci.draw_rect(Rect2(-9, 8, 18, 1), Color(0.55, 0.58, 0.72, 0.5))


	ci.draw_rect(Rect2(-10, -1, 20, 3), Color(1.0, 0.48, 0.08, 0.85))
	ci.draw_rect(Rect2(-10, 1, 20, 1), Color(0.05, 0.05, 0.08, 0.7))
	for i in range(5):
		ci.draw_circle(Vector2(-8 + i * 4, -8), 0.8, Color(0.65, 0.7, 0.82, 0.6))
	ci.draw_rect(Rect2(-1.5, 11, 3, 3), Color(0.15, 0.15, 0.22))
	ci.draw_circle(Vector2(0, 13), 2.0, Color(1.0, 0.35, 0.08, 0.7))


	ci.draw_line(Vector2(-8, 4), Vector2(-5, 8), Color(0.5, 0.55, 0.7, 0.35), 1.0)
	ci.draw_circle(Vector2(-4.5, -4.5), 1.2, Color(1, 1, 1, 0.7))

func _bake_lamp(ci: CanvasItem) -> void :
	var s: = PixelArt.SCALE
	ci.draw_set_transform(Vector2(5 * s, 5 * s), 0.0, Vector2(s, s))
	ci.draw_circle(Vector2.ZERO, 3.4, Color(0.25, 0.02, 0.02))
	ci.draw_circle(Vector2.ZERO, 2.4, Color(1.0, 0.2, 0.16, 0.95))
	ci.draw_circle(Vector2.ZERO, 1.1, Color(1.0, 0.9, 0.7, 1.0))

func _physics_process(delta: float) -> void :
	_pulse += delta
	_velocity.y = min(_velocity.y + fall_gravity * delta, max_fall)
	position += _velocity * delta
	_rot += delta * 6.0
	_sprite.rotation = _rot
	if _tex_lamp:
		var blink: = int(_rot * 1.5) % 2 == 0
		_lamp.modulate = Color(1, 1, 1, 1.0) if blink else Color(0.5, 0.15, 0.15, 1.0)
	if _glow:
		_glow.modulate.a = 0.28 + 0.12 * sin(_pulse * 9.0)

	if _ray.is_colliding():
		_explode()
		return
	for b in get_overlapping_bodies():
		if b.is_in_group("player"):
			_explode()
			return

	if global_position.y > 8000:
		queue_free()
	if _tex_body == null:
		queue_redraw()

func _explode() -> void :
	var e: = Explosion.new()
	e.core_radius = core_radius
	e.outer_radius = outer_radius
	e.core_damage = explosion_damage
	e.outer_damage = explosion_damage
	get_tree().current_scene.add_child(e)
	e.global_position = global_position
	queue_free()

func _get_soft_texture() -> Texture2D:
	if _tex_soft:
		return _tex_soft
	var size: = 32
	var img: = Image.create(size, size, false, Image.FORMAT_RGBA8)
	var c: = size * 0.5
	for y in range(size):
		for x in range(size):
			var d: = Vector2(x + 0.5 - c, y + 0.5 - c).length() / c
			var a: = pow(maxf(0.0, 1.0 - d), 2.2)
			img.set_pixel(x, y, Color(1, 1, 1, a))
	_tex_soft = ImageTexture.create_from_image(img)
	return _tex_soft

static func _additive_material() -> CanvasItemMaterial:
	var m: = CanvasItemMaterial.new()
	m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	return m

func _draw() -> void :
	if _tex_body:
		return
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(PixelArt.SCALE, PixelArt.SCALE))
	draw_circle(Vector2.ZERO, 11.0, Color(0.12, 0.13, 0.2))
	draw_circle(Vector2(-3, -3), 6.0, Color(0.28, 0.3, 0.42))
	draw_rect(Rect2(-1.5, -15, 3, 5), Color(0.2, 0.2, 0.28))
	var blink: = int(_rot * 1.5) % 2
	var lamp: = Color(1.0, 0.2, 0.2, 1.0) if blink == 0 else Color(0.5, 0.1, 0.1, 1.0)
	draw_circle(Vector2(0, -6), 2.5, lamp)
