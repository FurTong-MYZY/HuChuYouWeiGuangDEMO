extends Area2D
class_name DroneExplosion



@export var radius: float = 340.0
@export var damage: float = 20.0
@export var life: float = 0.7
@export var visual_scale: float = 1.0

static var _fire_cache: Texture2D = null
static var _core_cache: Texture2D = null
static var _shock_cache: Texture2D = null
static var _soft_cache: Dictionary = {}
static var _debris_cache: Texture2D = null

var _age: float = 0.0
var _hit_player: bool = false

var _fire_a: Sprite2D
var _fire_b: Sprite2D
var _core: Sprite2D
var _flash: Sprite2D
var _ring_a: Sprite2D
var _ring_b: Sprite2D
var _smoke: CPUParticles2D
var _debris: CPUParticles2D

var _tex_fire: Texture2D
var _tex_core: Texture2D

func _ready() -> void :
	collision_layer = 0
	collision_mask = 3
	z_index = 10

	var cs: = CollisionShape2D.new()
	var circle: = CircleShape2D.new()
	circle.radius = radius
	cs.shape = circle
	add_child(cs)

	_build_visuals()

	if _fire_cache == null:
		_fire_cache = await PixelArt.bake_texture(_bake_fire, Vector2i(512, 512), self)
	if _core_cache == null:
		_core_cache = await PixelArt.bake_texture(_bake_core, Vector2i(256, 256), self)
	_tex_fire = _fire_cache
	_tex_core = _core_cache
	if _tex_fire:
		_fire_a.texture = _tex_fire
		_fire_b.texture = _tex_fire
	if _tex_core:
		_core.texture = _tex_core
	else:
		queue_redraw()

	_animate()
	_screen_flash()
	_shake_camera()

func _build_visuals() -> void :
	_fire_a = Sprite2D.new()
	_fire_a.centered = true
	_fire_a.modulate = Color(1.0, 0.65, 0.2, 0.9)
	_fire_a.z_index = 1
	add_child(_fire_a)

	_fire_b = Sprite2D.new()
	_fire_b.centered = true
	_fire_b.modulate = Color(1.0, 0.35, 0.05, 0.85)
	_fire_b.rotation = 0.35
	_fire_b.scale = Vector2(0.7, 0.7)
	_fire_b.z_index = 2
	add_child(_fire_b)

	_core = Sprite2D.new()
	_core.centered = true
	_core.material = _additive_material()
	_core.z_index = 3
	add_child(_core)

	_flash = Sprite2D.new()
	_flash.centered = true
	_flash.texture = _make_soft_texture(64)
	_flash.material = _additive_material()
	_flash.modulate = Color(1.0, 0.9, 0.55, 0.95)
	_flash.scale = Vector2(1.5, 1.5)
	_flash.z_index = 4
	add_child(_flash)

	var shock: = _make_shock_texture()
	_ring_a = Sprite2D.new()
	_ring_a.centered = true
	_ring_a.texture = shock
	_ring_a.material = _additive_material()
	_ring_a.modulate = Color(1.0, 0.45, 0.12, 0.85)
	_ring_a.scale = Vector2(0.4, 0.4)
	_ring_a.z_index = 5
	add_child(_ring_a)

	_ring_b = Sprite2D.new()
	_ring_b.centered = true
	_ring_b.texture = shock
	_ring_b.material = _additive_material()
	_ring_b.modulate = Color(1.0, 0.9, 0.5, 0.55)
	_ring_b.scale = Vector2(0.25, 0.25)
	_ring_b.z_index = 5
	add_child(_ring_b)

	_smoke = CPUParticles2D.new()
	_smoke.amount = 26
	_smoke.one_shot = true
	_smoke.explosiveness = 1.0
	_smoke.lifetime = 1.2
	_smoke.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	_smoke.emission_sphere_radius = 42.0
	_smoke.direction = Vector2.UP
	_smoke.spread = 80.0
	_smoke.initial_velocity_min = 40.0
	_smoke.initial_velocity_max = 150.0
	_smoke.gravity = Vector2(0, -25)
	_smoke.scale_amount_min = 0.7
	_smoke.scale_amount_max = 1.8
	_smoke.texture = _make_soft_texture(32)
	var smoke_ramp: = Gradient.new()
	smoke_ramp.set_color(0, Color(0.2, 0.17, 0.16, 0.55))
	smoke_ramp.set_color(1, Color(0.04, 0.04, 0.05, 0.0))
	_smoke.color_ramp = smoke_ramp
	_smoke.z_index = 2
	add_child(_smoke)
	_smoke.emitting = true

	_debris = CPUParticles2D.new()
	_debris.amount = 42
	_debris.one_shot = true
	_debris.explosiveness = 1.0
	_debris.lifetime = 0.85
	_debris.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	_debris.emission_sphere_radius = 24.0
	_debris.direction = Vector2.RIGHT
	_debris.spread = 180.0
	_debris.initial_velocity_min = 380.0
	_debris.initial_velocity_max = 980.0
	_debris.gravity = Vector2(0, 620)
	_debris.scale_amount_min = 0.25
	_debris.scale_amount_max = 0.9
	var debris_tex: = _make_debris_texture()
	_debris.texture = debris_tex
	var debris_ramp: = Gradient.new()
	debris_ramp.set_color(0, Color(1.0, 0.9, 0.55, 1.0))
	debris_ramp.set_color(0.45, Color(1.0, 0.45, 0.08, 1.0))
	debris_ramp.set_color(1, Color(0.35, 0.12, 0.04, 0.0))
	_debris.color_ramp = debris_ramp
	_debris.z_index = 4
	add_child(_debris)
	_debris.emitting = true

func _animate() -> void :
	var fire_scale: = 1.65 * visual_scale
	var tw_a: = create_tween()
	tw_a.set_parallel(true)
	tw_a.tween_property(_fire_a, "scale", Vector2(fire_scale, fire_scale), life * 0.8).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw_a.tween_property(_fire_a, "rotation", 0.65, life * 0.8)
	tw_a.tween_property(_fire_a, "modulate:a", 0.0, life)
	var tw_b: = create_tween()
	tw_b.set_parallel(true)
	tw_b.tween_property(_fire_b, "scale", Vector2(1.2, 1.2) * visual_scale, life * 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw_b.tween_property(_fire_b, "rotation", -0.9, life * 0.7)
	tw_b.tween_property(_fire_b, "modulate:a", 0.0, life * 0.8)

	if _tex_core:
		_core.scale = Vector2(0.45, 0.45) * visual_scale
		var tw_c: = create_tween()
		tw_c.set_parallel(true)
		tw_c.tween_property(_core, "scale", Vector2(1.25, 1.25) * visual_scale, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw_c.tween_property(_core, "modulate:a", 0.0, 0.28)

	var tw_f: = create_tween()
	tw_f.set_parallel(true)
	tw_f.tween_property(_flash, "scale", Vector2(5.5, 5.5) * visual_scale, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw_f.tween_property(_flash, "modulate:a", 0.0, 0.24)

	var tw_r1: = create_tween()
	tw_r1.set_parallel(true)
	tw_r1.tween_property(_ring_a, "scale", Vector2(2.5, 2.5) * visual_scale, 0.36).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw_r1.tween_property(_ring_a, "modulate:a", 0.0, 0.4)
	var tw_r2: = create_tween()
	tw_r2.set_parallel(true)
	tw_r2.tween_property(_ring_b, "scale", Vector2(3.6, 3.6) * visual_scale, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw_r2.tween_property(_ring_b, "modulate:a", 0.0, 0.5)

func _bake_fire(ci: CanvasItem) -> void :
	var c: = Vector2(256, 256)


	for i in range(28):
		var ang: = TAU * float(i) / 28.0 + 0.19
		var rr: = 168.0 + float((i * 37) % 58)
		var p: = c + Vector2(cos(ang), sin(ang)) * rr
		ci.draw_circle(p, 32.0 + float((i * 13) % 26), Color(0.45, 0.12, 0.04, 0.1))
		ci.draw_circle(p, 18.0 + float((i * 7) % 16), Color(0.85, 0.24, 0.04, 0.16))


	ci.draw_circle(c, 226, Color(0.65, 0.12, 0.02, 0.16))
	ci.draw_circle(c, 196, Color(0.95, 0.24, 0.03, 0.3))
	ci.draw_circle(c, 160, Color(1.0, 0.38, 0.04, 0.52))
	ci.draw_circle(c, 122, Color(1.0, 0.58, 0.1, 0.72))
	ci.draw_circle(c, 84, Color(1.0, 0.78, 0.24, 0.88))
	ci.draw_circle(c, 46, Color(1.0, 0.95, 0.62, 0.97))
	ci.draw_circle(c, 22, Color(1.0, 1.0, 0.92, 1.0))


	for i in range(34):
		var ang: = TAU * float(i) / 34.0 + 0.11
		var noise: = 0.75 + 0.25 * absf(sin(float(i) * 9.73 + 1.7))
		var length: = (150.0 + 96.0 * noise)
		var dir: = Vector2(cos(ang), sin(ang))
		var color: = Color(1.0, 0.34 + 0.22 * noise, 0.05, 0.55)
		for k in range(5):
			var t: = 0.62 + float(k) * 0.095
			var p: = c + dir * (length * t)
			var radius: = 18.0 * (1.0 - float(k) * 0.18)
			ci.draw_circle(p, radius, color)


	for i in range(18):
		var ang: = TAU * float(i) / 18.0 + 0.41
		var length: = 78.0 + 40.0 * absf(sin(float(i) * 4.17))
		var dir: = Vector2(cos(ang), sin(ang))
		for k in range(3):
			var p: = c + dir * (length * (0.55 + k * 0.18))
			ci.draw_circle(p, 11.0 - k * 2.0, Color(1.0, 0.9, 0.35, 0.6))


	for i in range(30):
		var ang: = TAU * float(i) / 30.0 + 0.31
		var r: = 190.0 + float(i % 7) * 12.0
		var p: = c + Vector2(cos(ang), sin(ang)) * r
		ci.draw_circle(p, 2.0 + float(i % 3) * 1.5, Color(1.0, 0.72, 0.25, 0.7))

func _bake_core(ci: CanvasItem) -> void :
	var c: = Vector2(128, 128)
	ci.draw_circle(c, 108, Color(1.0, 0.65, 0.15, 0.15))
	ci.draw_circle(c, 78, Color(1.0, 0.85, 0.4, 0.55))
	ci.draw_circle(c, 52, Color(1.0, 0.98, 0.8, 0.95))
	ci.draw_circle(c, 28, Color(1, 1, 1, 1))

func _physics_process(delta: float) -> void :
	_age += delta
	if not _hit_player:
		for b in get_overlapping_bodies():
			if b.is_in_group("player") and b.has_method("take_damage"):

				if b.take_damage(damage, 0.45, true):
					_hit_player = true
					break
	if _age >= life:
		queue_free()
	if _tex_fire == null:
		queue_redraw()

func _screen_flash() -> void :
	var scene: = get_tree().current_scene
	if scene == null:
		return
	var layer: = CanvasLayer.new()
	layer.layer = 110
	var rect: = ColorRect.new()
	rect.color = Color(1.0, 0.55, 0.18, 0.18)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.position = Vector2.ZERO
	rect.size = get_viewport().get_visible_rect().size
	layer.add_child(rect)
	scene.add_child(layer)
	var tw: = create_tween()
	tw.tween_property(rect, "modulate:a", 0.0, 0.22)
	tw.tween_callback(layer.queue_free)

func _shake_camera() -> void :
	var cam: = get_viewport().get_camera_2d()
	if cam == null:
		return
	var base: = cam.offset
	var tw: = cam.create_tween()
	for i in range(7):
		var t: = float(i) / 7.0
		var a: = 13.0 * (1.0 - t)
		tw.tween_property(cam, "offset", base + Vector2(randf_range( - a, a), randf_range( - a * 0.7, a * 0.7)), 0.03)
	tw.tween_property(cam, "offset", base, 0.06)

func _make_soft_texture(size: int) -> Texture2D:
	if _soft_cache.has(size):
		return _soft_cache[size]
	var img: = Image.create(size, size, false, Image.FORMAT_RGBA8)
	var c: = size * 0.5
	for y in range(size):
		for x in range(size):
			var d: = Vector2(x + 0.5 - c, y + 0.5 - c).length() / c
			var a: = pow(maxf(0.0, 1.0 - d), 2.0)
			img.set_pixel(x, y, Color(1, 1, 1, a))
	_soft_cache[size] = ImageTexture.create_from_image(img)
	return _soft_cache[size]

func _make_debris_texture() -> Texture2D:
	if _debris_cache:
		return _debris_cache
	var size: = 12
	var img: = Image.create(size, size, false, Image.FORMAT_RGBA8)
	for y in range(size):
		for x in range(size):
			var edge: = 1.0 if x < 2 or x > size - 3 or y < 2 or y > size - 3 else 0.45
			img.set_pixel(x, y, Color(1, 1, 1, edge))
	_debris_cache = ImageTexture.create_from_image(img)
	return _debris_cache

func _make_shock_texture() -> Texture2D:
	if _shock_cache:
		return _shock_cache
	var size: = 256
	var img: = Image.create(size, size, false, Image.FORMAT_RGBA8)
	var c: = size * 0.5
	for y in range(size):
		for x in range(size):
			var d: = Vector2(x + 0.5 - c, y + 0.5 - c).length() / c
			var a: = 0.0
			if d > 0.78 and d < 1.0:
				a = smoothstep(0.78, 0.88, d) * (1.0 - smoothstep(0.94, 1.0, d))
			img.set_pixel(x, y, Color(1, 1, 1, a))
	_shock_cache = ImageTexture.create_from_image(img)
	return _shock_cache

static func _additive_material() -> CanvasItemMaterial:
	var m: = CanvasItemMaterial.new()
	m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	return m

func _draw() -> void :
	if _tex_fire:
		return
	var t: = clampf(_age / life, 0.0, 1.0)
	var r: = radius * (0.35 + t * 0.9)
	var a: = 1.0 - t
	draw_circle(Vector2.ZERO, r, Color(1.0, 0.32, 0.04, a * 0.35))
	draw_circle(Vector2.ZERO, r * 0.7, Color(1.0, 0.55, 0.1, a * 0.75))
	draw_circle(Vector2.ZERO, r * 0.35, Color(1.0, 0.95, 0.7, a))
