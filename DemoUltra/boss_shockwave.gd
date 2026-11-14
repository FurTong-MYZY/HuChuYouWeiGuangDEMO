extends Area2D


var velocity: Vector2 = Vector2.ZERO
var life: float = 1.6
var phase: int = 1
var _t: float = 0.0

func setup(vel: Vector2, p: int = 1) -> void :
	velocity = vel
	phase = p

func _ready() -> void :
	collision_layer = 0
	collision_mask = 3
	monitoring = true
	z_index = 7
	var cs: = CollisionShape2D.new()
	var rect: = RectangleShape2D.new()
	rect.size = Vector2(100, 140)
	cs.shape = rect
	add_child(cs)
	body_entered.connect(_on_body_entered)
	queue_redraw()

func _physics_process(delta: float) -> void :
	_t += delta
	life -= delta
	position += velocity * delta
	if life <= 0:
		queue_free()

func _on_body_entered(body: Node2D) -> void :
	if body.is_in_group("player") and body.has_method("take_trap_damage"):
		body.take_trap_damage()
		queue_free()

func _draw() -> void :
	var hot: = Color(1.0, 0.28, 0.12, 0.9) if phase < 3 else Color(1.0, 0.08, 0.25, 0.95)
	var mid: = Color(1.0, 0.62, 0.2, 0.55) if phase < 3 else Color(1.0, 0.25, 0.5, 0.6)

	var pts: = PackedVector2Array()
	pts.append(Vector2(-42, 46))
	var n: = 9
	for i in range(n):
		var x: = -42.0 + 84.0 * float(i) / float(n - 1)
		var y: = -44.0 + (14.0 if i % 2 == 0 else 0.0) + sin(_t * 14.0 + i) * 5.0
		pts.append(Vector2(x, y))
	pts.append(Vector2(42, 46))
	draw_colored_polygon(pts, Color(hot.r, hot.g, hot.b, 0.34))
	draw_polyline(pts, Color(mid.r, mid.g, mid.b, 0.9), 3.0)
	for i in range(3):
		var x: = -28.0 + i * 28.0
		draw_circle(Vector2(x, 34), 5.0, Color(hot.r, hot.g, hot.b, 0.55))
