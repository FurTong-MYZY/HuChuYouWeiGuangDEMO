extends Area2D
class_name Bullet



static var _cached_tex: Texture2D = null
static var _blood_tex: Texture2D = null

@export var direction: float = 1.0
@export var speed: float = 2800.0
@export var damage: float = 75.0
@export var life: float = 3.0

var _age: float = 0.0
var _ray: RayCast2D
var _hit: bool = false
var _sprite: Sprite2D
var _tex: Texture2D

func _ready() -> void :
	collision_layer = 0
	collision_mask = 3
	z_index = 10

	var shape: = CircleShape2D.new()
	shape.radius = 6.0 * PixelArt.SCALE
	var cs: = CollisionShape2D.new()
	cs.shape = shape
	add_child(cs)

	_ray = RayCast2D.new()
	_ray.target_position = Vector2(direction * 14.0 * PixelArt.SCALE, 0)
	_ray.collision_mask = 1
	add_child(_ray)

	_sprite = Sprite2D.new()
	_sprite.centered = true
	_sprite.scale = Vector2(0.6, 0.6)
	add_child(_sprite)
	if _cached_tex == null:
		_cached_tex = await PixelArt.bake_texture(_bake, Vector2i(34 * PixelArt.SCALE, 14 * PixelArt.SCALE), self)
	_tex = _cached_tex
	if _tex:
		_sprite.texture = _tex
		_sprite.flip_h = direction < 0

	if _tex == null:
		queue_redraw()

	body_entered.connect(_on_body_entered)

func _bake(ci: CanvasItem) -> void :
	var s: = PixelArt.SCALE

	ci.draw_set_transform(Vector2(28.5 * s, 7 * s), 0.0, Vector2(s, s))
	for i in range(4):
		var t: = i / 4.0
		var c: = Color(1.0, 0.7, 0.3, 0.55 * (1.0 - t))
		var r: = 6.0 * (1.0 - t * 0.6)
		ci.draw_circle(Vector2( - i * 7.0, 0), r, c)
	ci.draw_circle(Vector2.ZERO, 6.5, Color(1.0, 0.55, 0.15, 1.0))
	ci.draw_circle(Vector2(1.0, 0), 3.5, Color(1.0, 1.0, 0.9, 1.0))

func _physics_process(delta: float) -> void :
	_age += delta
	if _age > life:
		_spark(global_position)
		queue_free()
		return

	position += Vector2(direction * speed * delta, 0)

	if _ray.is_colliding():
		var collider: Object = _ray.get_collider()
		if not (collider and collider is Node and collider.is_in_group("player")):
			_spark(global_position)
			queue_free()
			return

	if _hit:
		return
	var bodies: = get_overlapping_bodies()
	for b in bodies:
		if b.is_in_group("player") and b.has_method("take_damage"):
			var info: = _hit_info(b, global_position)
			if b.take_damage(info.damage, 0.6):
				if b.get("shield_absorbed_last_hit"):
					_spark(global_position)
				else:
					_spawn_blood(global_position, info.part)
					_spawn_damage_number(global_position, info.damage)
				_hit = true
				queue_free()
				return

func _on_body_entered(body: Node) -> void :
	if _hit:
		return
	if body.is_in_group("player") and body.has_method("take_damage"):
		var info: = _hit_info(body, global_position)
		if body.take_damage(info.damage, 0.6):
			if body.get("shield_absorbed_last_hit"):
				_spark(global_position)
			else:
				_spawn_blood(global_position, info.part)
				_spawn_damage_number(global_position, info.damage)
			_hit = true
			queue_free()

func _hit_info(player: Node2D, hit_pos: Vector2) -> Dictionary:
	var part: = "body"
	var dmg: = 50.0
	var spr: Sprite2D = player.get_node_or_null("Sprite2D") as Sprite2D
	if spr and spr.texture:
		var local: = spr.to_local(hit_pos)
		var norm: = local.y / float(spr.texture.get_height()) + 0.5
		if norm < 0.33:
			part = "head"
			dmg = 75.0
		elif norm > 0.67:
			part = "legs"
			dmg = 30.0
	else:
		var dy: float = hit_pos.y - player.global_position.y
		if dy < -110.0:
			part = "head"
			dmg = 75.0
		elif dy > 130.0:
			part = "legs"
			dmg = 30.0
	return {"part": part, "damage": dmg}

func _spawn_damage_number(hit_pos: Vector2, amount: float) -> void :
	var scene: = get_tree().current_scene
	if scene == null:
		return
	var layer: = CanvasLayer.new()
	layer.layer = 50
	scene.add_child(layer)
	var label: = Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.text = "-%d" % int(round(amount))
	label.add_theme_font_override("font", load("res://fonts/TitleFont.ttf"))
	label.add_theme_font_size_override("font_size", 24)
	label.add_theme_color_override("font_color", Color(1.0, 0.12, 0.08, 1.0))
	label.add_theme_color_override("font_outline_color", Color(0.18, 0.0, 0.0, 0.95))
	label.add_theme_constant_override("outline_size", 4)
	label.z_index = 100
	var screen: = get_viewport().get_canvas_transform() * hit_pos
	label.position = screen + Vector2(-18, -42)
	layer.add_child(label)
	label.scale = Vector2(1.2, 1.2)
	var tw: = layer.create_tween()
	tw.set_parallel(true)
	tw.tween_property(label, "position:y", label.position.y - 46.0, 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(label, "modulate:a", 0.0, 0.55)
	tw.tween_property(label, "scale", Vector2(0.9, 0.9), 0.55)
	tw.chain().tween_callback(layer.queue_free)

func _spawn_blood(hit_pos: Vector2, part: String) -> void :
	var scene: = get_tree().current_scene
	if scene == null:
		return
	var p: = CPUParticles2D.new()
	p.amount = 20 if part == "head" else (10 if part == "legs" else 14)
	p.lifetime = 0.55
	p.one_shot = true
	p.explosiveness = 1.0
	p.emitting = true
	p.local_coords = false
	p.direction = Vector2( - direction, -0.22).normalized()
	p.spread = 58.0
	p.initial_velocity_min = 130.0 if part == "head" else 90.0
	p.initial_velocity_max = 310.0 if part == "head" else 220.0
	p.gravity = Vector2(0, 820)
	p.scale_amount_min = 0.7
	p.scale_amount_max = 1.8
	p.texture = _make_blood_texture()
	var ramp: = Gradient.new()
	ramp.set_color(0, Color(0.72, 0.01, 0.02, 0.95))
	ramp.set_color(1, Color(0.32, 0.0, 0.01, 0.0))
	p.color_ramp = ramp
	p.z_index = 20
	scene.add_child(p)
	p.global_position = hit_pos
	get_tree().create_timer(p.lifetime + 0.25).timeout.connect(p.queue_free)
	_spark(hit_pos)

static func _make_blood_texture() -> Texture2D:
	if _blood_tex:
		return _blood_tex
	var size: = 24
	var img: = Image.create(size, size, false, Image.FORMAT_RGBA8)
	var c: = size * 0.5
	for y in range(size):
		for x in range(size):
			var d: = Vector2(x + 0.5 - c, y + 0.5 - c).length() / c
			var a: = pow(maxf(0.0, 1.0 - d), 1.8)
			img.set_pixel(x, y, Color(1, 1, 1, a))
	_blood_tex = ImageTexture.create_from_image(img)
	return _blood_tex

func _draw() -> void :
	if _tex:
		return
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(PixelArt.SCALE, PixelArt.SCALE))
	for i in range(4):
		var t: = i / 4.0
		var c: = Color(1.0, 0.7, 0.3, 0.55 * (1.0 - t))
		var r: = 6.0 * (1.0 - t * 0.6)
		draw_circle(Vector2( - direction * i * 7.0, 0), r, c)
	draw_circle(Vector2.ZERO, 6.5, Color(1.0, 0.55, 0.15, 1.0))
	draw_circle(Vector2(direction * 1.0, 0), 3.5, Color(1.0, 1.0, 0.9, 1.0))

func _spark(pos: Vector2) -> void :
	var s: Spark = Spark.new()
	get_tree().current_scene.add_child(s)
	s.global_position = pos
	s.setup(Color(1.0, 0.7, 0.3), 8, 80.0 * PixelArt.SCALE)
