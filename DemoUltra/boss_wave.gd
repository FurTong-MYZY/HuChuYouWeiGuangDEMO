extends Area2D


var velocity: Vector2 = Vector2.ZERO
var life: float = 1.5
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
	rect.size = Vector2(150, 300)
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
	var dir: = 1.0 if velocity.x >= 0.0 else -1.0
	var hot: = Color(1.0, 0.16, 0.3, 0.92) if phase < 3 else Color(1.0, 0.04, 0.45, 0.96)
	var mid: = Color(1.0, 0.55, 0.38, 0.65) if phase < 3 else Color(1.0, 0.3, 0.7, 0.7)

	for i in range(3):
		var r: = 118.0 - i * 25.0
		var off: = dir * (24.0 + i * 9.0)
		var w: = 15.0 - i * 2.5
		var a: = 0.9 - i * 0.18
		draw_arc(Vector2(off, 0), r, -1.22, 1.22, 34, Color(hot.r, hot.g, hot.b, a * 0.22), w + 12.0)
		draw_arc(Vector2(off, 0), r, -1.18, 1.18, 34, Color(hot.r, hot.g, hot.b, a), w)
		draw_arc(Vector2(off - dir * 12.0, 0), r - 9.0, -1.05, 1.05, 30, Color(mid.r, mid.g, mid.b, a * 0.8), 2.5)

	for i in range(7):
		var y: = -84.0 + i * 28.0
		draw_line(Vector2( - dir * (48 + i * 8), y), Vector2( - dir * (118 + i * 12), y), Color(hot.r, hot.g, hot.b, 0.48), 2.0)
	draw_circle(Vector2.ZERO, 20.0, Color(1.0, 0.9, 0.7, 0.38))
	draw_circle(Vector2.ZERO, 8.0, Color(1.0, 0.96, 0.82, 0.75))
