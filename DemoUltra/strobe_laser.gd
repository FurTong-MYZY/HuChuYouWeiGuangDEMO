extends Area2D
class_name StrobeLaser





enum LaserShape{STRAIGHT, CURVE}
enum Phase{IDLE, WARNING, ACTIVE}

@export var shape_type: LaserShape = LaserShape.STRAIGHT
@export var end_point: Vector2 = Vector2(440, 0)
@export var curve_points: PackedVector2Array = []
@export var beam_width: float = 112.0
@export var idle_period: float = 2.0
@export var warning_period: float = 0.45
@export var active_period: float = 0.7
@export var sample_step: float = 80.0

var _phase: int = Phase.IDLE
var _timer: float = 0.0
var _samples: Array[Vector2] = []
var _inside: Array = []
var _bbox: Rect2
var _dash_sprite: Sprite2D
var _solid_sprite: Sprite2D
var _tex_dash: Texture2D
var _tex_solid: Texture2D

const BEAM: = Color(0.68, 0.25, 1.0)
const BEAM_HOT: = Color(0.85, 0.45, 1.0)

func _ready() -> void :
	collision_layer = 0
	collision_mask = 3
	monitoring = false
	monitorable = false
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	end_point *= PixelArt.SCALE
	for i in curve_points.size():
		curve_points[i] *= PixelArt.SCALE
	_samples = _sample_path()
	_bbox = _compute_bbox()

	_dash_sprite = Sprite2D.new()
	_dash_sprite.centered = false
	_dash_sprite.position = _bbox.position
	_dash_sprite.modulate = Color(BEAM.r, BEAM.g, BEAM.b, 0.45)
	add_child(_dash_sprite)
	_solid_sprite = Sprite2D.new()
	_solid_sprite.centered = false
	_solid_sprite.position = _bbox.position
	_solid_sprite.visible = false
	add_child(_solid_sprite)

	_tex_dash = await PixelArt.bake_texture(_bake_dash, Vector2i(_bbox.size), self)
	_tex_solid = await PixelArt.bake_texture(_bake_solid, Vector2i(_bbox.size), self)
	if _tex_dash:
		_dash_sprite.texture = _tex_dash
	if _tex_solid:
		_solid_sprite.texture = _tex_solid
	if _tex_dash == null:
		queue_redraw()

	_build_collisions()
	set_deferred("monitoring", false)

func _compute_bbox() -> Rect2:
	var r: = Rect2(_samples[0], Vector2.ZERO)
	for p in _samples:
		r = r.expand(p)
	r = r.grow(beam_width)
	return r

func _bake_dash(ci: CanvasItem) -> void :
	var offset: = - _bbox.position
	var dash_len: = 16.0
	var gap_len: = 14.0
	var dist: = 0.0
	var i: = 0
	while i < _samples.size():
		var p: = _samples[i] + offset
		if int(dist / (dash_len + gap_len)) % 2 == 0:
			ci.draw_circle(p, beam_width * 0.4, Color(1, 1, 1, 0.35))
			ci.draw_circle(p, beam_width * 0.16, Color(1, 1, 1, 0.5))
		i += 1
		dist += sample_step
	ci.draw_circle(_samples[0] + offset, 9.0 * PixelArt.SCALE, Color(0.9, 0.9, 0.9, 0.9))
	ci.draw_circle(_samples[0] + offset, 4.5 * PixelArt.SCALE, Color(1, 1, 1, 0.6))

func _bake_solid(ci: CanvasItem) -> void :
	var offset: = - _bbox.position
	for p in _samples:
		ci.draw_circle(p + offset, beam_width * 0.95, Color(1, 1, 1, 0.1))
	for p in _samples:
		ci.draw_circle(p + offset, beam_width * 0.62, Color(1, 1, 1, 0.32))
	for p in _samples:
		ci.draw_circle(p + offset, beam_width * 0.5, Color(1, 1, 1, 0.85))
	for p in _samples:
		ci.draw_circle(p + offset, beam_width * 0.2, Color(1, 1, 1, 0.95))

func _physics_process(delta: float) -> void :
	_timer += delta
	match _phase:
		Phase.IDLE:
			if _timer >= idle_period - warning_period:
				_set_phase(Phase.WARNING)
		Phase.WARNING:
			if _timer >= idle_period:
				_set_phase(Phase.ACTIVE)
		Phase.ACTIVE:
			_poll_overlaps()
			if _timer >= idle_period + active_period:
				_set_phase(Phase.IDLE)
				_timer = 0.0


	if _tex_dash:
		if _phase == Phase.WARNING:
			var w: = 0.7 + 0.3 * sin(_timer * 40.0)
			_dash_sprite.visible = true
			_dash_sprite.modulate = Color(1.0, 0.5, 0.4, w)
		elif _phase == Phase.IDLE:
			_dash_sprite.visible = true
			_dash_sprite.modulate = Color(BEAM.r, BEAM.g, BEAM.b, 0.45)
		else:
			_dash_sprite.visible = false
		if _tex_solid:
			if _phase == Phase.ACTIVE:
				var flicker: = 0.9 + 0.1 * sin(Time.get_ticks_msec() * 0.05)
				_solid_sprite.visible = true
				_solid_sprite.modulate = Color(BEAM_HOT.r, BEAM_HOT.g, BEAM_HOT.b, flicker)
			else:
				_solid_sprite.visible = false

func _poll_overlaps() -> void :
	if not monitoring:
		return
	var current: = get_overlapping_bodies()
	for b in current:
		if b.is_in_group("player") and not _inside.has(b):
			_inside.append(b)
			if b.has_method("add_contamination_source"):
				b.add_contamination_source(self)
	for b in _inside.duplicate():
		if not is_instance_valid(b) or not current.has(b):
			_inside.erase(b)
			if is_instance_valid(b) and b.has_method("remove_contamination_source"):
				b.remove_contamination_source(self)

func _set_phase(p: int) -> void :
	_phase = p
	if p == Phase.ACTIVE:
		set_deferred("monitoring", true)
		set_deferred("monitorable", true)
	else:
		set_deferred("monitoring", false)
		set_deferred("monitorable", false)
		for b in _inside:
			if is_instance_valid(b) and b.has_method("remove_contamination_source"):
				b.remove_contamination_source(self)
		_inside.clear()

func _on_body_entered(body: Node) -> void :
	if body.is_in_group("player") and _phase == Phase.ACTIVE:
		if not _inside.has(body):
			_inside.append(body)
		if body.has_method("add_contamination_source"):
			body.add_contamination_source(self)

func _on_body_exited(body: Node) -> void :
	_inside.erase(body)
	if body.is_in_group("player") and body.has_method("remove_contamination_source"):
		body.remove_contamination_source(self)

func _sample_path() -> Array[Vector2]:
	if shape_type == LaserShape.STRAIGHT:
		return _sample_line(Vector2.ZERO, end_point)
	return _sample_curve(curve_points)

func _sample_line(a: Vector2, b: Vector2) -> Array[Vector2]:
	var pts: Array[Vector2] = []
	var dist: = a.distance_to(b)
	var n: int = max(1, int(dist / sample_step))
	for i in range(n + 1):
		pts.append(a.lerp(b, float(i) / n))
	return pts

func _sample_curve(points: PackedVector2Array) -> Array[Vector2]:
	var pts: Array[Vector2] = []
	if points.size() < 2:
		return _sample_line(Vector2.ZERO, end_point)
	var cp: Array = []
	for p in points: cp.append(p)
	var ext: Array = [cp[0]] + cp + [cp[-1]]
	for seg in range(1, ext.size() - 2):
		var p0: Vector2 = ext[seg - 1]
		var p1: Vector2 = ext[seg]
		var p2: Vector2 = ext[seg + 1]
		var p3: Vector2 = ext[seg + 2]
		var seg_len: = p1.distance_to(p2)
		var steps: int = max(1, int(seg_len / sample_step))
		for i in range(steps):
			pts.append(_catmull(p0, p1, p2, p3, float(i) / steps))
	pts.append(ext[-2])
	return pts

func _catmull(p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2, t: float) -> Vector2:
	var t2: = t * t
	var t3: = t2 * t
	return 0.5 * (
		2.0 * p1
		+ ( - p0 + p2) * t
		+ (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t2
		+ ( - p0 + 3.0 * p1 - 3.0 * p2 + p3) * t3
	)

func _build_collisions() -> void :
	if _samples.size() < 2:
		return
	if shape_type == LaserShape.STRAIGHT:
		var a: = _samples[0]
		var b: = _samples[_samples.size() - 1]
		var len: = a.distance_to(b)
		if len <= 0.01:
			return
		var cs: = CollisionShape2D.new()
		var rect: = RectangleShape2D.new()
		rect.size = Vector2(len, beam_width)
		cs.shape = rect
		cs.position = (a + b) * 0.5
		cs.rotation = (b - a).angle()
		add_child(cs)
		return


	var half: = beam_width * 0.5
	var left: Array[Vector2] = []
	var right: Array[Vector2] = []
	for i in range(_samples.size()):
		var prev: = _samples[maxi(0, i - 1)]
		var next: = _samples[mini(_samples.size() - 1, i + 1)]
		var dir: = (next - prev).normalized()
		if dir == Vector2.ZERO:
			dir = Vector2.RIGHT
		var normal: = Vector2( - dir.y, dir.x) * half
		left.append(_samples[i] + normal)
		right.append(_samples[i] - normal)
	var poly: = PackedVector2Array()
	for p in left:
		poly.append(p)
	for i in range(right.size() - 1, -1, -1):
		poly.append(right[i])
	var cp: = CollisionPolygon2D.new()
	cp.polygon = poly
	add_child(cp)

func _draw() -> void :

	if _tex_dash:
		return
	if _samples.size() < 2:
		return
	if _phase == Phase.ACTIVE:
		var flicker: = 0.9 + 0.1 * sin(Time.get_ticks_msec() * 0.05)
		for i in range(_samples.size()):
			draw_circle(_samples[i], beam_width * 0.95, Color(BEAM.r, BEAM.g, BEAM.b, 0.1 * flicker))
		for i in range(_samples.size()):
			draw_circle(_samples[i], beam_width * 0.62, Color(BEAM.r, BEAM.g, BEAM.b, 0.32 * flicker))
		for i in range(_samples.size()):
			draw_circle(_samples[i], beam_width * 0.5, Color(BEAM_HOT.r, BEAM_HOT.g, BEAM_HOT.b, 0.85 * flicker))
		for i in range(_samples.size()):
			draw_circle(_samples[i], beam_width * 0.2, Color(0.96, 0.9, 1.0, 0.95))
	else:
		var alpha: = 0.7 + 0.3 * sin(_timer * 40.0) if _phase == Phase.WARNING else 0.45
		var col: = Color(1.0, 0.5, 0.4) if _phase == Phase.WARNING else BEAM
		var dash_len: = 16.0
		var gap_len: = 14.0
		var dist: = 0.0
		var i: = 0
		while i < _samples.size():
			var p: = _samples[i]
			if int(dist / (dash_len + gap_len)) % 2 == 0:
				draw_circle(p, beam_width * 0.4, Color(col.r, col.g, col.b, 0.35 * alpha))
				draw_circle(p, beam_width * 0.16, Color(0.9, 0.85, 1.0, 0.5 * alpha))
			i += 1
			dist += sample_step
		draw_circle(_samples[0], 9.0 * PixelArt.SCALE, Color(0.2, 0.1, 0.3, 0.9))
		draw_circle(_samples[0], 4.5 * PixelArt.SCALE, Color(col.r, col.g, col.b, 0.6 * alpha))
