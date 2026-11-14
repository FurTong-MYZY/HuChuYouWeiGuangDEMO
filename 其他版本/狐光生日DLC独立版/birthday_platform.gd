@tool
extends StaticBody2D


@export var platform_size: Vector2 = Vector2(150, 16):
	set(value):
		platform_size = value
		queue_redraw()
@export var top_color: Color = Color(0.58, 0.42, 0.72)
@export var body_color: Color = Color(0.28, 0.18, 0.38)

func _ready() -> void :
	z_index = -5
	queue_redraw()
	if Engine.is_editor_hint():
		return
	collision_layer = 1
	collision_mask = 0
	var col: = CollisionShape2D.new()
	var shape: = RectangleShape2D.new()
	shape.size = platform_size
	col.shape = shape
	add_child(col)

func _draw() -> void :
	var half: = platform_size * 0.5
	var r: = Rect2( - half, platform_size)
	draw_rect(Rect2(r.position + Vector2(4, 7), r.size), Color(0, 0, 0, 0.25))
	draw_rect(r, body_color)
	draw_rect(Rect2(r.position, Vector2(r.size.x, 5)), top_color)
	draw_line(Vector2(r.position.x + r.size.x * 0.5, r.position.y), Vector2(r.position.x + r.size.x * 0.5, r.position.y + r.size.y), Color(1.0, 0.72, 0.55, 0.42), 2.0)
	draw_line(Vector2(r.position.x + 4, r.position.y + r.size.y * 0.5), Vector2(r.position.x + r.size.x - 4, r.position.y + r.size.y * 0.5), Color(1.0, 0.8, 0.6, 0.28), 1.0)
