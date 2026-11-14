extends CharacterBody2D
class_name Drone




enum State{PATROL, MALFUNCTION, FALLING, DEAD}

const S: = PixelArt.SCALE
const DroneExplosionScript: = preload("res://drone_explosion.gd")
static var _impact_ring_tex: Texture2D = null
const CYAN: = Color(0.22, 0.95, 1.0)
const RED: = Color(1.0, 0.28, 0.28)
const ORANGE: = Color(1.0, 0.55, 0.1)
const DARK: = Color(0.07, 0.08, 0.14)
const MID: = Color(0.13, 0.15, 0.24)
const LIGHT: = Color(0.25, 0.28, 0.42)

@export var track_speed: float = 1200.0
@export var detect_range_x: float = 520.0
@export var detect_range_y: float = 700.0
@export var drop_range_x: float = 368.0
@export var drop_cooldown: float = 1.9
@export var drop_windup: float = 0.65
@export var bob_amount: float = 48.0
@export var bomb_scene: PackedScene
@export var core_radius: float = 384.0
@export var outer_radius: float = 736.0

@export_group("Durability")
@export var max_hits: int = 3
@export var malfunction_duration: float = 1.6
@export var fall_gravity: float = 2400.0
@export var fall_stall_duration: float = 0.55
@export var explosion_damage: float = 20.0
@export var explosion_radius: float = 320.0

var state: State = State.PATROL
var player: CharacterBody2D = null
var alert: bool = false
var facing_right: bool = false
var hits_taken: int = 0

var _hover_y: float = 0.0
var _t: float = 0.0
var _cd: float = 0.0
var _hit_cd: float = 0.0
var _malfunction_t: float = 0.0
var _fall_spin: float = 0.0
var _fall_time: float = 0.0
var _tilt: float = 0.0
var _spark_timer: float = 0.0
var _dead: bool = false

var _visual: Node2D
var _sprite: Sprite2D
var _damage_sprite: Sprite2D
var _rotors: Array[Sprite2D] = []
var _rotor_glows: Array[Sprite2D] = []
var _eye: Sprite2D
var _eye_glow: Sprite2D
var _under_glow: Sprite2D
var _light_l: Sprite2D
var _light_r: Sprite2D
var _stage_lights: Array[Sprite2D] = []
var _bay: Sprite2D
var _hitbox: Area2D
var _ground_ray: RayCast2D
var _wall_ray: RayCast2D
var _smoke: CPUParticles2D
var _fire: CPUParticles2D

var _aim_root: Node2D
var _aim_beam: Line2D
var _aim_glow: Line2D
var _aim_dashes: Array[Sprite2D] = []
var _aim_target: Sprite2D
var _drop_charge: float = 0.0
var _laser_overlay: CanvasLayer
var _ov_haze: Line2D
var _ov_beam: Line2D
var _ov_core: Line2D
var _ov_charge: Sprite2D
var _ov_target: Sprite2D
var _ov_core_ring: Line2D
var _ov_outer_ring: Line2D

var _tex_body: Texture2D
var _tex_rotor: Texture2D
var _tex_eye: Texture2D
var _tex_light: Texture2D
var _tex_bay: Texture2D
var _tex_damage: Texture2D
var _tex_soft: Texture2D
var _tex_dash: Texture2D
var _tex_target: Texture2D

func _ready() -> void :
	collision_layer = 4
	collision_mask = 1 | 4
	_hover_y = global_position.y

	var cs: = CollisionShape2D.new()
	var box: = RectangleShape2D.new()
	box.size = Vector2(50, 34) * S
	cs.shape = box
	add_child(cs)

	_hitbox = Area2D.new()
	_hitbox.collision_layer = 0
	_hitbox.collision_mask = 3
	var hs: = CollisionShape2D.new()
	var hrect: = RectangleShape2D.new()
	hrect.size = Vector2(58, 42) * S
	hs.shape = hrect
	_hitbox.add_child(hs)
	add_child(_hitbox)
	_hitbox.body_entered.connect(_on_hitbox_body_entered)

	_ground_ray = RayCast2D.new()
	_ground_ray.target_position = Vector2(0, 24000)
	_ground_ray.collision_mask = 1
	_ground_ray.add_exception(self)
	add_child(_ground_ray)

	_wall_ray = RayCast2D.new()
	_wall_ray.target_position = Vector2(32 * S, 0)
	_wall_ray.collision_mask = 1
	_wall_ray.add_exception(self)
	add_child(_wall_ray)

	_build_visuals()
	_build_aim_fx()
	_build_particles()

	_tex_body = await PixelArt.bake_texture(_bake_body, Vector2i(64 * S, 48 * S), self)
	_tex_rotor = await PixelArt.bake_texture(_bake_rotor, Vector2i(30 * S, 6 * S), self)
	_tex_eye = await PixelArt.bake_texture(_bake_eye, Vector2i(16 * S, 16 * S), self)
	_tex_light = await PixelArt.bake_texture(_bake_light, Vector2i(8 * S, 8 * S), self)
	_tex_bay = await PixelArt.bake_texture(_bake_bay, Vector2i(18 * S, 10 * S), self)
	_tex_damage = await PixelArt.bake_texture(_bake_damage, Vector2i(64 * S, 48 * S), self)
	_apply_textures()

func _build_visuals() -> void :
	_visual = Node2D.new()
	add_child(_visual)

	_sprite = Sprite2D.new()
	_sprite.centered = true
	_visual.add_child(_sprite)

	_damage_sprite = Sprite2D.new()
	_damage_sprite.centered = true
	_damage_sprite.visible = false
	_damage_sprite.z_index = 1
	_visual.add_child(_damage_sprite)

	var rotor_positions: = [
		Vector2(-26, -13), Vector2(26, -13), 
		Vector2(-15, -26), Vector2(15, -26)
	]
	for i in range(rotor_positions.size()):
		var rotor: = Sprite2D.new()
		rotor.centered = true
		rotor.position = rotor_positions[i] * S
		_visual.add_child(rotor)
		_rotors.append(rotor)

		var glow: = Sprite2D.new()
		glow.centered = true
		glow.position = rotor_positions[i] * S
		glow.z_index = -1
		glow.material = _additive_material()
		_visual.add_child(glow)
		_rotor_glows.append(glow)

	_eye = Sprite2D.new()
	_eye.centered = true
	_eye.position = Vector2(0, 2 * S)
	_visual.add_child(_eye)

	_eye_glow = Sprite2D.new()
	_eye_glow.centered = true
	_eye_glow.position = Vector2(0, 2 * S)
	_eye_glow.z_index = 1
	_eye_glow.material = _additive_material()
	_eye_glow.scale = Vector2(2.4, 2.4)
	_visual.add_child(_eye_glow)

	_under_glow = Sprite2D.new()
	_under_glow.centered = true
	_under_glow.position = Vector2(0, 16 * S)
	_under_glow.z_index = 1
	_under_glow.material = _additive_material()
	_under_glow.scale = Vector2(3.2, 0.7)
	_visual.add_child(_under_glow)

	_light_l = Sprite2D.new()
	_light_l.centered = true
	_light_l.position = Vector2(-20 * S, 0)
	_light_l.visible = false
	_visual.add_child(_light_l)
	_light_r = Sprite2D.new()
	_light_r.centered = true
	_light_r.position = Vector2(20 * S, 0)
	_light_r.visible = false
	_visual.add_child(_light_r)

	for i in range(3):
		var stage: = Sprite2D.new()
		stage.centered = true
		stage.position = Vector2((-8 + i * 8) * S, -15 * S)
		stage.visible = false
		stage.z_index = 1
		_visual.add_child(stage)
		_stage_lights.append(stage)

	_bay = Sprite2D.new()
	_bay.centered = true
	_bay.position = Vector2(0, 12 * S)
	_bay.visible = false
	_visual.add_child(_bay)

func _build_aim_fx() -> void :
	_aim_root = Node2D.new()
	_aim_root.position = Vector2(0, 12 * S)
	add_child(_aim_root)

	_aim_glow = Line2D.new()
	_aim_glow.points = PackedVector2Array([Vector2.ZERO, Vector2(0, 100)])
	_aim_glow.width = 18.0
	_aim_glow.default_color = Color(1, 0.2, 0.1, 0.12)
	_aim_glow.material = _additive_material()
	_aim_glow.z_index = 7
	_aim_root.add_child(_aim_glow)

	_aim_beam = Line2D.new()
	_aim_beam.points = PackedVector2Array([Vector2.ZERO, Vector2(0, 100)])
	_aim_beam.width = 2.5
	_aim_beam.default_color = Color(1, 0.3, 0.2, 0.7)
	_aim_beam.material = _additive_material()
	_aim_beam.z_index = 8
	_aim_root.add_child(_aim_beam)

	var dash_tex: = _make_dash_texture()
	for i in range(8):
		var d: = Sprite2D.new()
		d.texture = dash_tex
		d.centered = true
		d.z_index = 8
		d.modulate = Color(1, 0.25, 0.15, 0.0)
		_aim_root.add_child(d)
		_aim_dashes.append(d)

	_aim_target = Sprite2D.new()
	_aim_target.texture = _make_target_texture()
	_aim_target.centered = true
	_aim_target.z_index = 9
	_aim_target.visible = false
	add_child(_aim_target)

	_laser_overlay = CanvasLayer.new()
	_laser_overlay.layer = 9
	var scene: = get_tree().current_scene
	if scene:
		scene.add_child.call_deferred(_laser_overlay)
	else:
		add_child.call_deferred(_laser_overlay)
	tree_exiting.connect( func() -> void :
		if _laser_overlay:
			_laser_overlay.queue_free()
	)
	_ov_haze = _make_overlay_line(16.0, Color(1.0, 0.04, 0.02, 0.42))
	_ov_beam = _make_overlay_line(5.0, Color(1.0, 0.24, 0.12, 0.95))
	_ov_core = _make_overlay_line(1.5, Color(1.0, 0.95, 0.82, 1.0))
	_ov_charge = Sprite2D.new()
	_ov_charge.texture = _make_ring_texture()
	_ov_charge.centered = true
	_ov_charge.material = _additive_material()
	_ov_charge.visible = false
	_laser_overlay.add_child(_ov_charge)
	_ov_target = Sprite2D.new()
	_ov_target.texture = _make_target_texture()
	_ov_target.centered = true
	_ov_target.visible = false
	_laser_overlay.add_child(_ov_target)
	_ov_core_ring = _make_overlay_line(5.0, Color(1.0, 0.16, 0.08, 0.9))
	_ov_outer_ring = _make_overlay_line(3.0, Color(1.0, 0.08, 0.04, 0.65))

func _build_particles() -> void :
	_tex_soft = _make_soft_texture(32)

	_smoke = CPUParticles2D.new()
	_smoke.amount = 18
	_smoke.lifetime = 1.2
	_smoke.one_shot = false
	_smoke.emitting = false
	_smoke.local_coords = false
	_smoke.direction = Vector2.UP
	_smoke.spread = 35.0
	_smoke.initial_velocity_min = 20.0
	_smoke.initial_velocity_max = 80.0
	_smoke.gravity = Vector2(0, -12)
	_smoke.scale_amount_min = 0.35
	_smoke.scale_amount_max = 0.9
	_smoke.texture = _tex_soft
	var smoke_ramp: = Gradient.new()
	smoke_ramp.set_color(0, Color(0.22, 0.22, 0.28, 0.55))
	smoke_ramp.set_color(1, Color(0.06, 0.06, 0.09, 0.0))
	_smoke.color_ramp = smoke_ramp
	_smoke.z_index = 2
	add_child(_smoke)

	_fire = CPUParticles2D.new()
	_fire.amount = 14
	_fire.lifetime = 0.45
	_fire.one_shot = false
	_fire.emitting = false
	_fire.local_coords = false
	_fire.direction = Vector2.UP
	_fire.spread = 50.0
	_fire.initial_velocity_min = 40.0
	_fire.initial_velocity_max = 120.0
	_fire.gravity = Vector2(0, -80)
	_fire.scale_amount_min = 0.25
	_fire.scale_amount_max = 0.7
	_fire.texture = _tex_soft
	var fire_ramp: = Gradient.new()
	fire_ramp.set_color(0, Color(1.0, 0.75, 0.25, 0.95))
	fire_ramp.set_color(1, Color(1.0, 0.18, 0.04, 0.0))
	_fire.color_ramp = fire_ramp
	_fire.z_index = 3
	add_child(_fire)

func _apply_textures() -> void :
	_sprite.texture = _tex_body
	_damage_sprite.texture = _tex_damage
	for r in _rotors:
		r.texture = _tex_rotor
	for g in _rotor_glows:
		g.texture = _tex_soft
		g.modulate = Color(CYAN.r, CYAN.g, CYAN.b, 0.3)
		g.scale = Vector2(2.6, 0.9)
		g.z_index = 1
	_eye_glow.texture = _tex_soft
	_eye_glow.modulate = Color(CYAN.r, CYAN.g, CYAN.b, 0.28)
	_under_glow.texture = _tex_soft
	_under_glow.modulate = Color(CYAN.r, CYAN.g, CYAN.b, 0.18)
	_eye.texture = _tex_eye
	_light_l.texture = _tex_light
	_light_r.texture = _tex_light
	for stage in _stage_lights:
		stage.texture = _tex_light
	_bay.texture = _tex_bay
	if _tex_body == null:
		queue_redraw()


func _bake_body(ci: CanvasItem) -> void :
	var s: = S
	ci.draw_set_transform(Vector2(32 * s, 24 * s), 0.0, Vector2(s, s))


	ci.draw_circle(Vector2(0, -2), 30.0, Color(CYAN.r, CYAN.g, CYAN.b, 0.025))
	ci.draw_circle(Vector2(0, -2), 22.0, Color(CYAN.r, CYAN.g, CYAN.b, 0.035))


	ci.draw_line(Vector2(-12, -9), Vector2(-26, -13), MID, 4.0)
	ci.draw_line(Vector2(12, -9), Vector2(26, -13), MID, 4.0)
	ci.draw_line(Vector2(-8, -12), Vector2(-15, -26), DARK, 3.0)
	ci.draw_line(Vector2(8, -12), Vector2(15, -26), DARK, 3.0)
	ci.draw_circle(Vector2(-26, -13), 3.2, LIGHT)
	ci.draw_circle(Vector2(26, -13), 3.2, LIGHT)
	ci.draw_circle(Vector2(-15, -26), 2.8, LIGHT)
	ci.draw_circle(Vector2(15, -26), 2.8, LIGHT)


	ci.draw_rect(Rect2(-24, -6, 8, 13), DARK)
	ci.draw_rect(Rect2(16, -6, 8, 13), DARK)
	ci.draw_rect(Rect2(-23, -5, 6, 7), MID)
	ci.draw_rect(Rect2(17, -5, 6, 7), MID)
	ci.draw_rect(Rect2(-18, -11, 36, 22), DARK)
	ci.draw_rect(Rect2(-16, -10, 32, 18), MID)
	ci.draw_rect(Rect2(-16, -10, 32, 3), LIGHT)
	ci.draw_rect(Rect2(-14, -6, 28, 10), Color(0.1, 0.13, 0.21))
	ci.draw_rect(Rect2(-14, -6, 28, 1), Color(0.36, 0.42, 0.58))
	ci.draw_rect(Rect2(-18, -11, 36, 22), Color(CYAN.r, CYAN.g, CYAN.b, 0.16), false, 1.0)


	ci.draw_rect(Rect2(-2, -10, 4, 18), Color(0.045, 0.055, 0.09))
	ci.draw_rect(Rect2(-16, 2, 32, 2), Color(0.05, 0.06, 0.1))
	ci.draw_line(Vector2(-13, -7), Vector2(13, -7), Color(0.28, 0.32, 0.46), 1.0)


	ci.draw_circle(Vector2(0, 2), 7.5, Color(0.025, 0.04, 0.065))
	ci.draw_circle(Vector2(0, 2), 6.0, Color(0.06, 0.08, 0.13))
	ci.draw_circle(Vector2(0, 2), 4.6, Color(0.12, 0.15, 0.22))


	ci.draw_rect(Rect2(-8, 10, 16, 6), DARK)
	ci.draw_rect(Rect2(-6, 11, 12, 3), Color(0.06, 0.06, 0.09))
	ci.draw_rect(Rect2(-6, 11, 12, 1), Color(1.0, 0.45, 0.1, 0.35))


	ci.draw_rect(Rect2(13, -20, 2, 10), LIGHT)
	ci.draw_circle(Vector2(14, -21), 2.2, RED)
	ci.draw_rect(Rect2(-16, -15, 2, 6), LIGHT)


	ci.draw_rect(Rect2(-15, -4, 2, 5), Color(CYAN.r, CYAN.g, CYAN.b, 0.7))
	ci.draw_rect(Rect2(13, -4, 2, 5), Color(CYAN.r, CYAN.g, CYAN.b, 0.7))
	ci.draw_rect(Rect2(-8, -9, 4, 1), Color(CYAN.r, CYAN.g, CYAN.b, 0.5))
	ci.draw_rect(Rect2(4, -9, 4, 1), Color(CYAN.r, CYAN.g, CYAN.b, 0.5))
	ci.draw_rect(Rect2(-24, 4, 4, 2), Color(1.0, 0.45, 0.1, 0.7))
	ci.draw_rect(Rect2(20, 4, 4, 2), Color(1.0, 0.45, 0.1, 0.7))


	ci.draw_rect(Rect2(-8, 15, 16, 2), Color(CYAN.r, CYAN.g, CYAN.b, 0.28))
	ci.draw_circle(Vector2(0, 16), 2.0, Color(1, 1, 1, 0.35))

func _bake_rotor(ci: CanvasItem) -> void :
	var s: = S
	ci.draw_set_transform(Vector2(15 * s, 3 * s), 0.0, Vector2(s, s))
	ci.draw_rect(Rect2(-14, -2.5, 28, 5), Color(0.35, 0.4, 0.55, 0.55))
	ci.draw_rect(Rect2(-14, -1, 28, 2), Color(0.55, 0.62, 0.78, 0.9))
	ci.draw_rect(Rect2(-14, -2.5, 8, 1), Color(0.8, 0.9, 1.0, 0.7))
	ci.draw_circle(Vector2.ZERO, 3.0, DARK)
	ci.draw_circle(Vector2.ZERO, 1.5, LIGHT)

func _bake_eye(ci: CanvasItem) -> void :
	var s: = S
	ci.draw_set_transform(Vector2(8 * s, 8 * s), 0.0, Vector2(s, s))
	ci.draw_circle(Vector2.ZERO, 7.0, Color(0.02, 0.03, 0.05))
	ci.draw_circle(Vector2.ZERO, 5.0, Color(0.06, 0.09, 0.14))
	ci.draw_circle(Vector2.ZERO, 3.6, Color(CYAN.r, CYAN.g, CYAN.b, 0.9))
	ci.draw_circle(Vector2.ZERO, 1.8, Color(1, 1, 1, 0.95))
	ci.draw_circle(Vector2(-1, -1), 0.8, Color(1, 1, 1, 1))

func _bake_light(ci: CanvasItem) -> void :
	var s: = S
	ci.draw_set_transform(Vector2(4 * s, 4 * s), 0.0, Vector2(s, s))
	ci.draw_circle(Vector2.ZERO, 3.0, Color(0.15, 0.02, 0.02))
	ci.draw_circle(Vector2.ZERO, 2.0, Color(1.0, 0.25, 0.2, 0.95))
	ci.draw_circle(Vector2.ZERO, 0.8, Color(1, 0.85, 0.7, 1))

func _bake_bay(ci: CanvasItem) -> void :
	var s: = S
	ci.draw_set_transform(Vector2(9 * s, 5 * s), 0.0, Vector2(s, s))
	ci.draw_rect(Rect2(-8, -4, 16, 8), Color(0.04, 0.05, 0.08))
	ci.draw_rect(Rect2(-7, -3, 14, 6), Color(1.0, 0.45, 0.1, 0.16))
	ci.draw_rect(Rect2(-7, -3, 14, 1), Color(1.0, 0.55, 0.15, 0.8))
	ci.draw_rect(Rect2(-1, -3, 2, 6), Color(1.0, 0.75, 0.3, 0.9))

func _bake_damage(ci: CanvasItem) -> void :
	var s: = S
	ci.draw_set_transform(Vector2(32 * s, 24 * s), 0.0, Vector2(s, s))

	ci.draw_circle(Vector2(-12, -7), 6.0, Color(0.02, 0.02, 0.03, 0.55))
	ci.draw_circle(Vector2(9, 6), 4.5, Color(0.02, 0.02, 0.03, 0.4))
	ci.draw_line(Vector2(-16, -9), Vector2(-9, -3), Color(0.01, 0.01, 0.02, 0.8), 1.2)
	ci.draw_line(Vector2(-9, -3), Vector2(-12, 2), Color(0.01, 0.01, 0.02, 0.8), 1.0)
	ci.draw_line(Vector2(-9, -3), Vector2(-4, 0), Color(0.01, 0.01, 0.02, 0.75), 1.0)
	ci.draw_line(Vector2(8, 1), Vector2(13, 4), Color(0.01, 0.01, 0.02, 0.7), 1.0)
	ci.draw_line(Vector2(8, 1), Vector2(11, -3), Color(0.01, 0.01, 0.02, 0.7), 1.0)
	ci.draw_circle(Vector2(-8, 8), 1.0, Color(1.0, 0.55, 0.15, 0.55))


func _physics_process(delta: float) -> void :
	_t += delta
	_cd = maxf(0.0, _cd - delta)
	_hit_cd = maxf(0.0, _hit_cd - delta)

	if not player or not is_instance_valid(player):
		player = _find_player()
		if player:
			_ground_ray.add_exception(player)
			_wall_ray.add_exception(player)

	if state == State.FALLING:
		_process_falling(delta)
		return
	if state == State.DEAD:
		return

	if state == State.MALFUNCTION:
		_process_malfunction(delta)
		return

	alert = _compute_alert()
	var vx: = 0.0
	if alert and player:
		var dx: = player.global_position.x - global_position.x
		facing_right = dx > 0
		if absf(dx) > drop_range_x * 0.45:
			vx = signf(dx) * minf(track_speed, absf(dx) * 2.2)
		if absf(dx) <= drop_range_x and _cd <= 0.0:
			if _drop_charge <= 0.0:
				_drop_charge = maxf(0.05, drop_windup)
			_drop_charge -= delta
			if _drop_charge <= 0.0:
				_drop_charge = 0.0
				_drop_bomb()
				_cd = drop_cooldown
		else:
			_drop_charge = 0.0
		if vx != 0.0:
			_wall_ray.target_position = Vector2(signf(vx) * 34.0 * S, 0)
			_wall_ray.force_raycast_update()
			if _wall_ray.is_colliding():
				vx = 0.0

	var target_y: = _hover_y + sin(_t * 2.0) * bob_amount
	var vy: = (target_y - global_position.y) * 3.0
	velocity = Vector2(vx, vy)
	move_and_slide()

	_update_tilt(vx, delta)
	_update_aim()
	_update_visuals(delta)

	if state == State.PATROL and _hit_cd <= 0.0:
		for b in _hitbox.get_overlapping_bodies():
			if b.is_in_group("player") and b.is_dashing:
				_try_dash_hit(b)
				break

func _process_malfunction(delta: float) -> void :
	_malfunction_t -= delta
	velocity.x = move_toward(velocity.x, 0.0, 1000.0 * delta)
	var target_y: = _hover_y + 26.0 + sin(_t * 17.0) * 18.0
	velocity.y = (target_y - global_position.y) * 4.0
	move_and_slide()
	_visual.rotation = sin(_t * 22.0) * 0.12
	_update_visuals(delta)
	_update_aim()
	_spawn_damage_fx(delta)
	if _hit_cd <= 0.0:
		for b in _hitbox.get_overlapping_bodies():
			if b.is_in_group("player") and b.is_dashing:
				_try_dash_hit(b)
				break
	if state != State.MALFUNCTION:
		return
	if _malfunction_t <= 0.0:
		state = State.PATROL
		collision_mask = 1 | 4
		_smoke.emitting = false
		_visual.rotation = 0.0
		_hit_cd = 0.35

func _process_falling(delta: float) -> void :
	_fall_time += delta


	if _fall_time < fall_stall_duration:
		velocity.x = move_toward(velocity.x, 0.0, 80.0 * delta)
		velocity.y = 45.0
		global_position += velocity * delta
		_visual.rotation = sin(_fall_time * 21.0) * 0.18
		_update_visuals(delta)
		_spawn_damage_fx(delta)
		return


	velocity.y += fall_gravity * delta
	velocity.x = move_toward(velocity.x, 0.0, 180.0 * delta)
	global_position += velocity * delta
	_visual.rotation += _fall_spin * delta
	_update_visuals(delta)
	_spawn_damage_fx(delta)
	if _fall_time < fall_stall_duration + 0.16:
		return
	_ground_ray.force_raycast_update()
	if _ground_ray.is_colliding():
		_explode_at(_ground_ray.get_collision_point())
		return
	if global_position.y > _hover_y + 9000.0:
		_explode_at(global_position)

func _compute_alert() -> bool:
	if not player or not is_instance_valid(player):
		return false
	var dx: = absf(player.global_position.x - global_position.x)
	var dy: = player.global_position.y - global_position.y
	if dx > detect_range_x * S:
		return false
	if dy < -40.0 * S or dy > detect_range_y * S:
		return false
	return _has_los_to_player()

func _has_los_to_player() -> bool:
	if not player:
		return false
	var q: = PhysicsRayQueryParameters2D.create(global_position, player.global_position, 1)
	q.exclude = [self]
	var hit: = get_world_2d().direct_space_state.intersect_ray(q)
	if hit.is_empty():
		return true
	return hit.get("collider") == player


func _make_overlay_line(line_width: float, color: Color) -> Line2D:
	var line: = Line2D.new()
	line.width = line_width
	line.default_color = color
	line.material = _additive_material()
	line.visible = false
	_laser_overlay.add_child(line)
	return line

func _hide_laser_overlay() -> void :
	for n in [_ov_haze, _ov_beam, _ov_core, _ov_charge, _ov_target, _ov_core_ring, _ov_outer_ring]:
		n.visible = false

func _update_aim() -> void :
	var show: = alert and state == State.PATROL and player != null
	if not show:
		_aim_beam.visible = false
		_aim_glow.visible = false
		_aim_target.visible = false
		for d in _aim_dashes:
			d.visible = false
		_hide_laser_overlay()
		return

	_ground_ray.force_raycast_update()
	var start_y: = global_position.y + 12 * S
	var length: = 1200.0
	var has_ground: = false
	var hit_pos: = Vector2.ZERO
	if _ground_ray.is_colliding():
		hit_pos = _ground_ray.get_collision_point()
		length = clampf(hit_pos.y - start_y, 80.0, 2200.0)
		has_ground = true

	_aim_glow.visible = true
	_aim_beam.visible = true
	_aim_glow.points = PackedVector2Array([Vector2.ZERO, Vector2(0, length)])
	_aim_beam.points = PackedVector2Array([Vector2.ZERO, Vector2(0, length)])

	var ready: = _cd <= 0.0
	var pulse: = 0.5 + 0.5 * sin(_t * 14.0)
	var a: = (0.45 if ready else 0.22) + pulse * 0.25
	_aim_beam.modulate = Color(1.0, 0.28, 0.18, a)
	_aim_glow.modulate = Color(1.0, 0.2, 0.1, 0.08 + a * 0.15)

	var spacing: = maxf(42.0, length / 9.0)
	for i in range(_aim_dashes.size()):
		var d: = _aim_dashes[i]
		d.visible = true
		var yy: = fmod(_t * 280.0 + i * spacing, length)
		d.position = Vector2(0, yy)
		d.modulate = Color(1.0, 0.32, 0.2, 0.35 + 0.35 * pulse)

	if has_ground:
		_aim_target.visible = true
		_aim_target.global_position = hit_pos + Vector2(0, -18.0)
		_aim_target.rotation = _t * 1.8
		var ts: = 0.8 + 0.12 * pulse
		_aim_target.scale = Vector2(ts, ts)
		_aim_target.modulate = Color(1.0, 0.35, 0.22, 0.55 + 0.3 * pulse)
	else:
		_aim_target.visible = false

	var charging: = _drop_charge > 0.0
	var xf: = get_viewport().get_canvas_transform()
	var start_world: = global_position + Vector2(0, 12 * S)
	var target_world: = hit_pos if has_ground else start_world + Vector2(0, length)
	var s0: = xf * start_world
	var s1: = xf * target_world
	var spts: = PackedVector2Array([s0, s1])
	_ov_haze.visible = true
	_ov_beam.visible = true
	_ov_core.visible = true
	_ov_haze.points = spts
	_ov_beam.points = spts
	_ov_core.points = spts
	_ov_haze.modulate = Color(1.0, 0.05, 0.02, 0.32 + 0.15 * (1.0 if charging else 0.0))
	_ov_beam.modulate = Color(1.0, 0.25, 0.12, 0.92)
	_ov_core.modulate = Color(1.0, 0.94, 0.82, 1.0)
	_ov_target.visible = has_ground
	_ov_target.position = s1
	_ov_target.rotation = _t * 1.8
	_ov_target.scale = Vector2(0.75 + 0.1 * pulse + 0.2 * (1.0 if charging else 0.0), 0.75 + 0.1 * pulse)
	_ov_target.modulate = Color(1.0, 0.3, 0.16, 0.7 + 0.25 * pulse)
	_ov_charge.visible = charging
	_ov_core_ring.visible = charging
	_ov_outer_ring.visible = charging
	if charging:
		var grow: = 0.8 + 0.2 * pulse
		_ov_charge.position = s0
		_ov_charge.scale = Vector2(grow, grow)
		_ov_charge.rotation = _t * 3.2
		_ov_charge.modulate = Color(1.0, 0.22, 0.1, 0.8)
		var ss: = xf.get_scale().x
		_ov_core_ring.points = _make_screen_circle(core_radius * ss, 64)
		_ov_outer_ring.points = _make_screen_circle(outer_radius * ss, 80)
		_ov_core_ring.position = s1
		_ov_outer_ring.position = s1
		_ov_core_ring.modulate = Color(1.0, 0.16, 0.08, 0.9)
		_ov_outer_ring.modulate = Color(1.0, 0.08, 0.04, 0.7)

func _make_screen_circle(radius: float, segments: int) -> PackedVector2Array:
	var pts: = PackedVector2Array()
	for i in range(segments + 1):
		var ang: = TAU * float(i) / float(segments)
		pts.append(Vector2(cos(ang), sin(ang)) * radius)
	return pts


func _update_visuals(delta: float) -> void :
	var rotor_speed: = 32.0
	if state == State.MALFUNCTION:
		rotor_speed = 16.0 + sin(_t * 30.0) * 10.0
	elif state == State.FALLING:
		rotor_speed = 8.0
	for i in range(_rotors.size()):
		_rotors[i].rotation += delta * rotor_speed * (1.0 if i % 2 == 0 else -1.0)
		_rotor_glows[i].rotation = _t * 1.3
		_rotor_glows[i].modulate.a = 0.1 + 0.07 * sin(_t * 9.0 + i)

	var alert_col: = RED if alert else CYAN
	if state == State.MALFUNCTION:
		alert_col = ORANGE if int(_t * 12.0) % 2 == 0 else Color(0.2, 0.2, 0.25)
	elif state == State.FALLING:
		alert_col = RED
	_eye.modulate = Color(alert_col.r, alert_col.g, alert_col.b, 1.0)
	_eye.scale = Vector2.ONE * (1.0 + 0.04 * sin(_t * 14.0))
	_eye_glow.modulate = Color(alert_col.r, alert_col.g, alert_col.b, 0.2 + 0.1 * sin(_t * 10.0))
	_under_glow.modulate = Color(alert_col.r, alert_col.g, alert_col.b, 0.12 + 0.05 * sin(_t * 8.0))

	var blink: = int(_t * 4.0) % 2 == 0
	var lights_on: = (alert or state == State.MALFUNCTION or state == State.FALLING) and blink
	_light_l.visible = lights_on
	_light_r.visible = lights_on
	_light_l.modulate = Color(1, 1, 1, 0.8)
	_light_r.modulate = Color(1, 1, 1, 0.8)
	_bay.visible = state == State.PATROL and alert and _drop_charge > 0.0
	if _bay.visible:
		_bay.modulate = Color(1, 1, 1, 0.55 + 0.35 * sin(_t * 16.0))

	_damage_sprite.visible = hits_taken > 0
	_damage_sprite.modulate = Color(1, 1, 1, 0.45 + minf(hits_taken, 2) * 0.2)

	for i in range(_stage_lights.size()):
		var on: = i < hits_taken
		_stage_lights[i].visible = on
		if on:
			var blink_stage: = 0.7 + 0.3 * sin(_t * 10.0 + i * 1.2)
			_stage_lights[i].modulate = Color(1.0, 0.25, 0.12, blink_stage)

	if state == State.MALFUNCTION:
		_visual.position = Vector2(sin(_t * 31.0) * 2.0 * S, sin(_t * 19.0) * 2.0 * S)
	elif state == State.FALLING:
		_visual.position = Vector2.ZERO
	else:
		_visual.position = Vector2(0, sin(_t * 2.4) * 1.2 * S)
		_visual.rotation = _tilt + sin(_t * 1.3) * 0.008

func _update_tilt(vx: float, delta: float) -> void :
	var target_tilt: = clampf(vx * 0.00022, -0.2, 0.2)
	if alert and player:
		target_tilt = clampf((player.global_position.x - global_position.x) * 4e-05, -0.12, 0.12)
	_tilt = lerp(_tilt, target_tilt, clampf(delta * 5.0, 0.0, 1.0))

func _spawn_damage_fx(delta: float) -> void :
	_spark_timer -= delta
	if _spark_timer <= 0.0:
		_spark_timer = 0.16
		var spark: = Spark.new()
		get_tree().current_scene.add_child(spark)
		spark.global_position = global_position + Vector2(randf_range(-18, 18) * S, randf_range(-8, 8) * S)
		spark.setup(Color(1.0, 0.65, 0.25), 6, 70.0 * S)

func _impact_feedback(body: Node2D) -> void :
	_spawn_impact_ring()
	_screen_flash(Color(1, 1, 1, 0.42), 0.16)
	_shake_camera(8.0, 0.2)
	_hitstop()

	var spark: = Spark.new()
	get_tree().current_scene.add_child(spark)
	spark.global_position = global_position + Vector2(0, 2 * S)
	spark.setup(Color(0.75, 0.95, 1.0), 14, 140.0 * S)

	if _sprite:
		_sprite.modulate = Color(2.2, 2.2, 2.2, 1.0)
		var tw: = create_tween()
		tw.tween_property(_sprite, "modulate", Color.WHITE, 0.14)

func _hitstop() -> void :
	if Engine.time_scale < 0.99:
		return
	var previous: = Engine.time_scale
	Engine.time_scale = 0.12
	var timer: = get_tree().create_timer(0.045, true, false, true)
	timer.timeout.connect( func() -> void :
		Engine.time_scale = previous
	)

func _screen_flash(color: Color, duration: float) -> void :
	var scene: = get_tree().current_scene
	if scene == null:
		return
	var layer: = CanvasLayer.new()
	layer.layer = 100
	var rect: = ColorRect.new()
	rect.color = color
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.position = Vector2.ZERO
	rect.size = get_viewport().get_visible_rect().size
	layer.add_child(rect)
	scene.add_child(layer)
	var tw: = create_tween()
	tw.tween_property(rect, "modulate:a", 0.0, duration)
	tw.tween_callback(layer.queue_free)

func _shake_camera(amplitude: float, duration: float) -> void :
	var cam: = get_viewport().get_camera_2d()
	if cam == null:
		return
	var base: = cam.offset
	var tw: = cam.create_tween()
	for i in range(5):
		var t: = float(i) / 5.0
		var a: = amplitude * (1.0 - t)
		tw.tween_property(cam, "offset", base + Vector2(randf_range( - a, a), randf_range( - a * 0.7, a * 0.7)), 0.025)
	tw.tween_property(cam, "offset", base, 0.05)

func _spawn_impact_ring() -> void :
	var scene: = get_tree().current_scene
	if scene == null:
		return
	var ring: = Sprite2D.new()
	ring.texture = _make_ring_texture()
	ring.centered = true
	ring.material = _additive_material()
	ring.modulate = Color(0.7, 0.95, 1.0, 0.9)
	ring.scale = Vector2(0.22, 0.22)
	ring.z_index = 9
	scene.add_child(ring)
	ring.global_position = global_position
	var tw: = create_tween()
	tw.set_parallel(true)
	tw.tween_property(ring, "scale", Vector2(2.4, 2.4), 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(ring, "modulate:a", 0.0, 0.22)
	tw.chain().tween_callback(ring.queue_free)

static func _make_ring_texture() -> Texture2D:
	if _impact_ring_tex:
		return _impact_ring_tex
	var size: = 128
	var img: = Image.create(size, size, false, Image.FORMAT_RGBA8)
	var c: = size * 0.5
	for y in range(size):
		for x in range(size):
			var d: = Vector2(x + 0.5 - c, y + 0.5 - c).length() / c
			var a: = 0.0
			if d > 0.72 and d < 1.0:
				a = smoothstep(0.72, 0.82, d) * (1.0 - smoothstep(0.9, 1.0, d))
			img.set_pixel(x, y, Color(1, 1, 1, a))
	_impact_ring_tex = ImageTexture.create_from_image(img)
	return _impact_ring_tex

func _update_stage_lights() -> void :
	for i in range(_stage_lights.size()):
		_stage_lights[i].visible = i < hits_taken


func _try_dash_hit(body: Node2D) -> void :
	if state == State.FALLING or state == State.DEAD or _hit_cd > 0.0:
		return
	if body == null or not body.is_in_group("player") or not body.is_dashing:
		return
	_hit_cd = 0.65
	hits_taken += 1
	_update_stage_lights()
	_impact_feedback(body)
	if hits_taken >= max_hits:
		_start_falling(body)
	else:
		_start_malfunction(body)

func _on_hitbox_body_entered(body: Node2D) -> void :
	_try_dash_hit(body)

func _start_malfunction(from_player: Node2D) -> void :
	state = State.MALFUNCTION

	collision_mask = 1
	_malfunction_t = malfunction_duration
	_smoke.emitting = true
	_fire.emitting = false
	alert = false
	_drop_charge = 0.0
	_hide_laser_overlay()
	_aim_beam.visible = false
	_aim_glow.visible = false
	_aim_target.visible = false
	for d in _aim_dashes:
		d.visible = false
	if from_player:
		velocity = Vector2(signf(global_position.x - from_player.global_position.x) * 220.0, -150.0)
	_visual.rotation = 0.0

func _start_falling(from_player: Node2D) -> void :
	state = State.FALLING

	collision_mask = 0
	_fall_time = 0.0
	_hitbox.set_deferred("monitoring", false)
	_smoke.emitting = true
	_fire.emitting = true
	alert = false
	_drop_charge = 0.0
	_hide_laser_overlay()
	_aim_beam.visible = false
	_aim_glow.visible = false
	_aim_target.visible = false
	for d in _aim_dashes:
		d.visible = false
	var dir: = 1.0
	if from_player:
		dir = signf(global_position.x - from_player.global_position.x)
		if dir == 0.0:
			dir = 1.0
	velocity = Vector2(dir * 45.0, 30.0)
	_fall_spin = randf_range(-4.5, 4.5)

func _explode_at(pos: Vector2) -> void :
	if _dead:
		return
	_dead = true
	state = State.DEAD
	var e = DroneExplosionScript.new()
	e.damage = explosion_damage
	e.radius = explosion_radius
	get_tree().current_scene.add_child(e)
	e.global_position = pos
	queue_free()


func _drop_bomb() -> void :
	var bomb: Bomb
	if bomb_scene:
		bomb = bomb_scene.instantiate()
	else:
		bomb = Bomb.new()
	bomb.core_radius = core_radius
	bomb.outer_radius = outer_radius
	get_tree().current_scene.add_child(bomb)
	bomb.global_position = global_position + Vector2(0, 18 * S)
	if _bay:
		_bay.modulate = Color(1, 1, 1, 1)
		var tw: = create_tween()
		tw.tween_property(_bay, "modulate", Color(1, 1, 1, 0.5), 0.25)


func _find_player() -> CharacterBody2D:
	var nodes: = get_tree().get_nodes_in_group("player")
	return nodes[0] if nodes.size() > 0 else null

static func _additive_material() -> CanvasItemMaterial:
	var m: = CanvasItemMaterial.new()
	m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	return m

func _make_soft_texture(size: int) -> Texture2D:
	var img: = Image.create(size, size, false, Image.FORMAT_RGBA8)
	var c: = size * 0.5
	for y in range(size):
		for x in range(size):
			var d: = Vector2(x + 0.5 - c, y + 0.5 - c).length() / c
			var a: = pow(maxf(0.0, 1.0 - d), 2.0)
			img.set_pixel(x, y, Color(1, 1, 1, a))
	return ImageTexture.create_from_image(img)

func _make_dash_texture() -> Texture2D:
	var img: = Image.create(8, 24, false, Image.FORMAT_RGBA8)
	for y in range(24):
		var a: = 1.0 - absf(y - 12.0) / 12.0
		a = pow(maxf(0.0, a), 1.4)
		for x in range(8):
			var hx: = 1.0 - absf(x - 3.5) / 3.5
			img.set_pixel(x, y, Color(1, 1, 1, a * pow(maxf(0.0, hx), 1.5)))
	return ImageTexture.create_from_image(img)

func _make_target_texture() -> Texture2D:
	var size: = 128
	var img: = Image.create(size, size, false, Image.FORMAT_RGBA8)
	var c: = size * 0.5
	for y in range(size):
		for x in range(size):
			var dx: = x + 0.5 - c
			var dy: = y + 0.5 - c
			var d: = Vector2(dx, dy).length() / c
			var a: = 0.0
			if d > 0.72 and d < 0.9:
				a = 0.9
			elif d > 0.92 and d < 1.0:
				a = 0.55
			if absf(dx) < 3.0 and absf(dy) < 24.0:
				a = maxf(a, 0.85)
			if absf(dy) < 3.0 and absf(dx) < 24.0:
				a = maxf(a, 0.85)
			img.set_pixel(x, y, Color(1, 1, 1, a))
	return ImageTexture.create_from_image(img)


func _draw() -> void :
	if _tex_body:
		return
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(S, S))
	draw_rect(Rect2(-18, -11, 36, 22), MID)
	draw_rect(Rect2(-16, -10, 32, 3), LIGHT)
	draw_circle(Vector2(0, 2), 5.0, DARK)
	draw_circle(Vector2(0, 2), 3.0, CYAN)
	draw_rect(Rect2(-26, -15, 52, 3), LIGHT)
