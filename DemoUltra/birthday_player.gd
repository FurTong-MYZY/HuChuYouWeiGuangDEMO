extends CharacterBody2D



const SPEED: = 285.0
const ACCEL: = 1900.0
const FRICTION: = 2200.0
const GRAVITY: = 1450.0
const JUMP_VELOCITY: = -680.0
const DOUBLE_JUMP_VELOCITY: = -580.0
const VISUAL_SCALE: = 0.1286

var locked: bool = false
var facing: int = 1
var coyote: float = 0.0
var double_available: bool = true
var anim_time: float = 0.0
var spawn_point: = Vector2.ZERO
var trail: CPUParticles2D
var visual_holder: Node2D
var lumine_root: Node2D
var body_frames: Array[Sprite2D] = []
var outfit_overlay: Node2D
var _walk_t: float = 0.0
var _walk_frame: int = 0

var hat_style: String = "party"
var outfit_style: String = "scarf"
var tint_style: String = "warm"

func _ready() -> void :
	collision_layer = 1
	collision_mask = 1
	floor_snap_length = 6.0
	var shape: = CapsuleShape2D.new()
	shape.radius = 10.0
	shape.height = 42.0
	var col: = CollisionShape2D.new()
	col.shape = shape
	col.position = Vector2(0, -21)
	add_child(col)
	_build_visual()
	trail = CPUParticles2D.new()
	trail.amount = 16
	trail.lifetime = 0.55
	trail.local_coords = false
	trail.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	trail.emission_sphere_radius = 10.0
	trail.direction = Vector2(0, -1)
	trail.spread = 65.0
	trail.gravity = Vector2(0, 12)
	trail.initial_velocity_min = 6.0
	trail.initial_velocity_max = 24.0
	trail.scale_amount_min = 0.04
	trail.scale_amount_max = 0.1
	var ramp: = Gradient.new()
	ramp.set_color(0, Color(1.0, 0.85, 0.55, 0.35))
	ramp.set_color(1, Color(1.0, 0.55, 0.65, 0.0))
	trail.color_ramp = ramp
	trail.position = Vector2(0, -24)
	add_child(trail)
	z_index = 8
	_apply_outfit()

func _build_visual() -> void :

	var source = load("res://scene.tscn").instantiate()
	var original = source.get_node("player")
	lumine_root = original.duplicate()
	lumine_root.position = Vector2.ZERO
	lumine_root.scale = Vector2(0.7, 0.7)
	lumine_root.set_script(null)
	source.free()

	lumine_root.collision_layer = 0
	lumine_root.collision_mask = 0
	for child in lumine_root.get_children():
		if child is CollisionShape2D:
			child.disabled = true
		elif child is Area2D:
			child.monitoring = false
			child.monitorable = false
			child.collision_layer = 0
			child.collision_mask = 0
		elif child is AudioStreamPlayer2D:
			child.stop()

	visual_holder = Node2D.new()
	visual_holder.name = "LumineVisual"
	visual_holder.position = Vector2(0, -60)
	visual_holder.scale = Vector2(VISUAL_SCALE, VISUAL_SCALE)
	add_child(visual_holder)
	visual_holder.add_child(lumine_root)


	var names: = ["Sprite2D", "Sprite2D2", "Sprite2D3", "Sprite2D4", "Sprite2D5", "Sprite2D6"]
	for n in names:
		var s: = lumine_root.get_node_or_null(n) as Sprite2D
		if s:
			body_frames.append(s)
			s.visible = (n == "Sprite2D")
	for n in ["LeftHappy", "leftSquint", "leftPain", "Sprite2D10", "Sprite2D7", "Sprite2D8"]:
		var e: = lumine_root.get_node_or_null(n) as Sprite2D
		if e:
			e.visible = false

	outfit_overlay = load("res://birthday_outfit.gd").new()
	outfit_overlay.player = self
	outfit_overlay.z_index = 12
	add_child(outfit_overlay)

func set_outfit(hat: String, outfit: String, tint: String) -> void :
	hat_style = hat
	outfit_style = outfit
	tint_style = tint
	_apply_outfit()

func _apply_outfit() -> void :
	if lumine_root:
		match tint_style:
			"sakura":
				lumine_root.modulate = Color(1.0, 0.84, 0.9)
			"night":
				lumine_root.modulate = Color(0.75, 0.84, 1.0)
			_:
				lumine_root.modulate = Color.WHITE
	if outfit_overlay and is_instance_valid(outfit_overlay):
		outfit_overlay.queue_redraw()

func _physics_process(delta: float) -> void :
	anim_time += delta
	if global_position.y > 780.0:
		global_position = spawn_point
		velocity = Vector2.ZERO
	velocity.y += GRAVITY * delta
	if locked:
		velocity.x = move_toward(velocity.x, 0.0, FRICTION * delta)
		_move_visual(delta, false)
		move_and_slide()
		return
	var dir: = Input.get_axis("move_left", "move_right")
	if absf(dir) > 0.05:
		facing = 1 if dir > 0.0 else -1
		velocity.x = move_toward(velocity.x, dir * SPEED, ACCEL * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, FRICTION * delta)
	if is_on_floor():
		coyote = 0.12
		double_available = true
	else:
		coyote = maxf(0.0, coyote - delta)
	if Input.is_action_just_pressed("jump"):
		if is_on_floor() or coyote > 0.0:
			velocity.y = JUMP_VELOCITY
			coyote = 0.0
			_burst(Color(1.0, 0.85, 0.5))
		elif double_available:
			double_available = false
			velocity.y = DOUBLE_JUMP_VELOCITY
			_burst(Color(1.0, 0.55, 0.8))
	_move_visual(delta, absf(velocity.x) > 30.0)
	move_and_slide()
	global_position.x = clampf(global_position.x, 18.0, 1134.0)
	trail.emitting = absf(velocity.x) > 30.0 or not is_on_floor()

func _move_visual(delta: float, moving: bool) -> void :
	if visual_holder == null:
		return
	visual_holder.scale.x = VISUAL_SCALE * facing
	visual_holder.position.y = -60.0 + sin(anim_time * 3.2) * 0.8
	if moving and is_on_floor():
		_walk_t += delta
		if _walk_t >= 0.1:
			_walk_t = 0.0
			_walk_frame = (_walk_frame + 1) % body_frames.size()
			for i in range(body_frames.size()):
				body_frames[i].visible = (i == _walk_frame)
	else:
		_walk_t = 0.0
		_walk_frame = 0
		for i in range(body_frames.size()):
			body_frames[i].visible = (i == 0)
	if outfit_overlay:
		outfit_overlay.queue_redraw()

func _burst(color: Color) -> void :
	var p: = CPUParticles2D.new()
	p.amount = 12
	p.one_shot = true
	p.emitting = true
	p.lifetime = 0.45
	p.direction = Vector2(0, 1)
	p.spread = 180.0
	p.gravity = Vector2(0, 220)
	p.initial_velocity_min = 40.0
	p.initial_velocity_max = 110.0
	p.scale_amount_min = 0.05
	p.scale_amount_max = 0.14
	var ramp: = Gradient.new()
	ramp.set_color(0, color)
	ramp.set_color(1, Color(color.r, color.g, color.b, 0.0))
	p.color_ramp = ramp
	get_parent().add_child(p)
	p.global_position = global_position + Vector2(0, -8)
	get_tree().create_timer(0.8).timeout.connect(p.queue_free)
