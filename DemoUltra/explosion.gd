extends Area2D
class_name Explosion


const BLAST_SHADER: = preload("res://explosion.gdshader")

static var _white_tex: Texture2D = null
static var _soft_tex: Texture2D = null
static var _ember_tex: Texture2D = null

@export var core_radius: float = 384.0
@export var outer_radius: float = 736.0
@export var core_damage: float = 50.0
@export var outer_damage: float = 50.0
@export var blast_life: float = 0.55

var _life: float = 0.55
var _age: float = 0.0
var _armed: bool = false
var _fireball: Sprite2D
var _mat: ShaderMaterial

func _ready() -> void :
	collision_layer = 0
	collision_mask = 3
	z_index = 8
	_life = blast_life

	var cs: = CollisionShape2D.new()
	var circle: = CircleShape2D.new()
	circle.radius = outer_radius
	cs.shape = circle
	add_child(cs)

	_white_tex = _get_white_texture()
	_soft_tex = _get_soft_texture()
	_ember_tex = _get_ember_texture()

	_mat = ShaderMaterial.new()
	_mat.shader = BLAST_SHADER
	_mat.set_shader_parameter("progress", 0.0)
	_mat.set_shader_parameter("seed", randf() * 10.0)

	_fireball = Sprite2D.new()
	_fireball.centered = true
	_fireball.texture = _white_tex
	_fireball.material = _mat
	_fireball.scale = Vector2((outer_radius * 2.0) / 64.0, (outer_radius * 2.0) / 64.0)
	_fireball.z_index = 1
	add_child(_fireball)

	var embers: = CPUParticles2D.new()
	embers.amount = 26
	embers.one_shot = true
	embers.explosiveness = 1.0
	embers.lifetime = 0.65
	embers.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	embers.emission_sphere_radius = 42.0
	embers.direction = Vector2.RIGHT
	embers.spread = 180.0
	embers.initial_velocity_min = 260.0
	embers.initial_velocity_max = 720.0
	embers.gravity = Vector2(0, 620)
	embers.scale_amount_min = 0.25
	embers.scale_amount_max = 0.75
	embers.texture = _ember_tex
	var ramp: = Gradient.new()
	ramp.set_color(0, Color(1.0, 0.9, 0.5, 1.0))
	ramp.set_color(1, Color(1.0, 0.25, 0.03, 0.0))
	embers.color_ramp = ramp
	embers.z_index = 2
	add_child(embers)
	embers.emitting = true

	var smoke: = CPUParticles2D.new()
	smoke.amount = 10
	smoke.one_shot = true
	smoke.explosiveness = 1.0
	smoke.lifetime = 0.9
	smoke.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	smoke.emission_sphere_radius = 46.0
	smoke.direction = Vector2.UP
	smoke.spread = 70.0
	smoke.initial_velocity_min = 25.0
	smoke.initial_velocity_max = 85.0
	smoke.gravity = Vector2(0, -15)
	smoke.scale_amount_min = 0.6
	smoke.scale_amount_max = 1.5
	smoke.texture = _soft_tex
	var sr: = Gradient.new()
	sr.set_color(0, Color(0.16, 0.13, 0.12, 0.35))
	sr.set_color(1, Color(0.03, 0.03, 0.04, 0.0))
	smoke.color_ramp = sr
	smoke.z_index = 1
	add_child(smoke)
	smoke.emitting = true

	_shake_camera()
	_screen_flash()

func _physics_process(delta: float) -> void :
	if not _armed:
		_armed = true
		_apply_damage()
	_age += delta
	var p: = clampf(_age / _life, 0.0, 1.0)
	if _mat:
		_mat.set_shader_parameter("progress", p)
	if _age >= _life:
		queue_free()

func _apply_damage() -> void :
	var player: = get_tree().get_first_node_in_group("player")
	if not is_instance_valid(player) or not player.has_method("take_damage"):
		return
	var d: Vector2 = player.global_position - global_position
	if d.length() <= outer_radius:

		player.take_damage(core_damage, 0.6)

func _shake_camera() -> void :
	var cam: = get_viewport().get_camera_2d()
	if cam == null:
		return
	var base: = cam.offset
	var tw: = cam.create_tween()
	for i in range(5):
		var t: = float(i) / 5.0
		var a: = 8.0 * (1.0 - t)
		tw.tween_property(cam, "offset", base + Vector2(randf_range( - a, a), randf_range( - a * 0.7, a * 0.7)), 0.025)
	tw.tween_property(cam, "offset", base, 0.05)

func _screen_flash() -> void :
	var scene: = get_tree().current_scene
	if scene == null:
		return
	var layer: = CanvasLayer.new()
	layer.layer = 100
	var rect: = ColorRect.new()
	rect.color = Color(1.0, 0.72, 0.3, 0.16)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.position = Vector2.ZERO
	rect.size = get_viewport().get_visible_rect().size
	layer.add_child(rect)
	scene.add_child(layer)
	var tw: = create_tween()
	tw.tween_property(rect, "modulate:a", 0.0, 0.14)
	tw.tween_callback(layer.queue_free)

func _get_white_texture() -> Texture2D:
	if _white_tex:
		return _white_tex
	var img: = Image.create(64, 64, false, Image.FORMAT_RGBA8)
	img.fill(Color(1, 1, 1, 1))
	_white_tex = ImageTexture.create_from_image(img)
	return _white_tex

func _get_soft_texture() -> Texture2D:
	if _soft_tex:
		return _soft_tex
	var size: = 32
	var img: = Image.create(size, size, false, Image.FORMAT_RGBA8)
	var c: = size * 0.5
	for y in range(size):
		for x in range(size):
			var d: = Vector2(x + 0.5 - c, y + 0.5 - c).length() / c
			var a: = pow(maxf(0.0, 1.0 - d), 2.0)
			img.set_pixel(x, y, Color(1, 1, 1, a))
	_soft_tex = ImageTexture.create_from_image(img)
	return _soft_tex

func _get_ember_texture() -> Texture2D:
	if _ember_tex:
		return _ember_tex
	var size: = 12
	var img: = Image.create(size, size, false, Image.FORMAT_RGBA8)
	for y in range(size):
		for x in range(size):
			var edge: = 1.0 if x < 2 or x > size - 3 or y < 2 or y > size - 3 else 0.45
			img.set_pixel(x, y, Color(1, 1, 1, edge))
	_ember_tex = ImageTexture.create_from_image(img)
	return _ember_tex

func _draw() -> void :

	var t: = clampf(_age / _life, 0.0, 1.0)
	var a: = clampf(1.0 - t, 0.0, 1.0)
	draw_circle(Vector2.ZERO, core_radius * (0.5 + t * 0.5), Color(1.0, 0.45, 0.08, a * 0.55))
	draw_circle(Vector2.ZERO, core_radius * (0.25 + t * 0.25), Color(1.0, 0.85, 0.4, a))
