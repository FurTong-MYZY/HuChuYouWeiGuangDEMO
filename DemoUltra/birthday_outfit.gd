extends Node2D


var player: CharacterBody2D

func _draw() -> void :
	if player == null:
		return
	var f: int = player.facing
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(f, 1))
	match player.hat_style:
		"party":
			_draw_party_hat()
		"crown":
			_draw_crown()
		"flower":
			_draw_flower_crown()
	match player.outfit_style:
		"scarf":
			_draw_scarf()
		"bow":
			_draw_bow()
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_party_hat() -> void :
	var base_y: = -105.0
	draw_colored_polygon(PackedVector2Array([
		Vector2(-15, base_y), Vector2(16, base_y), Vector2(3, -140)
	]), Color(0.96, 0.44, 0.6))
	draw_colored_polygon(PackedVector2Array([
		Vector2(-4, base_y), Vector2(2, base_y), Vector2(3, -133)
	]), Color(1.0, 0.76, 0.5, 0.9))
	draw_line(Vector2(-15, base_y), Vector2(3, -140), Color(1.0, 0.85, 0.65, 0.8), 1.4)
	draw_line(Vector2(16, base_y), Vector2(3, -140), Color(1.0, 0.85, 0.65, 0.8), 1.4)
	draw_circle(Vector2(3, -141), 4.2, Color(1.0, 0.86, 0.55))
	draw_circle(Vector2(3, -141), 2.0, Color(1.0, 0.98, 0.8))

func _draw_crown() -> void :
	var y: = -106.0
	var pts: = PackedVector2Array([
		Vector2(-16, y), Vector2(-13, -128), Vector2(-8, y - 10), 
		Vector2(-2, -132), Vector2(3, y - 11), Vector2(9, -129), 
		Vector2(14, y), Vector2(10, y + 4), Vector2(-11, y + 4)
	])
	draw_colored_polygon(pts, Color(1.0, 0.82, 0.36))
	draw_polyline(PackedVector2Array([
		Vector2(-16, y), Vector2(-13, -128), Vector2(-8, y - 10), 
		Vector2(-2, -132), Vector2(3, y - 11), Vector2(9, -129), 
		Vector2(14, y)
	]), Color(1.0, 0.95, 0.7), 1.4)
	for p in [Vector2(-13, -126), Vector2(-2, -130), Vector2(9, -127)]:
		draw_circle(p, 2.5, Color(1.0, 0.45, 0.55))
	draw_circle(Vector2(-4, -112), 7.0, Color(0.55, 0.45, 1.0, 0.25))

func _draw_flower_crown() -> void :
	var colors: = [Color(1.0, 0.55, 0.7), Color(1.0, 0.8, 0.5), Color(0.7, 0.6, 1.0), Color(1.0, 0.9, 0.7)]
	for i in range(7):
		var x: = -18.0 + i * 6.0
		var y: = -104.0 + sin(i * 1.7) * 2.0
		var c: Color = colors[i % colors.size()]
		for k in range(5):
			var a: = TAU * float(k) / 5.0
			draw_circle(Vector2(x + cos(a) * 3.0, y + sin(a) * 3.0), 2.4, c)
		draw_circle(Vector2(x, y), 2.0, Color(1.0, 0.94, 0.65))
	draw_line(Vector2(-20, -103), Vector2(20, -103), Color(0.55, 0.8, 0.55, 0.75), 1.4)

func _draw_scarf() -> void :
	var y: = -68.0
	draw_colored_polygon(PackedVector2Array([
		Vector2(-17, y), Vector2(19, y - 2), Vector2(20, y + 7), Vector2(-17, y + 9)
	]), Color(0.56, 0.4, 0.95, 0.92))
	var pts: = PackedVector2Array([
		Vector2(12, y + 5), Vector2(22, y + 16), Vector2(16, y + 20), Vector2(7, y + 9)
	])
	draw_colored_polygon(pts, Color(0.48, 0.32, 0.86, 0.88))
	draw_line(Vector2(-17, y + 2), Vector2(19, y + 1), Color(1.0, 0.8, 0.6, 0.55), 1.0)
	draw_circle(Vector2(-16, y + 4), 2.0, Color(1.0, 0.85, 0.58))

func _draw_bow() -> void :
	var c: = Vector2(2, -68)
	draw_colored_polygon(PackedVector2Array([
		c + Vector2(-2, 0), c + Vector2(-17, -8), c + Vector2(-16, 8)
	]), Color(1.0, 0.55, 0.68, 0.92))
	draw_colored_polygon(PackedVector2Array([
		c + Vector2(2, 0), c + Vector2(16, -8), c + Vector2(15, 8)
	]), Color(1.0, 0.55, 0.68, 0.92))
	draw_circle(c, 4.0, Color(1.0, 0.78, 0.55))
	draw_circle(c, 2.0, Color(1.0, 0.9, 0.7))
