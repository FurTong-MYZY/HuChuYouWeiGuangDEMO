extends Area2D


const SAVE_PATH: = "user://progress.cfg"
const BIRTHDAY_SCENE: = "res://birthday.tscn"
const ANNOUNCEMENT: = "恭喜通关Chapter4!!!感谢游玩OwO \n 11.12是Demo Ultra的发布日，也是作者的生日。在此，为你献上一份特别DLC——"

var triggered: bool = false
var _t: float = 0.0

func _ready() -> void :
	collision_layer = 0
	collision_mask = 3
	monitoring = true
	z_index = 30
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void :
	_t += delta
	queue_redraw()

func _draw() -> void :
	var pulse: = 0.5 + 0.5 * sin(_t * 2.2)
	var c: = Color(1.0, 0.82, 0.42)

	draw_circle(Vector2.ZERO, 120.0, Color(c.r, c.g, c.b, 0.035 + pulse * 0.02))
	for i in range(3):
		var r: = 54.0 + i * 26.0
		draw_arc(Vector2.ZERO, r, 0, TAU, 64, Color(c.r, c.g, c.b, 0.24 - i * 0.05), 2.0)
	var pts: = PackedVector2Array([
		Vector2(0, -84), Vector2(30, 0), Vector2(0, 84), Vector2(-30, 0)
	])
	draw_colored_polygon(pts, Color(c.r, c.g, c.b, 0.92))
	draw_colored_polygon(PackedVector2Array([
		Vector2(0, -46), Vector2(16, 0), Vector2(0, 46), Vector2(-16, 0)
	]), Color(1.0, 0.97, 0.82, 0.95))
	for i in range(8):
		var a: = _t * 0.5 + TAU * float(i) / 8.0
		draw_circle(Vector2(cos(a) * (80.0 + 10.0 * sin(_t + i)), sin(a) * (80.0 + 10.0 * sin(_t + i))), 2.0, Color(1.0, 0.9, 0.58, 0.7))

func _on_body_entered(body: Node) -> void :
	if triggered or not body.is_in_group("player"):
		return
	triggered = true
	body.dialogue_locked = true
	body.is_invincible = true
	body.invincible_timer = 999.0
	var pui = body.get_node_or_null("PlayerUI")
	if pui:
		pui.visible = false
	var danger = body.get_node_or_null("DangerLayer")
	if danger:
		danger.visible = false
	var version = get_node_or_null("/root/VersionTag")
	if version:
		version.visible = false
	var cfg: = ConfigFile.new()
	cfg.load(SAVE_PATH)
	cfg.set_value("unlocked", "birthday_dlc", true)
	cfg.save(SAVE_PATH)
	_show_announcement()

func _show_announcement() -> void :
	var layer: = CanvasLayer.new()
	layer.layer = 90
	add_child(layer)
	var dim: = ColorRect.new()
	dim.color = Color(0.015, 0.01, 0.03, 0.0)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(dim)
	var panel: = PanelContainer.new()
	panel.position = Vector2(150, 180)
	panel.custom_minimum_size = Vector2(852, 260)
	var style: = StyleBoxFlat.new()
	style.bg_color = Color(0.055, 0.025, 0.08, 0.94)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = Color(1.0, 0.68, 0.38, 0.65)
	style.set_corner_radius_all(8)
	style.shadow_color = Color(0, 0, 0, 0.5)
	style.shadow_size = 18
	panel.add_theme_stylebox_override("panel", style)
	layer.add_child(panel)
	var margin: = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 36)
	margin.add_theme_constant_override("margin_right", 36)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	panel.add_child(margin)
	var box: = VBoxContainer.new()
	box.add_theme_constant_override("separation", 11)
	margin.add_child(box)
	var kicker: = Label.new()
	kicker.text = "DEMO ULTRA Chapter 4/  COMPLETE"
	kicker.add_theme_font_override("font", load("res://fonts/TitleFont.ttf"))
	kicker.add_theme_font_size_override("font_size", 12)
	kicker.add_theme_color_override("font_color", Color(1.0, 0.62, 0.48, 0.8))
	box.add_child(kicker)
	var text: = Label.new()
	text.text = ANNOUNCEMENT
	text.add_theme_font_override("font", load("res://fonts/TitleFont.ttf"))
	text.add_theme_font_size_override("font_size", 23)
	text.add_theme_color_override("font_color", Color(1.0, 0.9, 0.7))
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.custom_minimum_size = Vector2(780, 90)
	box.add_child(text)
	var tip: = Label.new()
	tip.text = "BIRTHDAY SPECIAL  /  11.12"
	tip.add_theme_font_override("font", load("res://fonts/TitleFont.ttf"))
	tip.add_theme_font_size_override("font_size", 13)
	tip.add_theme_color_override("font_color", Color(0.8, 0.68, 1.0, 0.8))
	box.add_child(tip)
	var fade: = ColorRect.new()
	fade.color = Color(0.01, 0.0, 0.015, 0.0)
	fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(fade)
	var tw: = create_tween()
	tw.tween_property(dim, "color:a", 0.86, 0.35)
	tw.tween_method( func(n: float) -> void : text.visible_characters = int(n), 0.0, float(ANNOUNCEMENT.length()), 2.8)
	tw.tween_interval(3.0)
	tw.tween_property(fade, "color:a", 1.0, 0.8)
	tw.tween_callback(_go_birthday)

func _go_birthday() -> void :
	get_tree().change_scene_to_file(BIRTHDAY_SCENE)
