extends Node2D


var player: Node = null
var hat_style: String = "party"
var outfit_style: String = "scarf"
var tint_style: String = "warm"

func _process(_delta: float) -> void :
	queue_redraw()

func set_outfit(hat: String, outfit: String, tint: String) -> void :
	hat_style = hat
	outfit_style = outfit
	tint_style = tint
	queue_redraw()

func _draw() -> void :
	if player == null or not is_instance_valid(player):
		return
	var head: = player.get_node_or_null("Sprite2D11") as Sprite2D
	if head == null:
		return
	var center: = get_viewport().get_canvas_transform() * head.global_position
	var f: = 1 if player.facing_right else -1
	var hat_offset: = -64.0 if hat_style == "flower" else -50.0
	draw_set_transform(center + Vector2(0, hat_offset), 0.0, Vector2(f, 1))

	if hat_style == "party":
		draw_colored_polygon(PackedVector2Array([Vector2(-13, -19), Vector2(13, -19), Vector2(2, -48)]), Color(0.96, 0.44, 0.6))
		draw_line(Vector2(-13, -19), Vector2(2, -48), Color(1.0, 0.85, 0.65, 0.8), 1.2)
		draw_line(Vector2(13, -19), Vector2(2, -48), Color(1.0, 0.85, 0.65, 0.8), 1.2)
		draw_circle(Vector2(2, -49), 3.5, Color(1.0, 0.86, 0.55))
	elif hat_style == "crown":
		draw_colored_polygon(PackedVector2Array([
			Vector2(-15, -21), Vector2(-12, -38), Vector2(-7, -28), 
			Vector2(-1, -42), Vector2(4, -28), Vector2(10, -38), 
			Vector2(14, -21), Vector2(10, -18), Vector2(-11, -18)
		]), Color(1.0, 0.82, 0.36))
		for p in [Vector2(-12, -36), Vector2(-1, -40), Vector2(10, -36)]:
			draw_circle(p, 2.2, Color(1.0, 0.45, 0.55))
	elif hat_style == "flower":
		for i in range(7):
			var x: = -16.0 + i * 5.3
			var y: = -20.0 + sin(i * 1.7) * 2.0
			var c: Color = [Color(1.0, 0.55, 0.7), Color(1.0, 0.8, 0.5), Color(0.7, 0.6, 1.0)][i % 3]
			for k in range(5):
				var a: = TAU * float(k) / 5.0
				draw_circle(Vector2(x + cos(a) * 2.6, y + sin(a) * 2.6), 2.0, c)
			draw_circle(Vector2(x, y), 1.6, Color(1.0, 0.94, 0.65))
	if outfit_style == "scarf":
		draw_set_transform(center + Vector2(0, -17), 0.0, Vector2(f, 1))
		draw_colored_polygon(PackedVector2Array([Vector2(-14, 3), Vector2(14, 2), Vector2(15, 9), Vector2(-14, 11)]), Color(0.56, 0.4, 0.95, 0.92))
		draw_colored_polygon(PackedVector2Array([Vector2(9, 8), Vector2(17, 19), Vector2(12, 22), Vector2(5, 11)]), Color(0.48, 0.32, 0.86, 0.88))
	elif outfit_style == "bow":
		draw_set_transform(center + Vector2(0, -17), 0.0, Vector2(f, 1))
		draw_colored_polygon(PackedVector2Array([Vector2(0, 6), Vector2(-14, -1), Vector2(-13, 12)]), Color(1.0, 0.55, 0.68))
		draw_colored_polygon(PackedVector2Array([Vector2(0, 6), Vector2(13, -1), Vector2(12, 12)]), Color(1.0, 0.55, 0.68))
		draw_circle(Vector2(0, 6), 3.2, Color(1.0, 0.78, 0.55))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
