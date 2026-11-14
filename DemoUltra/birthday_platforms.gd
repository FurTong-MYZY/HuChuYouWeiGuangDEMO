extends Node2D


const PLATFORMS: = [
	Rect2(0, 596, 1152, 52), 
	Rect2(260, 480, 150, 16), 
	Rect2(490, 390, 150, 16), 
	Rect2(300, 300, 150, 16), 
	Rect2(720, 480, 170, 16), 
	Rect2(790, 380, 170, 16), 
]

func _ready() -> void :
	z_index = -5
	for rect in PLATFORMS:
		var body: = StaticBody2D.new()
		body.collision_layer = 1
		body.collision_mask = 0
		var col: = CollisionShape2D.new()
		var shape: = RectangleShape2D.new()
		shape.size = rect.size
		col.shape = shape
		col.position = rect.position + rect.size * 0.5
		body.add_child(col)
		add_child(body)
	queue_redraw()

func _draw() -> void :
	for i in range(1, PLATFORMS.size()):
		var r: Rect2 = PLATFORMS[i]
		draw_rect(Rect2(r.position + Vector2(4, 7), r.size), Color(0, 0, 0, 0.25))
		draw_rect(r, Color(0.28, 0.18, 0.38))
		draw_rect(Rect2(r.position, Vector2(r.size.x, 5)), Color(0.58, 0.42, 0.72))
		draw_line(Vector2(r.position.x + r.size.x * 0.5, r.position.y), Vector2(r.position.x + r.size.x * 0.5, r.position.y + r.size.y), Color(1.0, 0.72, 0.55, 0.42), 2.0)
		draw_line(Vector2(r.position.x + 4, r.position.y + r.size.y * 0.5), Vector2(r.position.x + r.size.x - 4, r.position.y + r.size.y * 0.5), Color(1.0, 0.8, 0.6, 0.28), 1.0)
