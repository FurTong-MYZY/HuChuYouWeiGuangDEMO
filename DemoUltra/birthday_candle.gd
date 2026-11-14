extends Node2D


var lit: bool = false
@export var memory: String = ""
@export var index: int = 0
var _t: float = 0.0

func _ready() -> void :
	z_index = 6
	_t = randf() * TAU

func light_up() -> void :
	if lit:
		return
	lit = true
	queue_redraw()

func _process(delta: float) -> void :
	_t += delta
	queue_redraw()

func _draw() -> void :
	var bob: = sin(_t * 2.2) * 2.0
	var glow: = 0.5 + 0.5 * sin(_t * 3.0)
	if lit:
		draw_circle(Vector2(0, -31 + bob), 42.0, Color(1.0, 0.65, 0.28, 0.08))
		draw_circle(Vector2(0, -30 + bob), 24.0, Color(1.0, 0.72, 0.36, 0.12 + glow * 0.05))

	draw_rect(Rect2(-6, -25 + bob, 12, 25), Color(1.0, 0.78, 0.82))
	draw_rect(Rect2(-6, -25 + bob, 4, 25), Color(1.0, 0.9, 0.9, 0.55))
	draw_line(Vector2(0, -25 + bob), Vector2(0, -31 + bob), Color(0.25, 0.16, 0.15), 1.5)

	if lit:
		draw_colored_polygon(PackedVector2Array([
			Vector2(0, -45 + bob), Vector2(5, -34 + bob), Vector2(0, -31 + bob), Vector2(-5, -34 + bob)
		]), Color(1.0, 0.8, 0.25))
		draw_circle(Vector2(0, -35 + bob), 3.0, Color(1.0, 0.98, 0.8))
		draw_circle(Vector2(0, -35 + bob), 8.0 + glow * 3.0, Color(1.0, 0.65, 0.18, 0.1))
	else:
		draw_circle(Vector2(0, -28 + bob), 2.0, Color(0.55, 0.35, 0.4, 0.6))

	draw_circle(Vector2(0, -55 + bob), 1.8, Color(1.0, 0.85, 0.55, 0.8 if not lit else 0.35))
