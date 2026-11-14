extends Node2D


var lit: bool = false
var _t: float = 0.0

func _ready() -> void :
	z_index = 5
	_t = randf() * TAU

func light_up() -> void :
	lit = true
	queue_redraw()

func _process(delta: float) -> void :
	_t += delta
	queue_redraw()

func _draw() -> void :
	var bob: = sin(_t * 1.5) * 2.0
	var halo: = 0.5 + 0.5 * sin(_t * 2.2)
	if lit:
		draw_circle(Vector2(0, -40 + bob), 92.0, Color(1.0, 0.68, 0.35, 0.06))
		draw_circle(Vector2(0, -40 + bob), 58.0, Color(1.0, 0.75, 0.42, 0.09 + halo * 0.03))

	draw_ellipse(Vector2(0, 4), Vector2(72, 14), Color(0.55, 0.38, 0.4))
	draw_ellipse(Vector2(0, 1), Vector2(66, 12), Color(0.8, 0.62, 0.55))

	draw_rect(Rect2(-50, -34 + bob, 100, 36), Color(0.98, 0.65, 0.72))
	draw_rect(Rect2(-44, -66 + bob, 88, 34), Color(0.95, 0.56, 0.66))
	draw_rect(Rect2(-34, -94 + bob, 68, 30), Color(1.0, 0.74, 0.8))

	for rect in [Rect2(-50, -38 + bob, 100, 10), Rect2(-44, -70 + bob, 88, 9), Rect2(-34, -98 + bob, 68, 9)]:
		draw_rect(rect, Color(1.0, 0.94, 0.86))
	for i in range(10):
		var x: = -46.0 + i * 10.0
		draw_circle(Vector2(x, -31 + bob), 5.0, Color(1.0, 0.94, 0.86))

	for i in range(5):
		var x: = -27.0 + i * 13.5
		draw_rect(Rect2(x - 2.2, -116 + bob, 4.4, 18), Color(0.95, 0.72, 0.82))
		draw_line(Vector2(x, -116 + bob), Vector2(x, -120 + bob), Color(0.2, 0.14, 0.15), 1.0)
		if lit:
			draw_colored_polygon(PackedVector2Array([
				Vector2(x, -135 + bob), Vector2(x + 4, -124 + bob), Vector2(x, -121 + bob), Vector2(x - 4, -124 + bob)
			]), Color(1.0, 0.8, 0.28))
			draw_circle(Vector2(x, -124 + bob), 3.0, Color(1.0, 0.98, 0.82))
			draw_circle(Vector2(x, -125 + bob), 9.0, Color(1.0, 0.68, 0.2, 0.08))

	draw_line(Vector2(-50, -50 + bob), Vector2(50, -50 + bob), Color(0.62, 0.4, 0.95, 0.9), 3.0)
	draw_line(Vector2(-44, -80 + bob), Vector2(44, -80 + bob), Color(0.62, 0.4, 0.95, 0.9), 3.0)
	draw_circle(Vector2(0, -98 + bob), 7.0, Color(1.0, 0.85, 0.55))

func draw_ellipse(center: Vector2, radii: Vector2, color: Color) -> void :
	var pts: = PackedVector2Array()
	for i in range(32):
		var a: = TAU * float(i) / 32.0
		pts.append(center + Vector2(cos(a) * radii.x, sin(a) * radii.y))
	draw_colored_polygon(pts, color)
