@tool
extends StaticBody2D
class_name NeonBlock









enum Mode{DASH, JUMP, LEFT, RIGHT, INTERACT}

@export var mode: Mode = Mode.DASH:
	set(value):
		mode = value
		_refresh_colors()
		if Engine.is_editor_hint():
			_solid = _rest_solid()
			if is_inside_tree():
				queue_redraw()
@export var block_size: Vector2 = Vector2(56, 56):
	set(value):
		block_size = value
		if Engine.is_editor_hint() and is_inside_tree():
			queue_redraw()
@export var hold_solid: bool = true:
	set(value):
		hold_solid = value
		if Engine.is_editor_hint():
			_solid = _rest_solid()
			if is_inside_tree():
				queue_redraw()
@export var start_solid: bool = true:
	set(value):
		start_solid = value
		if Engine.is_editor_hint():
			_solid = _rest_solid()
			if is_inside_tree():
				queue_redraw()

@export var reverse_style: bool = false:
	set(value):
		reverse_style = value
		_refresh_colors()
		if Engine.is_editor_hint() and is_inside_tree():
			queue_redraw()

var _color: = Color.WHITE
var _base_color: = Color.WHITE
var _collision_shape: CollisionShape2D
var _solid: bool = true
var _display_alpha: float = 1.0
var _pulse: float = 0.0
var _solid_sprite: Sprite2D
var _tex_solid: Texture2D
var _tex_ghost: Texture2D
var _scan: Sprite2D
var _phase_fx: CPUParticles2D
var _prev_dash: bool = false
var _prev_jump: bool = false
var _airborne_time: float = 0.0
var _last_toggle_ms: int = -1000

const STUCK_AIR_RECOVERY_TIME: = 1.2
const STUCK_RECOVERY_RANGE: = 700.0
const TOGGLE_DEBOUNCE_MS: = 120

const BAKE_MARGIN: = 80.0


static var _tex_cache: Dictionary = {}
static var _tex_pending: Dictionary = {}
static var _scan_cache: Dictionary = {}

const ICONS: = {
	"dash": [
		"@@..@@..", 
		".@@..@@.", 
		"..@@..@@", 
		".@@..@@.", 
		"@@..@@..", 
	], 
	"jump": [
		"...@@...", 
		"..@@@@..", 
		".@@@@@@.", 
		"...@@...", 
		"...@@...", 
		"@@@@@@@@", 
	], 
	"left": [
		"....@@..", 
		"...@@@..", 
		"..@@@@..", 
		".@@@@@@.", 
		"@@@@@@@@", 
		".@@@@@@.", 
		"..@@@@..", 
		"...@@@..", 
	], 
	"right": [
		"..@@....", 
		"..@@@...", 
		"..@@@@..", 
		".@@@@@@.", 
		"@@@@@@@@", 
		".@@@@@@.", 
		"..@@@@..", 
		"..@@@...", 
	], 
	"interact": [
		".@@@@@@.", 
		"@......@", 
		"@..@@..@", 
		"@..@@..@", 
		"@......@", 
		"@..@@..@", 
		".@@@@@@.", 
		"...@@...", 
	], 
}

func _refresh_colors() -> void :
	match mode:
		Mode.DASH: _base_color = PixelArt.CYAN
		Mode.JUMP: _base_color = Color(0.68, 0.32, 1.0)
		Mode.LEFT: _base_color = PixelArt.PINK
		Mode.RIGHT: _base_color = PixelArt.ORANGE
		Mode.INTERACT: _base_color = PixelArt.YELLOW

	_color = _base_color
	if reverse_style:
		_color = _color.inverted()

func _rest_solid() -> bool:

	if mode == Mode.INTERACT:
		return not hold_solid
	if mode == Mode.LEFT or mode == Mode.RIGHT:
		return not hold_solid
	return start_solid

func _ready() -> void :
	_refresh_colors()
	_solid = _rest_solid()
	_display_alpha = 1.0 if _solid else 0.0

	if Engine.is_editor_hint():

		queue_redraw()
		return

	add_to_group("neon_blocks")
	collision_layer = 1
	collision_mask = 0

	var shape: = RectangleShape2D.new()
	shape.size = block_size * PixelArt.SCALE
	_collision_shape = CollisionShape2D.new()
	_collision_shape.shape = shape
	add_child(_collision_shape)

	_solid_sprite = Sprite2D.new()
	_solid_sprite.centered = true
	add_child(_solid_sprite)
	_build_ghost_overlay()

	_apply_state(false)


	var key: = _texture_key()
	if _tex_cache.has(key):
		var cached: Array = _tex_cache[key]
		_tex_solid = cached[0]
		_tex_ghost = cached[1]
		_apply_state(false)
		return

	if _tex_pending.has(key):
		while not _tex_cache.has(key):
			await get_tree().process_frame
			if not is_instance_valid(self):
				return
		var cached: Array = _tex_cache[key]
		_tex_solid = cached[0]
		_tex_ghost = cached[1]
		_apply_state(false)
		return

	_tex_pending[key] = true

	for i in range(3):
		await get_tree().process_frame
	var bsize: = Vector2i(block_size * PixelArt.SCALE + Vector2(BAKE_MARGIN * 2.0, BAKE_MARGIN * 2.0))
	_tex_solid = await PixelArt.bake_texture(_bake_solid, bsize, self)
	for i in range(2):
		await get_tree().process_frame
	_tex_ghost = await PixelArt.bake_texture(_bake_ghost, bsize, self)
	_tex_cache[key] = [_tex_solid, _tex_ghost]
	_tex_pending.erase(key)
	_apply_state(false)

func _bake_solid(ci: CanvasItem) -> void :
	var s: = PixelArt.SCALE
	ci.draw_set_transform(Vector2(block_size.x * s * 0.5 + BAKE_MARGIN, block_size.y * s * 0.5 + BAKE_MARGIN), 0.0, Vector2.ONE)
	_draw_solid_art(ci)


func _draw_solid_art(ci: CanvasItem) -> void :
	var s: = PixelArt.SCALE
	PixelArt.neon_panel(ci, Rect2( - block_size / 2.0, block_size), _color, true, 1.0)
	if reverse_style:

		var inner: = Rect2( - block_size * s / 2.0, block_size * s).grow(-10.0)
		ci.draw_rect(inner, Color(_color.r, _color.g, _color.b, 0.45))
		_draw_diagonal_stripes(ci, inner, Color(0.02, 0.02, 0.03, 0.16), 14.0, 52.0)
		_draw_corner_cuts(ci, inner, Color(0.02, 0.02, 0.03, 0.32), 42.0)
		ci.draw_rect(inner.grow(-12.0), Color(0.02, 0.02, 0.03, 0.55), false, 4.0)
	var icon_src: = _base_color
	var lift: = 0.25
	if reverse_style:

		icon_src = _color
		lift = 0.4
	var icon_col: = Color(min(1.0, icon_src.r + lift), min(1.0, icon_src.g + lift), min(1.0, icon_src.b + lift))
	PixelArt.draw_icon(ci, "\n".join(ICONS[_icon_key()]), icon_col, Vector2.ZERO, 4, 1.0)

func _bake_ghost(ci: CanvasItem) -> void :

	var s: = PixelArt.SCALE


	ci.draw_set_transform(Vector2(block_size.x * s * 0.5 + BAKE_MARGIN, block_size.y * s * 0.5 + BAKE_MARGIN), 0.0, Vector2.ONE)
	var r: = Rect2( - block_size * s / 2.0, block_size * s)
	_draw_ghost_frame(ci, r, Color(_color.r, _color.g, _color.b))


	var icon_col: = Color(_color.r, _color.g, _color.b)
	PixelArt.draw_icon(ci, "\n".join(ICONS[_icon_key()]), icon_col, Vector2.ZERO, 3, 0.14)


func _draw_ghost_frame(ci: CanvasItem, r: Rect2, col: Color) -> void :
	ci.draw_rect(r, Color(col.r, col.g, col.b, 0.03))


	for i in range(8):
		var e: = 4.0 + i * 9.0
		var a: = 0.34 * pow(0.74, i)
		ci.draw_rect(r.grow(e), Color(col.r, col.g, col.b, a), false, 26.0)

	if reverse_style:

		_draw_diagonal_stripes(ci, r.grow(-14.0), Color(col.r, col.g, col.b, 0.08), 10.0, 46.0)
		var inner: = r.grow(-30.0)
		var inner_col: = Color(col.r, col.g, col.b, 0.55)
		_draw_dashed_line(ci, inner.position, Vector2(inner.end.x, inner.position.y), inner_col, 8.0, 28.0, 20.0)
		_draw_dashed_line(ci, Vector2(inner.end.x, inner.position.y), inner.end, inner_col, 8.0, 28.0, 20.0)
		_draw_dashed_line(ci, inner.end, Vector2(inner.position.x, inner.end.y), inner_col, 8.0, 28.0, 20.0)
		_draw_dashed_line(ci, Vector2(inner.position.x, inner.end.y), inner.position, inner_col, 8.0, 28.0, 20.0)
	else:
		var step: = 56.0
		var yy: = r.position.y + 28.0
		while yy < r.end.y - 20.0:
			var xx: = r.position.x + 28.0
			while xx < r.end.x - 20.0:
				ci.draw_circle(Vector2(xx, yy), 3.5, Color(col.r, col.g, col.b, 0.1))
				xx += step
			yy += step

	var border: = Color(col.r, col.g, col.b, 0.95)
	_draw_dashed_line(ci, r.position, Vector2(r.end.x, r.position.y), border, 18.0, 46.0, 30.0)
	_draw_dashed_line(ci, Vector2(r.end.x, r.position.y), r.end, border, 18.0, 46.0, 30.0)
	_draw_dashed_line(ci, r.end, Vector2(r.position.x, r.end.y), border, 18.0, 46.0, 30.0)
	_draw_dashed_line(ci, Vector2(r.position.x, r.end.y), r.position, border, 18.0, 46.0, 30.0)

func _draw_dashed_line(ci: CanvasItem, from: Vector2, to: Vector2, color: Color, width: float, dash: float, gap: float) -> void :
	var total: = from.distance_to(to)
	if total <= gap * 2.0:
		return
	var dir: = (to - from) / total

	var t: = gap
	var end: = total - gap
	while t < end:
		var seg: = minf(dash, end - t)
		ci.draw_line(from + dir * t, from + dir * (t + seg), color, width)
		t += dash + gap


func _draw_diagonal_stripes(ci: CanvasItem, r: Rect2, color: Color, width: float, spacing: float) -> void :
	var c: = r.position.y - r.end.x
	var c_end: = r.end.y - r.position.x
	while c < c_end:
		var pts: Array[Vector2] = []
		var y: = r.position.x + c
		if y >= r.position.y and y <= r.end.y:
			pts.append(Vector2(r.position.x, y))
		y = r.end.x + c
		if y >= r.position.y and y <= r.end.y:
			pts.append(Vector2(r.end.x, y))
		var x: = r.position.y - c
		if x >= r.position.x and x <= r.end.x:
			pts.append(Vector2(x, r.position.y))
		x = r.end.y - c
		if x >= r.position.x and x <= r.end.x:
			pts.append(Vector2(x, r.end.y))
		if pts.size() >= 2 and pts[0].distance_to(pts[1]) > 1.0:
			ci.draw_line(pts[0], pts[1], color, width)
		c += spacing


func _draw_corner_cuts(ci: CanvasItem, r: Rect2, color: Color, size: float) -> void :
	var p: = r.position
	var e: = r.end
	var tris: = [
		PackedVector2Array([p, p + Vector2(size, 0.0), p + Vector2(0.0, size)]), 
		PackedVector2Array([Vector2(e.x, p.y), Vector2(e.x - size, p.y), Vector2(e.x, p.y + size)]), 
		PackedVector2Array([Vector2(p.x, e.y), Vector2(p.x + size, e.y), Vector2(p.x, e.y - size)]), 
		PackedVector2Array([e, e + Vector2( - size, 0.0), e + Vector2(0.0, - size)]), 
	]
	for t in tris:
		ci.draw_colored_polygon(t, color)

func _build_ghost_overlay() -> void :

	_scan = Sprite2D.new()
	_scan.name = "GhostScan"
	_scan.centered = true
	var scan_mat: = CanvasItemMaterial.new()
	scan_mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_scan.material = scan_mat
	_scan.visible = false
	_scan.texture = _make_scan_texture()
	add_child(_scan)


	_phase_fx = CPUParticles2D.new()
	_phase_fx.name = "PhaseFX"
	_phase_fx.amount = 20
	_phase_fx.one_shot = true
	_phase_fx.explosiveness = 1.0
	_phase_fx.lifetime = 0.5
	_phase_fx.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	_phase_fx.emission_sphere_radius = 170.0
	_phase_fx.spread = 180.0
	_phase_fx.initial_velocity_min = 50.0
	_phase_fx.initial_velocity_max = 190.0
	_phase_fx.gravity = Vector2.ZERO
	_phase_fx.scale_amount_min = 4.0
	_phase_fx.scale_amount_max = 10.0
	_phase_fx.color = Color(_color.r, _color.g, _color.b, 0.55)
	_phase_fx.emitting = false
	add_child(_phase_fx)

func _make_scan_texture() -> Texture2D:
	var key: = _color.to_html()
	if _scan_cache.has(key):
		return _scan_cache[key]
	var c: = Color(minf(1.0, _color.r + 0.3), minf(1.0, _color.g + 0.3), minf(1.0, _color.b + 0.3), 0.0)
	var g: = Gradient.new()
	g.set_color(0, c)
	g.set_color(1, c)
	g.add_point(0.5, Color(c.r, c.g, c.b, 0.55))
	var t: = GradientTexture2D.new()
	t.gradient = g
	t.width = 380
	t.height = 26
	t.fill_from = Vector2(0, 0)
	t.fill_to = Vector2(0, 1)
	_scan_cache[key] = t
	return t

func _texture_key() -> String:
	return "%d|%s|%s" % [mode, str(reverse_style), str(block_size)]

func _update_ghost_visuals() -> void :
	if _solid:
		_solid_sprite.modulate = Color(1, 1, 1, 1)
		if _scan:
			_scan.visible = false
		return

	var breathe: = 0.84 + 0.08 * sin(_pulse * 3.6)
	_solid_sprite.modulate = Color(1, 1, 1, breathe)
	if _scan:
		_scan.visible = true
		var scan_y: = -200.0 + fmod(_pulse * 170.0, 400.0)
		_scan.position = Vector2(0, scan_y)
		_scan.modulate = Color(1, 1, 1, 0.5 + 0.15 * sin(_pulse * 7.0))

func _burst() -> void :
	if _phase_fx:
		_phase_fx.restart()

func _icon_key() -> String:
	match mode:
		Mode.DASH: return "dash"
		Mode.JUMP: return "jump"
		Mode.LEFT: return "left"
		Mode.RIGHT: return "right"
		Mode.INTERACT: return "interact"
	return "dash"

func _physics_process(delta: float) -> void :
	if Engine.is_editor_hint():
		return

	var player: = get_tree().get_first_node_in_group("player")
	var can_recover: = false
	if player and not player.is_dead and not player.dialogue_locked and not player.is_on_floor():
		_airborne_time += delta
		can_recover = _airborne_time >= STUCK_AIR_RECOVERY_TIME and global_position.distance_to(player.global_position) <= STUCK_RECOVERY_RANGE
	else:
		_airborne_time = 0.0
	if can_recover:
		if mode == Mode.JUMP and Input.is_action_just_pressed("jump"):
			_toggle()
		elif mode == Mode.DASH and Input.is_action_just_pressed("dash"):
			_toggle()
	_pulse += delta

	match mode:
		Mode.DASH, Mode.JUMP:

			pass
		Mode.LEFT, Mode.RIGHT, Mode.INTERACT:
			var action: = "interact"
			if mode == Mode.LEFT:
				action = "move_left"
			elif mode == Mode.RIGHT:
				action = "move_right"
			var held: = Input.is_action_pressed(action)
			var want: bool
			if mode == Mode.INTERACT:

				want = held if hold_solid else ( not held)
			else:
				want = held if hold_solid else ( not held)
			if want != _solid:
				_solid = want
				if not _solid:
					_burst()
				_apply_state(true)




	var target: float = 1.0 if _solid else 0.0
	_display_alpha = move_toward(_display_alpha, target, delta * 8.0)
	var a: = clampf(_display_alpha, 0.0, 1.0)
	if _solid and _tex_solid:
		_solid_sprite.texture = _tex_solid
	elif not _solid and _tex_ghost:
		_solid_sprite.texture = _tex_ghost
	_update_ghost_visuals()
	var pulse: = 1.0 + sin(_pulse * 3.0) * 0.025
	var solid_scale: = pulse
	var ghost_scale: = 0.92
	var s: = lerpf(ghost_scale, solid_scale, a)
	_solid_sprite.scale = Vector2(s, s)

func _toggle() -> void :
	var now: = Time.get_ticks_msec()
	if now - _last_toggle_ms < TOGGLE_DEBOUNCE_MS:
		return
	_last_toggle_ms = now
	_solid = not _solid
	if not _solid:
		_burst()
	_apply_state(true)

func _on_player_jumped() -> void :
	if mode == Mode.JUMP:
		_toggle()

func _on_player_dashed() -> void :
	if mode == Mode.DASH:
		_toggle()

func _apply_state(with_anim: bool) -> void :
	if _collision_shape:
		_collision_shape.disabled = not _solid
	collision_layer = 1 if _solid else 0
	if not with_anim:
		_display_alpha = 1.0 if _solid else 0.0

	if _solid and _tex_solid:
		_solid_sprite.texture = _tex_solid
	elif not _solid and _tex_ghost:
		_solid_sprite.texture = _tex_ghost


	queue_redraw()
	if _scan:
		_update_ghost_visuals()

func _draw() -> void :

	if _tex_solid and _tex_ghost:
		return
	var s: = PixelArt.SCALE
	if _solid:
		_draw_solid_art(self)
	else:

		var r: = Rect2( - block_size.x * s / 2.0, - block_size.y * s / 2.0, block_size.x * s, block_size.y * s)
		_draw_ghost_frame(self, r, Color(_color.r, _color.g, _color.b))

		_draw_icon_for_mode(0.14, 3)

func _draw_icon_for_mode(alpha: float, px: int = 4) -> void :
	var icon_col: = Color(min(1.0, _color.r + 0.25), min(1.0, _color.g + 0.25), min(1.0, _color.b + 0.25))
	PixelArt.draw_icon(self, "\n".join(ICONS[_icon_key()]), icon_col, Vector2.ZERO, px, alpha)
