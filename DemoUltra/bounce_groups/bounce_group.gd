extends Node2D





enum Formation{RING, WAVE, SPIRAL}

@export var formation: Formation = Formation.RING
@export var radius: float = 320.0
@export var spacing: float = 260.0
@export var amplitude: float = 160.0
@export var speed: float = 0.6
@export var phase_step: float = 0.7
@export var flow_speed: float = 1.6
@export var formation_offset: float = 0.0
@export var fx_color: Color = Color(0.35, 0.95, 1.0)

var _pads: Array[Area2D] = []
var _flow: Array[Sprite2D] = []
var _flow_core: Array[Sprite2D] = []
var _time: float = 0.0
var _link: Line2D
var _link_glow: Line2D

func _enter_tree() -> void :

	for c in get_children():
		if c is Area2D and c.has_method("start_bounce"):
			c.set("fx_color", fx_color)

func _ready() -> void :
	for c in get_children():
		if c is Area2D and c.has_method("start_bounce"):
			c.set("motion", 0)
			c.set("motion_active", false)
			c.set("fx_color", fx_color)
			c.set("bounce_speed", 10000.0)
			c.scale = Vector2.ONE
			_pads.append(c)
	_build_link()
	_build_flow()

func _process(delta: float) -> void :
	_time += delta
	var n: = _pads.size()
	if n == 0:
		return

	match formation:
		Formation.RING:
			var sgn: = 1.0 if speed >= 0.0 else -1.0
			for i in range(n):
				var ang: = _time * speed + TAU * float(i) / float(n)
				var pos: = Vector2(cos(ang), sin(ang)) * radius + Vector2(formation_offset, 0.0)
				var dir: = Vector2( - sin(ang), cos(ang)) * sgn
				_place(_pads[i], pos, dir)
		Formation.WAVE:
			for i in range(n):
				var x: = (float(i) - (float(n) - 1.0) * 0.5) * spacing + formation_offset
				var y: = sin(_time * speed + float(i) * phase_step) * amplitude
				_pads[i].position = Vector2(x, y)
				_pads[i].rotation = 0.0
				_pads[i].set("bounce_direction", Vector2.UP)
		Formation.SPIRAL:
			for i in range(n):
				var base_t: = float(i) / float(maxi(1, n - 1))
				var wobble: = 0.22 * sin(_time * flow_speed + float(i) * 0.7)
				var ang: = _time * speed + float(i) * phase_step + wobble
				var breathe: = 0.5 + 0.5 * sin(_time * flow_speed - float(i) * 1.1)
				var rr: = radius * (0.6 + 0.22 * base_t + 0.14 * breathe)
				var radial: = Vector2(cos(ang), sin(ang))
				var tangent: = Vector2( - sin(ang), cos(ang))
				var dr: = radius * 0.07 * flow_speed * cos(_time * flow_speed - float(i) * 1.1)
				var dang: = speed + 0.22 * flow_speed * cos(_time * flow_speed + float(i) * 0.7)
				var flow_dir: = radial * dr + tangent * (rr * dang)
				_place(_pads[i], radial * rr + Vector2(formation_offset, 0.0), flow_dir)
				var glow: = 1.0 + 0.15 * sin(_time * flow_speed * 2.2 - float(i) * 1.1)
				_pads[i].modulate = Color(glow, glow, glow, 1.0)

	_update_link()
	_update_flow()

func _place(pad: Area2D, pos: Vector2, dir: Vector2) -> void :
	pad.position = pos
	var d: = dir.normalized()
	pad.set("bounce_direction", d)
	pad.rotation = d.angle() + PI * 0.5

func _build_link() -> void :
	_link_glow = Line2D.new()
	_link_glow.width = 18.0
	_link_glow.default_color = Color(fx_color.r, fx_color.g, fx_color.b, 0.1)
	_link_glow.material = _add_material()
	_link_glow.z_index = 1
	add_child(_link_glow)

	_link = Line2D.new()
	_link.width = 5.0
	_link.default_color = Color(fx_color.r, fx_color.g, fx_color.b, 0.4)
	_link.material = _add_material()
	_link.z_index = 1
	_link.closed = formation == Formation.RING
	add_child(_link)

func _build_flow() -> void :
	if formation != Formation.SPIRAL:
		return
	for i in range(6):
		var s: = Sprite2D.new()
		s.texture = _make_glow_texture(32)
		s.material = _add_material()
		s.modulate = Color(fx_color.r, fx_color.g, fx_color.b, 0.0)
		s.scale = Vector2(5.0, 5.0)
		s.z_index = 3
		add_child(s)
		_flow.append(s)

		var core: = Sprite2D.new()
		core.texture = s.texture
		core.material = _add_material()
		core.modulate = Color(1, 1, 1, 0.0)
		core.scale = Vector2(1.7, 1.7)
		core.z_index = 4
		add_child(core)
		_flow_core.append(core)

func _update_flow() -> void :
	if _flow.is_empty() or _link == null or _link.points.size() < 2:
		return
	var pts: = _link.points
	for i in range(_flow.size()):
		var t: = fmod(_time * 0.34 + float(i) / float(_flow.size()), 1.0)
		var pos: = _sample_polyline(pts, t, false)
		_flow[i].position = pos
		_flow[i].modulate.a = 0.75 + 0.2 * sin(_time * 7.0 + float(i))
		var s: = 5.0 + 0.6 * sin(_time * 7.0 + float(i))
		_flow[i].scale = Vector2(s, s)
		if i < _flow_core.size():
			_flow_core[i].position = pos
			_flow_core[i].modulate.a = 0.85
			var cs: = 1.6 + 0.25 * sin(_time * 7.0 + float(i))
			_flow_core[i].scale = Vector2(cs, cs)

func _sample_polyline(points: PackedVector2Array, t: float, closed: bool) -> Vector2:
	var count: = points.size()
	if count == 0:
		return Vector2.ZERO
	if count == 1:
		return points[0]
	var segs: = count if closed else count - 1
	var total: = 0.0
	var lens: Array[float] = []
	for i in range(segs):
		var d: = points[i].distance_to(points[(i + 1) % count])
		lens.append(d)
		total += d
	if total <= 0.0:
		return points[0]
	var target: = clampf(t, 0.0, 0.999999) * total
	for i in range(segs):
		if target <= lens[i]:
			var f: = 0.0 if lens[i] <= 0.0 else target / lens[i]
			return points[i].lerp(points[(i + 1) % count], f)
		target -= lens[i]
	return points[count - 1]

static func _make_glow_texture(size: int) -> Texture2D:
	var img: = Image.create(size, size, false, Image.FORMAT_RGBA8)
	var c: = size * 0.5
	for y in range(size):
		for x in range(size):
			var d: = Vector2(x + 0.5 - c, y + 0.5 - c).length() / c
			var a: = pow(maxf(0.0, 1.0 - d), 2.4)
			img.set_pixel(x, y, Color(1, 1, 1, a))
	return ImageTexture.create_from_image(img)

func _update_link() -> void :
	if _link == null:
		return
	var pts: = PackedVector2Array()
	for p in _pads:
		pts.append(p.position)
	_link.points = pts
	_link_glow.points = pts
	_link.closed = formation == Formation.RING
	_link_glow.closed = _link.closed

static func _add_material() -> CanvasItemMaterial:
	var m: = CanvasItemMaterial.new()
	m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	return m
