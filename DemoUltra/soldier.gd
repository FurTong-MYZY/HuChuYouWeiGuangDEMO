extends CharacterBody2D
class_name Soldier



enum State{IDLE, AIM, COOLDOWN, STUNNED}

const S: = 8.0
const SOLDIER_ARMED_PATH: = "res://spr/角色/士兵/持枪.png"
const SOLDIER_LOWERED_PATH: = "res://spr/角色/士兵/放下枪.png"
const SOLDIER_SCALE: = 5.2
const SOLDIER_CENTER_Y: = -78.0
const MUZZLE_OFFSET: = Vector2(272.0, -172.0)
const CYAN: = Color(0.22, 0.95, 1.0)
const RED: = Color(1.0, 0.28, 0.28)
const ORANGE: = Color(1.0, 0.55, 0.1)
const DARK: = Color(0.07, 0.08, 0.14)
const MID: = Color(0.13, 0.15, 0.24)
const LIGHT: = Color(0.25, 0.28, 0.42)

@export var gravity: float = 6666.0
@export var aim_duration: float = 0.7
@export var fire_cooldown: float = 1.15
@export var stun_duration: float = 1.6
@export var bullet_scene: PackedScene
@export var range_x: float = 420.0
@export var range_y: float = 220.0
@export var bullet_speed: float = 4960.0
@export var burst_count: int = 3
@export var burst_interval: float = 0.12

var state: State = State.IDLE
var player: CharacterBody2D = null
var facing_right: bool = false
var _state_time: float = 0.0
var _t: float = 0.0
var _recoil: float = 0.0
var _burst_left: int = 0
var _burst_timer: float = 0.0
var _hit_cd: float = 0.0

var _body_root: Node2D
var _body_sprite: Sprite2D
var _charge_sprite: Sprite2D
var _muzzle_flash: Sprite2D
var _alert_sprite: Sprite2D
var _laser: Line2D
var _laser_glow: Line2D
var _laser_overlay: CanvasLayer
var _ov_outer: Line2D
var _ov_beam: Line2D
var _ov_core: Line2D
var _ov_band: Sprite2D
var _ov_charge: Sprite2D
var _ov_target: Sprite2D
var _ov_player: Sprite2D
var _aim_len: float = 0.0
static var _overlay_reticle_tex: Texture2D = null
static var _overlay_ring_tex: Texture2D = null
static var _overlay_band_tex: Texture2D = null
var _stars: Array[Sprite2D] = []
var _hitbox: Area2D

var _tex_flash: Texture2D
var _tex_alert: Texture2D
var _tex_star: Texture2D
var _armed_tex: Texture2D
var _lowered_tex: Texture2D

func _ready() -> void :
	collision_layer = 4
	collision_mask = 1 | 4

	var cs: = CollisionShape2D.new()
	var capsule: = CapsuleShape2D.new()
	capsule.radius = 12.0 * S * 1.3
	capsule.height = 42.0 * S * 1.3
	cs.shape = capsule
	add_child(cs)

	_hitbox = Area2D.new()
	_hitbox.collision_layer = 0
	_hitbox.collision_mask = 3
	var hs: = CollisionShape2D.new()
	var hrect: = RectangleShape2D.new()
	hrect.size = Vector2(32, 46) * S * 1.3
	hs.shape = hrect
	hs.position = Vector2(0, -2 * S)
	_hitbox.add_child(hs)
	add_child(_hitbox)
	_hitbox.body_entered.connect(_on_hitbox_body_entered)

	_build_sprites()
	_build_laser_overlay()

	_tex_flash = await PixelArt.bake_texture(_bake_flash, Vector2i(32 * S, 24 * S), self)
	_tex_alert = await PixelArt.bake_texture(_bake_alert, Vector2i(12 * S, 20 * S), self)
	_tex_star = await PixelArt.bake_texture(_bake_star, Vector2i(8 * S, 8 * S), self)
	_apply_textures()

func _build_sprites() -> void :
	_body_root = Node2D.new()
	add_child(_body_root)

	_body_sprite = Sprite2D.new()
	_body_sprite.centered = true
	_body_root.add_child(_body_sprite)

	_charge_sprite = Sprite2D.new()
	_charge_sprite.centered = true
	_charge_sprite.position = MUZZLE_OFFSET
	_charge_sprite.visible = false
	_body_root.add_child(_charge_sprite)

	_muzzle_flash = Sprite2D.new()
	_muzzle_flash.centered = true
	_muzzle_flash.position = MUZZLE_OFFSET
	_muzzle_flash.visible = false
	_body_root.add_child(_muzzle_flash)

	_alert_sprite = Sprite2D.new()
	_alert_sprite.centered = true
	_alert_sprite.position = Vector2(0, -36 * S)
	_alert_sprite.visible = false
	_body_root.add_child(_alert_sprite)

	_laser_glow = Line2D.new()
	_laser_glow.points = PackedVector2Array([Vector2.ZERO, Vector2(range_x * S, 0)])
	_laser_glow.width = 14.0
	_laser_glow.default_color = Color(1.0, 0.2, 0.1, 0.15)
	_laser_glow.position = MUZZLE_OFFSET
	_laser_glow.z_index = 5
	_laser_glow.material = _additive_material()
	_laser_glow.visible = false
	_body_root.add_child(_laser_glow)

	_laser = Line2D.new()
	_laser.points = PackedVector2Array([Vector2.ZERO, Vector2(range_x * S, 0)])
	_laser.width = 3.0
	_laser.default_color = Color(1.0, 0.2, 0.15, 0.9)
	_laser.position = MUZZLE_OFFSET
	_laser.z_index = 6
	_laser.material = _additive_material()
	_laser.visible = false
	_body_root.add_child(_laser)

	for i in range(3):
		var st: = Sprite2D.new()
		st.centered = true
		st.visible = false
		_body_root.add_child(st)
		_stars.append(st)

func _build_laser_overlay() -> void :
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
	_ov_outer = _make_overlay_line(12.0, Color(1.0, 0.04, 0.02, 0.45))
	_ov_beam = _make_overlay_line(4.0, Color(1.0, 0.22, 0.12, 0.95))
	_ov_core = _make_overlay_line(1.2, Color(1.0, 0.96, 0.84, 1.0))
	_ov_band = Sprite2D.new()
	_ov_band.texture = _make_overlay_band()
	_ov_band.centered = true
	_ov_band.material = _additive_material()
	_ov_band.visible = false
	_laser_overlay.add_child(_ov_band)
	_ov_charge = Sprite2D.new()
	_ov_charge.texture = _make_overlay_ring()
	_ov_charge.centered = true
	_ov_charge.material = _additive_material()
	_ov_charge.visible = false
	_laser_overlay.add_child(_ov_charge)
	_ov_target = Sprite2D.new()
	_ov_target.texture = _make_overlay_reticle()
	_ov_target.centered = true
	_ov_target.visible = false
	_laser_overlay.add_child(_ov_target)
	_ov_player = Sprite2D.new()
	_ov_player.texture = _make_overlay_reticle()
	_ov_player.centered = true
	_ov_player.scale = Vector2(0.52, 0.52)
	_ov_player.visible = false
	_laser_overlay.add_child(_ov_player)

func _make_overlay_line(line_width: float, color: Color) -> Line2D:
	var line: = Line2D.new()
	line.width = line_width
	line.default_color = color
	line.material = _additive_material()
	line.visible = false
	_laser_overlay.add_child(line)
	return line

func _make_overlay_band() -> Texture2D:
	if _overlay_band_tex:
		return _overlay_band_tex
	var w: = 64
	var h: = 32
	var img: = Image.create(w, h, false, Image.FORMAT_RGBA8)
	for y in range(h):
		var vy: float = 1.0 - absf(y + 0.5 - h * 0.5) / (h * 0.5)
		var a: float = pow(maxf(0.0, vy), 2.2)
		for x in range(w):
			var hx: float = minf(1.0, minf(x + 0.5, w - x - 0.5) / 8.0)
			img.set_pixel(x, y, Color(1, 1, 1, a * hx))
	_overlay_band_tex = ImageTexture.create_from_image(img)
	return _overlay_band_tex

func _make_overlay_ring() -> Texture2D:
	if _overlay_ring_tex:
		return _overlay_ring_tex
	var size: = 96
	var img: = Image.create(size, size, false, Image.FORMAT_RGBA8)
	var c: = size * 0.5
	for y in range(size):
		for x in range(size):
			var d: = Vector2(x + 0.5 - c, y + 0.5 - c).length() / c
			var a: = 0.0
			if d > 0.7 and d < 0.82:
				a = 0.9
			elif d > 0.9 and d < 0.96:
				a = 0.4
			img.set_pixel(x, y, Color(1, 1, 1, a))
	_overlay_ring_tex = ImageTexture.create_from_image(img)
	return _overlay_ring_tex

func _make_overlay_reticle() -> Texture2D:
	if _overlay_reticle_tex:
		return _overlay_reticle_tex
	var size: = 128
	var img: = Image.create(size, size, false, Image.FORMAT_RGBA8)
	var c: = size * 0.5
	for y in range(size):
		for x in range(size):
			var dx: float = absf(x + 0.5 - c)
			var dy: float = absf(y + 0.5 - c)
			var d: = Vector2(dx, dy).length() / c
			var a: = 0.0
			if d > 0.7 and d < 0.74:
				a = 0.5
			if (dx > 30.0 and dx < 48.0 and dy < 3.5) or (dy > 30.0 and dy < 48.0 and dx < 3.5):
				a = maxf(a, 0.95)
			if dx < 2.0 and dy < 14.0:
				a = maxf(a, 0.9)
			if dy < 2.0 and dx < 14.0:
				a = maxf(a, 0.9)
			if dx < 2.5 and dy < 2.5:
				a = 1.0
			img.set_pixel(x, y, Color(1, 1, 1, a))
	_overlay_reticle_tex = ImageTexture.create_from_image(img)
	return _overlay_reticle_tex

func _apply_textures() -> void :
	_armed_tex = load(SOLDIER_ARMED_PATH)
	_lowered_tex = load(SOLDIER_LOWERED_PATH)
	_body_sprite.texture = _armed_tex
	_body_sprite.scale = Vector2(SOLDIER_SCALE, SOLDIER_SCALE)
	_body_sprite.position = Vector2(0, SOLDIER_CENTER_Y)
	_charge_sprite.texture = _tex_flash
	_charge_sprite.position = MUZZLE_OFFSET
	_muzzle_flash.texture = _tex_flash
	_muzzle_flash.position = MUZZLE_OFFSET
	_alert_sprite.texture = _tex_alert
	_alert_sprite.position = Vector2(0, -384.6)
	for st in _stars:
		st.texture = _tex_star


func _bake_flash(ci: CanvasItem) -> void :
	var s: = S
	ci.draw_set_transform(Vector2(16 * s, 12 * s), 0.0, Vector2(s, s))
	ci.draw_circle(Vector2.ZERO, 10.0, Color(1, 0.55, 0.15, 0.35))
	ci.draw_circle(Vector2.ZERO, 6.5, Color(1, 0.85, 0.45, 0.8))
	ci.draw_circle(Vector2.ZERO, 3.2, Color(1, 1, 0.9, 1.0))
	for i in range(4):
		var ang: = i * PI * 0.5
		ci.draw_line(Vector2(cos(ang), sin(ang)) * 5.0, Vector2(cos(ang), sin(ang)) * 11.0, Color(1, 0.8, 0.35, 0.75), 1.5)

func _bake_alert(ci: CanvasItem) -> void :
	var s: = S
	ci.draw_set_transform(Vector2(6 * s, 10 * s), 0.0, Vector2(s, s))
	ci.draw_rect(Rect2(-2, -8, 4, 11), Color(1.0, 0.85, 0.2, 0.95))
	ci.draw_rect(Rect2(-2, 5, 4, 3), Color(1.0, 0.85, 0.2, 0.95))
	ci.draw_rect(Rect2(-1, -7, 2, 9), Color(1.0, 1.0, 0.9, 1.0))

func _bake_star(ci: CanvasItem) -> void :
	var s: = S
	ci.draw_set_transform(Vector2(4 * s, 4 * s), 0.0, Vector2(s, s))
	for i in range(4):
		var ang: = i * PI * 0.5
		var d: = Vector2(cos(ang), sin(ang))
		ci.draw_line( - d * 3.0, d * 3.0, Color(1.0, 0.9, 0.3, 1.0), 1.2)


func _physics_process(delta: float) -> void :
	_t += delta
	_hit_cd = maxf(0.0, _hit_cd - delta)

	if not player or not is_instance_valid(player):
		player = _find_player()

	match state:
		State.IDLE:
			velocity.x = move_toward(velocity.x, 0.0, 1800.0 * delta)
			_update_alert()
		State.AIM:
			_state_time += delta
			velocity.x = move_toward(velocity.x, 0.0, 3000.0 * delta)
			if player:
				facing_right = player.global_position.x > global_position.x
			if not _can_see_player():
				_change(State.IDLE)
			elif _state_time >= aim_duration:
				_begin_burst()
		State.COOLDOWN:
			_state_time += delta
			velocity.x = move_toward(velocity.x, 0.0, 2200.0 * delta)
			if _burst_left > 0:
				_burst_timer -= delta
				if _burst_timer <= 0.0:
					_fire_one()
			elif _state_time >= fire_cooldown:
				_change(State.IDLE)
		State.STUNNED:
			_state_time += delta
			velocity.x *= pow(0.02, delta)
			if _state_time >= stun_duration:
				_change(State.IDLE)

	velocity.y += gravity * delta
	move_and_slide()

	if state != State.STUNNED and _hit_cd <= 0.0:
		for b in _hitbox.get_overlapping_bodies():
			if b.is_in_group("player") and b.is_dashing:
				_get_stunned(b)
				break

	_update_visuals(delta)

func _can_see_player() -> bool:
	if not player or not is_instance_valid(player):
		return false
	var dx: = absf(player.global_position.x - global_position.x)
	var dy: = absf(player.global_position.y - global_position.y)
	if dx > range_x * S or dy > range_y * S:
		return false
	return _has_line_of_sight()

func _has_line_of_sight() -> bool:
	if not player:
		return false
	var from: = global_position + Vector2(0, -2 * S)
	var to: = player.global_position
	var q: = PhysicsRayQueryParameters2D.create(from, to, 1)
	q.exclude = [self]
	var hit: = get_world_2d().direct_space_state.intersect_ray(q)
	if hit.is_empty():
		return true
	return hit.get("collider") == player

func _update_alert() -> void :
	if _can_see_player():
		facing_right = player.global_position.x > global_position.x
		_change(State.AIM)

func _change(s: State) -> void :
	state = s
	_state_time = 0.0
	_alert_sprite.visible = s == State.AIM
	_laser.visible = s == State.AIM
	_laser_glow.visible = s == State.AIM
	_charge_sprite.visible = s == State.AIM
	_muzzle_flash.visible = false
	if s != State.STUNNED:
		_body_root.rotation = 0.0
	for st in _stars:
		st.visible = s == State.STUNNED

func _begin_burst() -> void :
	_burst_left = maxi(1, burst_count)
	_burst_timer = 0.0
	_change(State.COOLDOWN)


func _muzzle_world() -> Vector2:
	var f: float = 1.0 if facing_right else -1.0
	return global_position + Vector2(
		_body_root.position.x + f * MUZZLE_OFFSET.x, 
		_body_root.position.y + MUZZLE_OFFSET.y
	)

func _fire_one() -> void :
	if _burst_left <= 0:
		return
	_burst_left -= 1
	_burst_timer = burst_interval
	var dir: float = 1.0 if facing_right else -1.0
	var muzzle: = _muzzle_world()

	var bullet: Area2D
	if bullet_scene:
		bullet = bullet_scene.instantiate()
	else:
		bullet = Bullet.new()
	bullet.direction = dir
	bullet.speed = bullet_speed
	bullet.damage = 75.0
	get_tree().current_scene.add_child(bullet)
	bullet.global_position = muzzle

	var flash: = Spark.new()
	get_tree().current_scene.add_child(flash)
	flash.global_position = muzzle
	flash.setup(Color(1.0, 0.95, 0.8), 8, 90.0 * S)

	_recoil = -6.0 * S
	_show_muzzle_flash()
	_spawn_overlay_shot()

func _show_muzzle_flash() -> void :
	if _muzzle_flash == null:
		return
	_muzzle_flash.visible = true
	_muzzle_flash.modulate = Color(1, 1, 1, 1)
	_muzzle_flash.scale = Vector2(0.29, 0.29)
	var tw: = create_tween()
	tw.set_parallel(true)
	tw.tween_property(_muzzle_flash, "scale", Vector2(0.55, 0.55), 0.1)
	tw.tween_property(_muzzle_flash, "modulate:a", 0.0, 0.12)
	tw.chain().tween_callback( func(): _muzzle_flash.visible = false)

func _get_stunned(from_player: Node2D) -> void :
	if state == State.STUNNED or _hit_cd > 0.0:
		return
	_hit_cd = 0.8
	var push_dir: float = signf(global_position.x - from_player.global_position.x)
	if push_dir == 0.0:
		push_dir = 1.0 if not facing_right else -1.0
	_change(State.STUNNED)
	velocity.x = push_dir * 340.0 * S
	velocity.y = -180.0 * S
	var spark: = Spark.new()
	get_tree().current_scene.add_child(spark)
	spark.global_position = global_position + Vector2(0, -2 * S)
	spark.setup(Color(0.8, 0.95, 1.0), 10, 110.0 * S)

func _on_hitbox_body_entered(body: Node2D) -> void :
	if body.is_in_group("player") and body.is_dashing and state != State.STUNNED:
		_get_stunned(body)


func _update_laser_overlay(show: bool, t: float, pulse: float) -> void :
	if _laser_overlay == null:
		return
	if not show or player == null:
		for n in [_ov_outer, _ov_beam, _ov_core, _ov_band, _ov_charge, _ov_target, _ov_player]:
			n.visible = false
		return

	var dir: float = 1.0 if facing_right else -1.0
	var muzzle_world: = _muzzle_world()
	var max_len: float = range_x * S
	var q: = PhysicsRayQueryParameters2D.create(muzzle_world, muzzle_world + Vector2(dir * max_len, 0), 1)
	q.exclude = [self]
	var hit: = get_world_2d().direct_space_state.intersect_ray(q)
	var length: = max_len
	if not hit.is_empty():
		var hp: Vector2 = hit["position"]
		length = clampf(muzzle_world.distance_to(hp), 20.0 * S, max_len)
	_aim_len = length

	var xf: = get_viewport().get_canvas_transform()
	var s0: = xf * muzzle_world
	var s1: = xf * (muzzle_world + Vector2(dir * length, 0))
	var pts: = PackedVector2Array([s0, s1])
	for line in [_ov_outer, _ov_beam, _ov_core]:
		line.points = pts
		line.visible = true
	_ov_outer.modulate = Color(1.0, 0.04, 0.02, 0.35 + 0.2 * t)
	_ov_beam.modulate = Color(1.0, 0.24, 0.12, 0.9 + 0.1 * t)
	_ov_core.modulate = Color(1.0, 0.96, 0.84, 1.0)
	_ov_band.visible = false
	_ov_charge.visible = true
	_ov_charge.position = s0
	var cs: = 0.5 + t * 1.5 + pulse * 0.15
	_ov_charge.scale = Vector2(cs, cs)
	_ov_charge.rotation = _state_time * 2.4
	_ov_charge.modulate = Color(1.0, 0.25, 0.1, 0.35 + 0.45 * t)
	_ov_target.visible = true
	_ov_target.position = s1
	_ov_target.rotation = _state_time * 0.8
	_ov_target.scale = Vector2(0.82 + 0.08 * pulse, 0.82 + 0.08 * pulse)
	_ov_target.modulate = Color(1.0, 0.22 + 0.2 * t, 0.12, 0.72 + 0.25 * t)
	_ov_player.visible = true
	_ov_player.position = xf * (player.global_position + Vector2(0, -65.0))
	_ov_player.rotation = - _state_time * 0.7
	_ov_player.modulate = Color(1.0, 0.18 + 0.2 * t, 0.1, 0.72 + 0.25 * t)

func _spawn_overlay_shot() -> void :
	if _laser_overlay == null:
		return
	var dir: float = 1.0 if facing_right else -1.0
	var muzzle_world: = _muzzle_world()
	var length: = _aim_len if _aim_len > 0.0 else range_x * S
	var xf: = get_viewport().get_canvas_transform()
	var s0: = xf * muzzle_world
	var s1: = xf * (muzzle_world + Vector2(dir * length, 0))
	var line: = Line2D.new()
	line.points = PackedVector2Array([s0, s1])
	line.width = 3.5
	line.default_color = Color(1.0, 0.9, 0.7, 0.95)
	line.material = _additive_material()
	line.z_index = 10
	_laser_overlay.add_child(line)
	var tw: = create_tween()
	tw.tween_property(line, "modulate:a", 0.0, 0.14)
	tw.tween_callback(line.queue_free)

func _update_visuals(delta: float) -> void :
	var f: float = 1.0 if facing_right else -1.0
	_body_root.scale.x = f
	if state == State.STUNNED and _lowered_tex:
		_body_sprite.texture = _lowered_tex
	elif _armed_tex:
		_body_sprite.texture = _armed_tex
	_recoil = move_toward(_recoil, 0.0, 900.0 * delta)

	var bob: = sin(_t * 2.2) * 1.2 * S
	var lean: = 0.0
	if state == State.AIM:
		lean = 2.0 * S
	elif state == State.COOLDOWN:
		lean = 0.5 * S
	_body_root.position = Vector2(f * (lean + _recoil), bob)
	if state == State.STUNNED:
		_body_root.rotation = sin(_state_time * 11.0) * 0.1
		_body_root.position.y = - absf(sin(_state_time * 8.0)) * 2.0 * S
	else:
		_body_root.rotation = sin(_t * 1.4) * 0.008

	if state == State.AIM:
		var t: = clampf(_state_time / aim_duration, 0.0, 1.0)
		var pulse: = 0.5 + 0.5 * sin(_state_time * 24.0)
		_update_laser_overlay(true, t, pulse)
		var a: = 0.2 + 0.55 * t + 0.15 * pulse
		_laser.modulate = Color(1.0, 0.22, 0.16, clampf(a, 0.0, 1.0))
		_laser_glow.modulate = Color(1.0, 0.15, 0.08, 0.1 + 0.12 * t)
		_charge_sprite.visible = true
		var cs: = 0.16 + t * 0.44 + pulse * 0.06
		_charge_sprite.scale = Vector2(cs, cs)
		_charge_sprite.modulate = Color(1, 0.55 + 0.3 * t, 0.3, 0.85)
		_alert_sprite.visible = true
		_alert_sprite.scale = Vector2.ONE * (0.8 + 0.2 * pulse)
		_alert_sprite.modulate = Color(1, 1, 1, 0.7 + 0.3 * pulse)
	else:
		_charge_sprite.visible = false
		_alert_sprite.visible = false
		_update_laser_overlay(false, 0.0, 0.0)

	if state == State.STUNNED:
		for i in range(_stars.size()):
			var st: = _stars[i]
			st.visible = true
			var ang: = _state_time * 7.0 + i * TAU / 3.0
			st.position = Vector2(cos(ang) * 10.0 * S, -309.6 + sin(ang) * 3.0 * S)
			st.rotation = _state_time * 4.0 + i


func _find_player() -> CharacterBody2D:
	var nodes: = get_tree().get_nodes_in_group("player")
	return nodes[0] if nodes.size() > 0 else null

static func _additive_material() -> CanvasItemMaterial:
	var m: = CanvasItemMaterial.new()
	m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	return m
