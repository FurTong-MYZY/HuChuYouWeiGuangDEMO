extends Area2D


var velocity: Vector2 = Vector2.ZERO
var life: float = 3.5
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
	var circle: = CircleShape2D.new()
	circle.radius = 28.0
	cs.shape = circle
	add_child(cs)
	body_entered.connect(_on_body_entered)
	queue_redraw()

func _physics_process(delta: float) -> void :
	_t += delta
	life -= delta
	position += velocity * delta
	rotation += delta * 3.0
	if life <= 0:
		queue_free()

func _on_body_entered(body: Node2D) -> void :
	if body.is_in_group("player") and body.has_method("take_trap_damage"):
		body.take_trap_damage()
		queue_free()

func _draw() -> void :
	var hot: = Color(1.0, 0.24, 0.12, 0.95) if phase < 3 else Color(1.0, 0.08, 0.22, 0.98)
	var mid: = Color(1.0, 0.55, 0.18, 0.55) if phase < 3 else Color(1.0, 0.25, 0.45, 0.6)
	draw_circle(Vector2.ZERO, 44.0, Color(hot.r, hot.g, hot.b, 0.1))
	draw_circle(Vector2.ZERO, 30.0, Color(mid.r, mid.g, mid.b, 0.22))
	draw_circle(Vector2.ZERO, 20.0, Color(hot.r, hot.g, hot.b, 0.78))
	draw_circle(Vector2.ZERO, 9.0, Color(1.0, 0.92, 0.66, 0.95))

	for i in range(4):
		var a: = TAU * i / 4.0 + _t * 2.0
		var p: = Vector2(cos(a), sin(a))
		draw_line(p * 12.0, p * 32.0, Color(hot.r, hot.g, hot.b, 0.85), 3.0)
