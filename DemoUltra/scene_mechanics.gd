extends Node2D



const S: = PixelArt.SCALE

func _ready() -> void :
	_make_ground()
	_make_neon_blocks()
	_make_soldier()
	_make_drone()
	_make_lasers()


func _static_platform(center: Vector2, size: Vector2, color: Color = Color(0.13, 0.15, 0.24)) -> void :
	var body: = StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	body.position = center
	var cs: = CollisionShape2D.new()
	var box: = RectangleShape2D.new()
	box.size = size
	cs.shape = box
	body.add_child(cs)
	var vis: = ColorRect.new()
	vis.size = size
	vis.position = - size / 2.0
	vis.color = color
	vis.z_index = -1
	body.add_child(vis)
	var edge: = ColorRect.new()
	edge.size = Vector2(size.x, 4 * S)
	edge.position = Vector2( - size.x / 2.0, - size.y / 2.0)
	edge.color = Color(0.3, 0.35, 0.5)
	edge.z_index = -1
	body.add_child(edge)
	add_child(body)

func _make_ground() -> void :

	_static_platform(Vector2(2600, -480), Vector2(3200, 80))

	_static_platform(Vector2(3300, -1000), Vector2(700, 40), Color(0.11, 0.13, 0.2))

	_static_platform(Vector2(3700, -1300), Vector2(300, 32), Color(0.1, 0.12, 0.18))


func _add_block(mode: int, pos: Vector2, hold_solid: bool = true, start_solid: bool = true) -> void :
	var b: NeonBlock = NeonBlock.new()
	b.mode = mode
	b.block_size = Vector2(56, 56)
	b.hold_solid = hold_solid
	b.start_solid = start_solid
	b.position = pos
	add_child(b)

func _make_neon_blocks() -> void :

	var y: = -744.0
	_add_block(NeonBlock.Mode.DASH, Vector2(1400, y))
	_add_block(NeonBlock.Mode.JUMP, Vector2(2000, y))
	_add_block(NeonBlock.Mode.INTERACT, Vector2(2600, y))

	_add_block(NeonBlock.Mode.LEFT, Vector2(3200, y), true, false)
	_add_block(NeonBlock.Mode.RIGHT, Vector2(3800, y), true, false)

	var y2: = -1244.0
	_add_block(NeonBlock.Mode.LEFT, Vector2(3100, y2), false, true)
	_add_block(NeonBlock.Mode.RIGHT, Vector2(3500, y2), false, true)


func _make_soldier() -> void :
	var s: Soldier = Soldier.new()

	s.position = Vector2(2300, -751)
	add_child(s)


func _make_drone() -> void :
	var d: Drone = Drone.new()
	d.position = Vector2(3700, -1400)
	add_child(d)


func _make_lasers() -> void :

	var straight: StrobeLaser = StrobeLaser.new()
	straight.position = Vector2(1300, -800)
	straight.shape_type = StrobeLaser.LaserShape.STRAIGHT
	straight.end_point = Vector2(200, 0)
	straight.idle_period = 2.0
	straight.active_period = 0.7
	add_child(straight)


	var curve: StrobeLaser = StrobeLaser.new()
	curve.position = Vector2(3600, -800)
	curve.shape_type = StrobeLaser.LaserShape.CURVE
	curve.curve_points = PackedVector2Array([
		Vector2(0, 0), 
		Vector2(60, 30), 
		Vector2(120, 0), 
		Vector2(180, 30), 
	])
	curve.idle_period = 2.4
	curve.active_period = 0.8
	add_child(curve)
