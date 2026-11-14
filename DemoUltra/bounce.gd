extends Area2D

enum Motion{STATIC, VERTICAL_SHM, CIRCULAR, ROTATING}

@export var motion: Motion = Motion.STATIC
@export var shm_amplitude: float = 180.0
@export var shm_speed: float = 1.6
@export var orbit_radius: float = 220.0
@export var orbit_speed: float = 1.2
@export var rotation_speed: float = 1.0
@export var fx_color: Color = Color(0.35, 0.95, 1.0)

@export var bounce_speed: float = 500.0
@export var bounce_duration: float = 0.3
@export var decay_rate: float = 5.0
@export var min_speed_percent: float = 0.1
@export var bounce_direction: Vector2 = Vector2.UP


@export var squash_amount: float = 0.3
@export var stretch_amount: float = 0.2
@export var animation_duration: float = 0.3


@export var pre_compress_distance: float = 14.0
@export var pre_compress_time: float = 0.08
@export var pre_recover_time: float = 0.06


@export var glow_brightness: float = 1.8
@export var glow_duration: float = 0.25
@export var bounce_sound: AudioStream
@export var bounce_sound_volume: float = 0.0

const DEFAULT_BOUNCE_SOUND: = "res://sound/bounce.wav"

var player: Node2D = null
var is_bouncing: bool = false
var bounce_velocity: Vector2 = Vector2.ZERO
var bounce_time: float = 0.0
var _launch_direction: Vector2 = Vector2.UP
var _last_safe_player_pos: Vector2 = Vector2.ZERO
var _has_last_safe: bool = false

var _motion_time: float = 0.0
var _base_position: Vector2 = Vector2.ZERO
var _base_rotation: float = 0.0
var _orbit_center: Vector2 = Vector2.ZERO
var _holo: Sprite2D = null
var _gyro: Sprite2D = null
var _ghost_timer: float = 0.0
var motion_active: bool = false
var _fx_scale: float = 1.0

static var _tex_ring: Texture2D = null
static var _tex_glow: Texture2D = null
static var _tex_spark: Texture2D = null
static var _tex_holo: Texture2D = null
static var _tex_beam: Texture2D = null
static var _mat_add: CanvasItemMaterial = null


@onready var bounce_sprite: Sprite2D = $Sprite2D
@onready var particles: GPUParticles2D = get_node_or_null("GPUParticles2D")
var audio_player: AudioStreamPlayer


var original_scale: Vector2 = Vector2.ONE
var is_animating: bool = false
var animation_time: float = 0.0

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	if bounce_sprite:
		original_scale = bounce_sprite.scale
		if bounce_sprite.texture:
			_fx_scale = maxf(bounce_sprite.texture.get_width(), bounce_sprite.texture.get_height()) / 128.0

	_base_position = position
	_base_rotation = rotation
	_orbit_center = global_position - Vector2(orbit_radius, 0.0)

	_ensure_fx_textures()
	_build_idle_fx()
	_build_motion_fx()


	audio_player = AudioStreamPlayer.new()
	audio_player.name = "AudioStreamPlayer"
	add_child(audio_player)

func _on_body_entered(body):
	if body.is_in_group("player"):
		player = body


func _on_body_exited(body):
	if body == player:

		if not is_bouncing:
			player = null




func _update_motion() -> void :
	match motion:
		Motion.VERTICAL_SHM:
			position.y = _base_position.y + sin(_motion_time * shm_speed) * shm_amplitude
		Motion.CIRCULAR:
			var ang: = _motion_time * orbit_speed
			var tangent: = Vector2( - sin(ang), cos(ang))
			if orbit_speed < 0.0:
				tangent = - tangent
			global_position = _orbit_center + Vector2(cos(ang), sin(ang)) * orbit_radius
			if tangent.length_squared() > 0.0001:
				bounce_direction = tangent.normalized()

			rotation = bounce_direction.angle() + PI * 0.5
		Motion.ROTATING:
			rotation = _base_rotation + _motion_time * rotation_speed
			bounce_direction = Vector2.UP.rotated(rotation)




func _build_idle_fx() -> void :
	_holo = Sprite2D.new()
	_holo.name = "HoloRing"
	_holo.texture = _tex_holo
	_holo.material = _add_material()
	_holo.modulate = Color(fx_color.r, fx_color.g, fx_color.b, 0.3)
	_holo.z_index = 1
	_holo.scale = Vector2.ONE * _fx_scale
	add_child(_holo)

func _build_motion_fx() -> void :
	match motion:
		Motion.VERTICAL_SHM:
			var holder: = Node2D.new()
			holder.top_level = true
			add_child(holder)
			holder.global_position = global_position

			var rail: = Line2D.new()
			rail.points = PackedVector2Array([Vector2(0.0, - shm_amplitude), Vector2(0.0, shm_amplitude)])
			rail.width = 4.0
			rail.default_color = Color(fx_color.r, fx_color.g, fx_color.b, 0.16)
			rail.material = _add_material()
			rail.z_index = 1
			holder.add_child(rail)
		Motion.CIRCULAR:
			var holder: = Node2D.new()
			holder.top_level = true
			add_child(holder)
			holder.global_position = _orbit_center

			var orbit: = Sprite2D.new()
			orbit.texture = _tex_ring
			orbit.material = _add_material()
			orbit.modulate = Color(fx_color.r, fx_color.g, fx_color.b, 0.12)
			orbit.scale = Vector2.ONE * (orbit_radius / 64.0)
			orbit.z_index = 1
			holder.add_child(orbit)
		Motion.ROTATING:
			_gyro = Sprite2D.new()
			_gyro.texture = _tex_ring
			_gyro.material = _add_material()
			_gyro.modulate = Color(fx_color.r, fx_color.g, fx_color.b, 0.18)
			_gyro.scale = Vector2.ONE * (_fx_scale * 0.85)
			_gyro.z_index = 1
			add_child(_gyro)

func _update_motion_fx(delta: float) -> void :
	if _gyro:
		_gyro.rotation -= delta * 1.6
	if motion != Motion.STATIC or motion_active:
		_ghost_timer -= delta
		if _ghost_timer <= 0.0:
			_ghost_timer = 0.11
			_spawn_motion_ghost()

func _spawn_motion_ghost() -> void :
	if bounce_sprite == null or bounce_sprite.texture == null:
		return
	var host: = get_parent()
	if host == null:
		return
	var g: = Sprite2D.new()
	g.texture = bounce_sprite.texture
	g.centered = true
	g.scale = bounce_sprite.scale * scale
	g.modulate = Color(fx_color.r, fx_color.g, fx_color.b, 0.1)
	g.material = _add_material()
	g.z_index = 1
	host.add_child(g)
	g.global_position = global_position
	g.global_rotation = global_rotation
	var tw: = create_tween()
	tw.tween_property(g, "modulate:a", 0.0, 0.3)
	tw.tween_callback(g.queue_free)

func _spawn_launch_fx() -> void :
	if not is_inside_tree():
		return
	_spawn_ring(0.0, 2.2, 0.38)
	_spawn_ring(0.07, 1.5, 0.28)
	_spawn_beam()
	_spawn_sparks()
	_spawn_arrow_ghosts()
	_spawn_flash()
	_shake_camera()

func _spawn_ring(delay: float, target_mult: float, life: float) -> void :
	var ring: = Sprite2D.new()
	ring.texture = _tex_ring
	ring.material = _add_material()
	ring.modulate = Color(fx_color.r, fx_color.g, fx_color.b, 0.9)
	ring.scale = Vector2.ONE * (0.15 * _fx_scale)
	ring.z_index = 20
	add_child(ring)
	var tw: = create_tween()
	if delay > 0.0:
		tw.tween_interval(delay)
	tw.tween_property(ring, "scale", Vector2.ONE * (target_mult * _fx_scale), life)\
	.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(ring, "modulate:a", 0.0, life)
	tw.tween_callback(ring.queue_free)

func _spawn_beam() -> void :
	var length: = 720.0
	_spawn_beam_layer(length, 4.5, 0.18, Color(fx_color.r, fx_color.g, fx_color.b, 1.0), 17, 0.38)
	_spawn_beam_layer(length, 2.6, 0.55, Color(fx_color.r, fx_color.g, fx_color.b, 1.0), 18, 0.32)
	_spawn_beam_layer(length, 1.0, 0.95, Color.WHITE, 19, 0.26)

func _spawn_beam_layer(length: float, width_mult: float, alpha: float, color: Color, z: int, life: float) -> void :
	var beam: = Sprite2D.new()
	beam.texture = _tex_beam
	beam.centered = true
	beam.position = Vector2(0.0, - length * 0.5)
	beam.scale = Vector2(width_mult, length / 256.0)
	beam.modulate = Color(color.r, color.g, color.b, alpha)
	beam.material = _add_material()
	beam.z_index = z
	add_child(beam)
	var tw: = create_tween()
	tw.tween_property(beam, "scale:x", width_mult * 1.7, life)\
	.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(beam, "modulate:a", 0.0, life)
	tw.tween_callback(beam.queue_free)

func _spawn_sparks() -> void :
	for i in range(18):
		var s: = Sprite2D.new()
		s.texture = _tex_spark
		s.material = _add_material()
		s.z_index = 19
		var start: = Vector2(randf_range(-26.0, 26.0), randf_range(-18.0, 18.0))
		var dir: = Vector2.UP.rotated(randf_range(-0.75, 0.75))
		s.position = start
		s.rotation = dir.angle() + PI * 0.5
		s.scale = Vector2(1.2, 3.2) * randf_range(0.8, 1.25)
		if i % 3 == 0:
			s.modulate = Color(1, 1, 1, 0.95)
		else:
			s.modulate = Color(fx_color.r, fx_color.g, fx_color.b, 0.9)
		add_child(s)
		var dist: = randf_range(280.0, 640.0)
		var life: = randf_range(0.35, 0.55)
		var tw: = create_tween()
		tw.set_parallel(true)
		tw.tween_property(s, "position", start + dir * dist, life)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(s, "scale", s.scale * 0.15, life)
		tw.tween_property(s, "modulate:a", 0.0, life)
		tw.chain().tween_callback(s.queue_free)

func _spawn_arrow_ghosts() -> void :
	if bounce_sprite == null or bounce_sprite.texture == null:
		return
	for i in range(3):
		var g: = Sprite2D.new()
		g.texture = bounce_sprite.texture
		g.centered = true
		g.scale = bounce_sprite.scale * (0.9 - i * 0.12)
		g.modulate = Color(fx_color.r, fx_color.g, fx_color.b, 0.35)
		g.material = _add_material()
		g.z_index = 15
		add_child(g)
		var tw: = create_tween()
		tw.set_parallel(true)
		tw.tween_property(g, "position", Vector2(0.0, -180.0 * (i + 1)), 0.22 + i * 0.04)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(g, "modulate:a", 0.0, 0.28 + i * 0.04)
		tw.tween_property(g, "scale", g.scale * 1.2, 0.3)
		tw.chain().tween_callback(g.queue_free)

func _spawn_flash() -> void :
	var flash: = Sprite2D.new()
	flash.texture = _tex_glow
	flash.material = _add_material()
	flash.modulate = Color(fx_color.r, fx_color.g, fx_color.b, 0.9)
	flash.scale = Vector2.ONE * (_fx_scale * 1.8)
	flash.z_index = 1
	add_child(flash)
	var tw: = create_tween()
	tw.tween_property(flash, "scale", Vector2.ONE * (_fx_scale * 3.6), 0.22)\
	.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(flash, "modulate:a", 0.0, 0.22)
	tw.tween_callback(flash.queue_free)

func _shake_camera() -> void :
	var cam: = get_viewport().get_camera_2d()
	if cam == null:
		return
	var base: = cam.offset
	var tw: = create_tween()
	for i in range(4):
		tw.tween_property(cam, "offset", base + Vector2(randf_range(-4.0, 4.0), randf_range(-3.0, 3.0)), 0.03)
	tw.tween_property(cam, "offset", base, 0.06)




static func _ensure_fx_textures() -> void :
	if _tex_ring != null:
		return
	_tex_ring = _make_ring_texture(128)
	_tex_glow = _make_glow_texture(64)
	_tex_spark = _make_glow_texture(16)
	_tex_holo = _make_holo_texture(128)
	_tex_beam = _make_beam_texture(96, 256)

static func _make_ring_texture(size: int) -> Texture2D:
	var img: = Image.create(size, size, false, Image.FORMAT_RGBA8)
	var c: = size * 0.5
	for y in range(size):
		for x in range(size):
			var d: = Vector2(x + 0.5 - c, y + 0.5 - c).length() / c
			var a: = 0.0
			if d > 0.72 and d < 1.0:
				a = smoothstep(0.72, 0.84, d) * (1.0 - smoothstep(0.9, 1.0, d))
			img.set_pixel(x, y, Color(1, 1, 1, a))
	return ImageTexture.create_from_image(img)

static func _make_glow_texture(size: int) -> Texture2D:
	var img: = Image.create(size, size, false, Image.FORMAT_RGBA8)
	var c: = size * 0.5
	for y in range(size):
		for x in range(size):
			var d: = Vector2(x + 0.5 - c, y + 0.5 - c).length() / c
			var a: = pow(maxf(0.0, 1.0 - d), 2.2)
			img.set_pixel(x, y, Color(1, 1, 1, a))
	return ImageTexture.create_from_image(img)

static func _make_holo_texture(size: int) -> Texture2D:
	var img: = Image.create(size, size, false, Image.FORMAT_RGBA8)
	var c: = size * 0.5
	for y in range(size):
		for x in range(size):
			var dx: = x + 0.5 - c
			var dy: = y + 0.5 - c
			var d: = Vector2(dx, dy).length() / c
			var a: = 0.0
			if d > 0.76 and d < 0.98:
				var ang: = atan2(dy, dx)
				var seg: = int((ang + PI) / TAU * 36.0)
				if seg % 3 != 0:
					a = 0.8
			img.set_pixel(x, y, Color(1, 1, 1, a))
	return ImageTexture.create_from_image(img)

static func _make_beam_texture(w: int, h: int) -> Texture2D:
	var img: = Image.create(w, h, false, Image.FORMAT_RGBA8)
	var cx: = w * 0.5
	for y in range(h):
		var v: float = float(y) / float(h - 1)
		var vy: float = pow(v, 1.3)
		for x in range(w):
			var hx: float = 1.0 - absf(x + 0.5 - cx) / cx
			var a: float = vy * pow(maxf(0.0, hx), 1.8)
			img.set_pixel(x, y, Color(1, 1, 1, a))
	return ImageTexture.create_from_image(img)

static func _add_material() -> CanvasItemMaterial:
	if _mat_add == null:
		_mat_add = CanvasItemMaterial.new()
		_mat_add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	return _mat_add

func start_bounce():
	if not player or not is_instance_valid(player):
		return


	_do_bounce()



	var direction = Vector2.UP
	var origin_pos = bounce_sprite.position
	var tw = bounce_sprite.create_tween()
	tw.tween_property(bounce_sprite, "position", origin_pos - direction * pre_compress_distance, pre_compress_time)\
	.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(bounce_sprite, "position", origin_pos, pre_recover_time)\
	.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

func _do_bounce():
	if not player or not is_instance_valid(player):
		return
	is_bouncing = true
	bounce_time = 0.0
	_last_safe_player_pos = player.global_position
	_has_last_safe = true

	var direction = bounce_direction.normalized()
	_launch_direction = direction
	bounce_velocity = direction * bounce_speed

	if player is CharacterBody2D:
		player.is_bouncing_from_bumper = true
		player.velocity = Vector2.ZERO
		if player.is_dashing and player.has_method("_end_dash_anim"):
			player.is_dashing = false
			player._end_dash_anim()

func _process(delta):
	_motion_time += delta
	_update_motion()
	_update_motion_fx(delta)

	if _holo:
		_holo.rotation += delta * 0.55
		_holo.modulate.a = 0.18 + 0.08 * sin(_motion_time * 2.4)


	if player and not is_bouncing:
		var mc: = get_node_or_null("/root/MobileControls")
		var pressed: = Input.is_action_just_pressed("interact")
		if mc and mc.interact_queued > 0:
			mc.interact_queued -= 1
			pressed = true
		if pressed:
			start_bounce()
			play_bounce_effects()

	if is_bouncing and player and is_instance_valid(player):
		bounce_time += delta

		if Input.is_action_just_pressed("dash"):

			_end_bounce_and_dash()
			return

		if bounce_time >= bounce_duration:

			stop_bounce()
			return


		var progress = bounce_time / bounce_duration
		var decay_factor = exp( - decay_rate * bounce_time)

		var min_factor = min_speed_percent
		decay_factor = max(decay_factor, min_factor)

		var current_velocity = bounce_velocity * decay_factor

		var movement = current_velocity * delta


		if player is CharacterBody2D:
			player.global_position += movement
		elif player is RigidBody2D:
			player.global_position += movement

		if not _player_overlaps_solid(player.global_position):
			_last_safe_player_pos = player.global_position
			_has_last_safe = true


	if is_animating and bounce_sprite:
		animation_time += delta

		if animation_time < animation_duration:
			var progress = animation_time / animation_duration

			if progress < 0.3:
				var squash_progress = progress / 0.3
				var current_squash = squash_amount * squash_progress
				var current_stretch = stretch_amount * squash_progress * 0.5

				bounce_sprite.scale = original_scale * Vector2(
					1.0 - current_squash, 
					1.0 + current_stretch
				)
			elif progress < 0.6:
				var stretch_progress = (progress - 0.3) / 0.3
				var current_stretch = stretch_amount * (1.0 - stretch_progress)
				var current_squash = squash_amount * (1.0 - stretch_progress)

				bounce_sprite.scale = original_scale * Vector2(
					1.0 + current_stretch, 
					1.0 - current_squash * 0.5
				)
			else:
				var recover_progress = (progress - 0.6) / 0.4
				var eased_recover = ease(recover_progress, 3.0)

				bounce_sprite.scale = original_scale * Vector2(
					1.0 + stretch_amount * (1.0 - eased_recover), 
					1.0 - squash_amount * 0.5 * (1.0 - eased_recover)
				)
		else:
			is_animating = false
			bounce_sprite.scale = original_scale

func _end_bounce_and_dash():
	if not player or not is_instance_valid(player):
		stop_bounce()
		return


	is_bouncing = false
	bounce_time = 0.0
	bounce_velocity = Vector2.ZERO
	_resolve_player_stuck()

	if player is CharacterBody2D:
		player.is_bouncing_from_bumper = false

		var input_dir = Input.get_axis("move_left", "move_right")

		player._try_dash(input_dir)

		if not player.is_dashing:
			var dash_dir = input_dir if input_dir != 0 else (1 if player.facing_right else -1)
			player.velocity = Vector2(dash_dir * player.dash_speed, 0)

	player = null

func play_bounce_effects():
	if particles:
		particles.restart()
		particles.emitting = true

	start_squash_animation()
	_play_glow()
	_play_sound()
	_spawn_launch_fx()


func _play_glow() -> void :
	if not bounce_sprite:
		return
	var tw: = create_tween()
	tw.tween_property(bounce_sprite, "modulate", Color(glow_brightness, glow_brightness, glow_brightness * 0.85, 1.0), 0.04)
	tw.tween_property(bounce_sprite, "modulate", Color.WHITE, glow_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _play_sound() -> void :
	if not audio_player:
		return
	var snd: = bounce_sound
	if snd == null:
		snd = load(DEFAULT_BOUNCE_SOUND)
	if snd == null:
		return
	audio_player.stream = snd
	audio_player.volume_db = bounce_sound_volume
	audio_player.play()

func start_squash_animation():
	is_animating = true
	animation_time = 0.0

func stop_bounce():
	is_bouncing = false
	bounce_time = 0.0
	bounce_velocity = Vector2.ZERO
	_resolve_player_stuck()

	if player and is_instance_valid(player):
		if player is CharacterBody2D:
			player.is_bouncing_from_bumper = false
			var direction = _launch_direction.normalized()
			var final_speed = bounce_speed * min_speed_percent
			player.velocity = direction * final_speed
	player = null



func _resolve_player_stuck() -> void :
	if player == null or not is_instance_valid(player):
		return
	if not _player_overlaps_solid(player.global_position):
		_last_safe_player_pos = player.global_position
		_has_last_safe = true
		return

	var origin: = player.global_position



	var radius: = 16.0
	while radius <= 560.0:
		var best: Vector2 = Vector2.ZERO
		var found: = false
		for i in range(24):
			var ang: = TAU * float(i) / 24.0
			var p: Vector2 = origin + Vector2(cos(ang), sin(ang)) * radius
			if _player_overlaps_solid(p):
				continue
			if not found or p.y < best.y:
				best = p
				found = true
		if found:
			player.global_position = best
			return
		radius += 16.0


	if _has_last_safe and not _player_overlaps_solid(_last_safe_player_pos):
		player.global_position = _last_safe_player_pos
		return
	var device_fallback: = global_position + Vector2(0, -40)
	if not _player_overlaps_solid(device_fallback):
		player.global_position = device_fallback

func _player_overlaps_solid(pos: Vector2) -> bool:
	if player == null or not is_instance_valid(player):
		return false
	var shape_node: CollisionShape2D = null
	if player is Node:
		shape_node = player.get_node_or_null("CollisionShape2D") as CollisionShape2D
		if shape_node == null:
			for child in player.get_children():
				if child is CollisionShape2D:
					shape_node = child
					break
	if shape_node == null or shape_node.shape == null:
		return false
	var world: = player.get_world_2d()
	if world == null:
		return false
	var query: = PhysicsShapeQueryParameters2D.new()
	query.shape = shape_node.shape
	var xf: = shape_node.global_transform
	xf.origin += pos - player.global_position
	query.transform = xf
	query.collision_mask = 1
	if player is CollisionObject2D:
		query.exclude = [player.get_rid()]
	return not world.direct_space_state.intersect_shape(query, 1).is_empty()

func _exit_tree():
	if body_entered.is_connected(_on_body_entered):
		body_entered.disconnect(_on_body_entered)
	if body_exited.is_connected(_on_body_exited):
		body_exited.disconnect(_on_body_exited)
