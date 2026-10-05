extends Node2D


var target: Node2D

var follow_offset: = Vector2(-30, -440)
var text_scale: = 2.25
var font_size: = 32
var type_speed: = 0.08
var hold_after_type: = 0.6
var fade_duration: = 0.5

var _t: = 0.0
var _full_text: = ""
var _label: Label
var _type_done_at: = 0.0

func setup(p: Node2D, text: String) -> void :
	target = p
	_full_text = text
	_label = Label.new()
	_label.name = "L"
	_label.text = ""
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", font_size)
	_label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.7))
	_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	_label.add_theme_constant_override("shadow_offset_x", 2)
	_label.add_theme_constant_override("shadow_offset_y", 2)
	add_child(_label)
	scale = Vector2(text_scale, text_scale)

func _process(delta: float) -> void :
	_t += delta
	if is_instance_valid(target):
		global_position = target.global_position + follow_offset

	var n: = int(_t / type_speed)
	n = clampi(n, 0, _full_text.length())
	var new_text: = _full_text.substr(0, n)
	if new_text != _label.text:
		_label.text = new_text
		_label.reset_size()
		_label.position = - _label.size / 2

	if n >= _full_text.length() and _type_done_at == 0.0:
		_type_done_at = _t

	var alpha: = 1.0
	if _type_done_at > 0.0:
		var fade_t: = _t - _type_done_at - hold_after_type
		if fade_t > 0.0:
			alpha = clampf(1.0 - fade_t / fade_duration, 0.0, 1.0)
			if alpha <= 0.0:
				queue_free()
	modulate.a = alpha
