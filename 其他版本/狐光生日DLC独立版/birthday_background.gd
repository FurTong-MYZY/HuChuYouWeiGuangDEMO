extends Node2D


const VIEW: = Vector2(1152, 648)
var _t: float = 0.0
var _stars: Array[Dictionary] = []
var _balloons: Array[Dictionary] = []

func _ready() -> void :
	z_index = -10
	seed(20261111)
	for i in range(96):
		_stars.append({
			"p": Vector2(randf_range(20, 1132), randf_range(18, 420)), 
			"r": randf_range(0.7, 2.0), 
			"a": randf_range(0.25, 0.9), 
		})
	var colors: = [
		Color(1.0, 0.55, 0.62), Color(1.0, 0.78, 0.4), Color(0.6, 0.7, 1.0), 
		Color(0.7, 0.55, 1.0), Color(0.55, 0.9, 0.8)
	]
	for i in range(7):
		_balloons.append({
			"p": Vector2(70 + i * 166 + randf_range(-30, 30), 150 + randf_range(-55, 65)), 
			"c": colors[i % colors.size()], 
			"s": randf_range(0.75, 1.25), 
		})
	queue_redraw()
	set_process(false)

func _process(_delta: float) -> void :
	pass

func _draw() -> void :
	for i in range(72):
		var t: = float(i) / 71.0
		var c: = Color(0.035, 0.035, 0.1).lerp(Color(0.2, 0.1, 0.23), t)
		draw_rect(Rect2(0, i * 9, VIEW.x, 10), c)
	for s in _stars:
		var a: float = s["a"] * (0.7 + 0.3 * sin(_t * 1.4 + s["p"].x))
		draw_circle(s["p"], s["r"], Color(1.0, 0.9, 0.75, a))
	draw_circle(Vector2(944, 112), 52.0, Color(1.0, 0.82, 0.56, 0.05))
	draw_circle(Vector2(944, 112), 34.0, Color(1.0, 0.9, 0.68, 0.2))
	draw_circle(Vector2(944, 112), 24.0, Color(1.0, 0.95, 0.78, 0.9))
	draw_circle(Vector2(954, 104), 5.0, Color(0.95, 0.85, 0.68, 0.5))
	draw_circle(Vector2(932, 120), 3.0, Color(0.95, 0.85, 0.68, 0.4))
	for k in range(3):
		var pts: = PackedVector2Array()
		for x in range(0, 1160, 18):
			var y: = 190.0 + k * 34.0 + sin(x * 0.008 + _t * 0.25 + k) * 22.0
			pts.append(Vector2(x, y))
		draw_polyline(pts, Color(0.35, 0.72, 0.75, 0.06 - k * 0.012), 18.0)
	for i in range(16):
		var bx: = i * 78.0 + 10.0
		var bh: = 40.0 + (i * 37 % 90)
		draw_rect(Rect2(bx, 560 - bh, 54, bh), Color(0.06, 0.05, 0.12, 0.6))
		for w in range(2):
			draw_rect(Rect2(bx + 11 + w * 20, 525 - bh, 4, 4), Color(1.0, 0.7, 0.4, 0.18))
	var bunting: = PackedVector2Array()
	for x in range(0, 1160, 32):
		bunting.append(Vector2(x, 46 + sin(x * 0.02) * 9))
	draw_polyline(bunting, Color(1.0, 0.72, 0.55, 0.35), 1.0)
	for i in range(0, 1160, 64):
		var y: = 46 + sin(i * 0.02) * 9
		draw_colored_polygon(PackedVector2Array([Vector2(i, y), Vector2(i + 18, y), Vector2(i + 9, y + 18)]), Color(1.0, 0.55, 0.55, 0.5) if i % 128 == 0 else Color(1.0, 0.78, 0.45, 0.45))
	for b in _balloons:
		var p: Vector2 = b["p"]
		var c: Color = b["c"]
		var sf: float = b["s"]
		draw_line(p + Vector2(0, 26 * sf), p + Vector2(sin(_t + p.x) * 8, 90), Color(0.85, 0.75, 0.7, 0.28), 1.0)
		draw_colored_polygon(_ellipse(p, Vector2(18, 23) * sf, 20), Color(c.r, c.g, c.b, 0.65))
		draw_colored_polygon(_ellipse(p + Vector2(-5, -6) * sf, Vector2(6, 8) * sf, 12), Color(1, 1, 1, 0.12))
	draw_rect(Rect2(0, 596, VIEW.x, 52), Color(0.12, 0.075, 0.13))
	draw_rect(Rect2(0, 596, VIEW.x, 4), Color(0.85, 0.55, 0.48, 0.35))
	draw_colored_polygon(_ellipse(Vector2(560, 624), Vector2(440, 16), 36), Color(0.3, 0.14, 0.22, 0.55))
	_draw_gift(Vector2(620, 596), Color(0.55, 0.35, 0.85), Color(1.0, 0.72, 0.5))
	_draw_gift(Vector2(950, 596), Color(0.85, 0.35, 0.45), Color(1.0, 0.85, 0.55))

func _draw_gift(p: Vector2, body: Color, ribbon: Color) -> void :
	draw_rect(Rect2(p.x - 30, p.y - 46, 60, 46), Color(0, 0, 0, 0.25))
	draw_rect(Rect2(p.x - 26, p.y - 44, 52, 44), body)
	draw_rect(Rect2(p.x - 4, p.y - 44, 8, 44), ribbon)
	draw_rect(Rect2(p.x - 26, p.y - 30, 52, 6), ribbon)
	draw_colored_polygon(PackedVector2Array([Vector2(p.x, p.y - 44), Vector2(p.x - 15, p.y - 56), Vector2(p.x - 2, p.y - 52)]), ribbon)
	draw_colored_polygon(PackedVector2Array([Vector2(p.x, p.y - 44), Vector2(p.x + 15, p.y - 56), Vector2(p.x + 2, p.y - 52)]), ribbon)

func _ellipse(c: Vector2, r: Vector2, steps: int) -> PackedVector2Array:
	var pts: = PackedVector2Array()
	for i in range(steps):
		var a: = TAU * float(i) / float(steps)
		pts.append(c + Vector2(cos(a) * r.x, sin(a) * r.y))
	return pts
