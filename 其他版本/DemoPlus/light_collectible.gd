extends Area2D


const SAVE_PATH: = "user://collected_light.cfg"

@export var collect_id: String = "light_0"
@export var display_text: String = "微光"
@export var collected_alpha: float = 0.5
@export var collect_radius: float = 60.0
@export var mood: String = "pain"
@export var mood_lock_time: float = 1.5

var _collected: = false
var _glow: Sprite2D
var _ambient: CPUParticles2D

func _ready() -> void :
	body_entered.connect(_on_body_entered)
	monitoring = true
	monitorable = false
	z_index = 50

	var shape: = CircleShape2D.new()
	shape.radius = collect_radius
	var col: = CollisionShape2D.new()
	col.shape = shape
	add_child(col)

	_glow = Sprite2D.new()
	_glow.name = "Glow"
	_glow.texture = _make_glow_texture()
	_glow.scale = Vector2(15.0, 15.0)
	_glow.modulate = Color(1.0, 0.95, 0.7, 1.0)
	add_child(_glow)

	_ambient = CPUParticles2D.new()
	_ambient.amount = 40
	_ambient.lifetime = 1.5
	_ambient.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	_ambient.emission_sphere_radius = 40.0
	_ambient.spread = 180.0
	_ambient.direction = Vector2(0, -1)
	_ambient.gravity = Vector2(0, -10)
	_ambient.initial_velocity_min = 20.0
	_ambient.initial_velocity_max = 60.0
	_ambient.scale_amount_min = 5.0
	_ambient.scale_amount_max = 15.0
	_ambient.color = Color(1.0, 0.95, 0.7, 1.0)
	_ambient.emitting = true
	add_child(_ambient)

	if _is_collected():
		_glow.modulate = Color(0.45, 0.45, 0.45, collected_alpha)
		_ambient.color = Color(0.45, 0.45, 0.45, collected_alpha)

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

func _is_collected() -> bool:
	var cfg: = ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return false
	return cfg.has_section_key("collected", collect_id)

func _mark_collected() -> void :
	var cfg: = ConfigFile.new()
	cfg.load(SAVE_PATH)
	cfg.set_value("collected", collect_id, true)
	cfg.save(SAVE_PATH)

func _on_body_entered(body: Node2D) -> void :
	if _collected:
		return
	if not body.is_in_group("player"):
		return
	_collected = true
	_collect(body)

func _collect(player: Node2D) -> void :
	_mark_collected()

	var ap: = AudioStreamPlayer.new()
	ap.stream = load("res://sound/Sound2.mp3")
	ap.volume_db = -6.0
	add_child(ap)
	ap.play()

	var burst: = CPUParticles2D.new()
	burst.amount = 80
	burst.one_shot = true
	burst.explosiveness = 1.0
	burst.lifetime = 1.2
	burst.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	burst.emission_sphere_radius = 20.0
	burst.spread = 180.0
	burst.initial_velocity_min = 200.0
	burst.initial_velocity_max = 600.0
	burst.gravity = Vector2(0, 100)
	burst.scale_amount_min = 5.0
	burst.scale_amount_max = 15.0
	burst.color = Color(1.0, 0.95, 0.7, 1.0)
	add_child(burst)
	burst.emitting = true

	var ring: = _make_ring()
	add_child(ring)
	var ring_tw: = create_tween()
	ring_tw.tween_property(ring, "scale", Vector2(10, 10), 0.5).from(Vector2(0.5, 0.5))
	ring_tw.parallel().tween_property(ring, "modulate:a", 0.0, 0.5)
	ring_tw.tween_callback(ring.queue_free)

	var cam: = player.get_viewport().get_camera_2d()
	if cam:
		var shake: = create_tween()
		for i in range(5):
			shake.tween_property(cam, "offset:x", randf_range(-8, 8), 0.04)
		shake.tween_property(cam, "offset:x", 0, 0.05)

	if player.has_method("set_mood_expression"):
		player.set_mood_expression(mood, mood_lock_time)
	_show_floating_text(player)

	var tw: = create_tween()
	tw.set_parallel(true)
	tw.tween_property(self, "scale", Vector2(2.0, 2.0), 0.15)
	tw.tween_property(self, "modulate:a", 0.0, 0.4)
	tw.chain().tween_callback(queue_free)

func _make_ring() -> Sprite2D:
	var img: = Image.create(64, 64, false, Image.FORMAT_RGBA8)
	for y in range(64):
		for x in range(64):
			var dx: = x - 32.0
			var dy: = y - 32.0
			var d = sqrt(dx * dx + dy * dy)
			var a = 0.0
			if d > 26 and d < 32:
				a = 1.0 - (d - 26.0) / 6.0
			img.set_pixel(x, y, Color(1.0, 0.95, 0.7, a))
	var s: = Sprite2D.new()
	s.texture = ImageTexture.create_from_image(img)
	return s

func _show_floating_text(player: Node2D) -> void :
	var ft = preload("res://floating_text.gd").new()
	player.get_parent().add_child(ft)
	ft.setup(player, display_text)
