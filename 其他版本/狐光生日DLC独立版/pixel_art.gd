class_name PixelArt




const SCALE: = 8.0


const CYAN: = Color(0.22, 0.95, 1.0)
const PINK: = Color(1.0, 0.2, 0.62)
const GREEN: = Color(0.35, 1.0, 0.35)
const ORANGE: = Color(1.0, 0.55, 0.1)
const YELLOW: = Color(1.0, 0.9, 0.3)
const PURPLE: = Color(0.68, 0.25, 1.0)
const RED: = Color(1.0, 0.28, 0.28)
const WHITE: = Color(1.0, 1.0, 1.0)
const METAL_DARK: = Color(0.07, 0.08, 0.14)
const METAL_MID: = Color(0.13, 0.15, 0.24)
const METAL_LIGHT: = Color(0.22, 0.25, 0.38)


static func pixel(ci: CanvasItem, pos: Vector2, size: int, color: Color, px: int = 4) -> void :
	var u: = px * SCALE
	ci.draw_rect(Rect2(pos * u, Vector2(u, u) * size), color)


static func draw_pixel_grid(ci: CanvasItem, grid: Array, palette: Dictionary, origin: Vector2, px: int = 4) -> void :
	var u: = px * SCALE
	for y in range(grid.size()):
		var row: String = str(grid[y])
		for x in range(row.length()):
			var ch: = row[x]
			if palette.has(ch):
				ci.draw_rect(Rect2(origin * SCALE + Vector2(x, y) * u, Vector2(u, u)), palette[ch])


static func neon_panel(ci: CanvasItem, rect: Rect2, glow: Color, filled: bool, alpha: float = 1.0) -> void :
	var s: = SCALE
	var r: = Rect2(rect.position * s, rect.size * s)
	if filled:
		var g: = [0.1, 0.16, 0.26]
		for i in range(3):
			var e: float = (3.0 + (2 - i) * 2.0) * s
			var c: = Color(glow.r, glow.g, glow.b, g[i] * alpha)
			ci.draw_rect(Rect2(r.position - Vector2(e, e), r.size + Vector2(e * 2, e * 2)), c)
		var body: = Color(glow.r * 0.45, glow.g * 0.5, glow.b * 0.62, 0.92 * alpha)
		ci.draw_rect(r, body)
		ci.draw_rect(Rect2(r.position + Vector2(2 * s, 2 * s), Vector2(r.size.x - 4 * s, 3 * s)), Color(glow.r, glow.g, glow.b, 0.35 * alpha))
		var border: = glow
		ci.draw_rect(r, Color(border.r, border.g, border.b, alpha), false, 2.0 * s)
	else:
		var dash: = Color(glow.r, glow.g, glow.b, 0.18 * alpha)
		var w: = r.size.x
		var h: = r.size.y
		var corners: = [r.position, r.position + Vector2(w, 0), r.position + Vector2(0, h), r.position + Vector2(w, h)]
		for c in corners:
			ci.draw_circle(c, 2.5 * s, dash)
		var step: = 12.0 * s
		var seg_len: = 5.0 * s
		var thick: = 1.5 * s
		for xx in range(0.0, w, step):
			ci.draw_rect(Rect2(r.position + Vector2(xx, 0), Vector2(seg_len, thick)), dash)
			ci.draw_rect(Rect2(r.position + Vector2(xx, h - thick), Vector2(seg_len, thick)), dash)
		for yy in range(0.0, h, step):
			ci.draw_rect(Rect2(r.position + Vector2(0, yy), Vector2(thick, seg_len)), dash)
			ci.draw_rect(Rect2(r.position + Vector2(w - thick, yy), Vector2(thick, seg_len)), dash)


static func draw_icon(ci: CanvasItem, icon: String, color: Color, center: Vector2, px: int = 4, alpha: float = 1.0) -> void :
	var rows: Array = Array(icon.split("\n"))
	while rows.size() > 0 and str(rows[0]).strip_edges() == "":
		rows.pop_front()
	while rows.size() > 0 and str(rows[-1]).strip_edges() == "":
		rows.pop_back()
	var h: int = rows.size()
	var w: int = 0
	for r in rows:
		w = max(w, str(r).length())
	var u: = px * SCALE
	var origin: = center * SCALE - Vector2(w * u / 2.0, h * u / 2.0)
	var palette: = {"@": Color(color.r, color.g, color.b, alpha), ".": Color(color.r, color.g, color.b, 0.45 * alpha)}
	var grid_ci: = ci
	for y in range(rows.size()):
		var row: String = str(rows[y])
		for x in range(row.length()):
			var ch: = row[x]
			if palette.has(ch):
				ci.draw_rect(Rect2(origin + Vector2(x, y) * u, Vector2(u, u)), palette[ch])


static func draw_glow(ci: CanvasItem, center: Vector2, radius_art: float, color: Color, alpha: float = 0.3) -> void :
	var r: = radius_art * SCALE
	var layers: = 4
	for i in range(layers):
		var t: = float(i) / float(layers)
		var rr: = r * (1.0 - t * 0.5)
		var a: = alpha * (1.0 - t) * 0.5
		ci.draw_circle(center * SCALE, rr, Color(color.r, color.g, color.b, a))



class BakeCanvas:
	extends Node2D
	var fn: Callable
	func _draw() -> void :
		if fn.is_valid():
			fn.call(self)




static func bake_texture(draw_fn: Callable, size: Vector2i, host: Node) -> Texture2D:
	if DisplayServer.get_name() == "headless":
		return null
	var vp: = SubViewport.new()
	vp.size = size
	vp.transparent_bg = true
	vp.disable_3d = true
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	var c: = BakeCanvas.new()
	c.fn = draw_fn
	vp.add_child(c)
	host.add_child(vp)
	for i in range(3):
		if not is_instance_valid(host) or host.get_tree() == null:
			if is_instance_valid(vp):
				vp.queue_free()
			return null
		await host.get_tree().process_frame
	if not is_instance_valid(host) or not is_instance_valid(vp):
		return null
	var out: Texture2D = null
	var tex: = vp.get_texture()
	if tex != null:
		var img: = tex.get_image()
		if img != null and img.get_width() > 0:
			out = ImageTexture.create_from_image(img)
	vp.queue_free()
	return out
