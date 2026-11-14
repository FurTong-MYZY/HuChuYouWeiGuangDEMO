extends Node2D
class_name Spark



static var _cached_tex: Texture2D = null

var _color: Color = Color.WHITE
var _life: float = 0.28
var _age: float = 0.0
var _sprite: Sprite2D

func setup(color: Color, count: int = 10, spread: float = 70.0) -> void :
	_color = color

	if _sprite:
		_sprite.modulate = _color

	queue_redraw()

func _ready() -> void :
	_sprite = Sprite2D.new()
	_sprite.centered = true
	_sprite.modulate = _color
	var m: = CanvasItemMaterial.new()
	m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_sprite.material = m
	add_child(_sprite)
	if _cached_tex == null:
		_cached_tex = await PixelArt.bake_texture(_bake, Vector2i(48 * PixelArt.SCALE, 48 * PixelArt.SCALE), self)
	if _cached_tex:
		_sprite.texture = _cached_tex
		var tw: = create_tween()
		tw.set_parallel(true)
		tw.tween_property(_sprite, "scale", Vector2(1.7, 1.7), _life).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(_sprite, "modulate:a", 0.0, _life)
		tw.chain().tween_callback(queue_free)
	else:
		queue_redraw()

func _bake(ci: CanvasItem) -> void :
	var s: = PixelArt.SCALE
	ci.draw_set_transform(Vector2(24 * s, 24 * s), 0.0, Vector2(s, s))
	ci.draw_circle(Vector2.ZERO, 10.0, Color(1, 1, 1, 0.8))

	for i in range(12):
		var ang: = TAU * i / 12.0
		var r: = 8.0 + (i % 3) * 5.0
		ci.draw_circle(Vector2(cos(ang), sin(ang)) * r, 3.0, Color(1, 1, 1, 0.9))

func _physics_process(delta: float) -> void :
	_age += delta

	if _cached_tex == null and _age >= 1.0:
		queue_free()
	elif _cached_tex == null:
		queue_redraw()

func _draw() -> void :

	if _cached_tex:
		return
	var t: float = _age / _life
	var s: = PixelArt.SCALE
	var flash: float = max(0.0, 1.0 - t * 3.0)
	draw_circle(Vector2.ZERO, (10.0 * flash + 2.0) * s, Color(1, 1, 1, flash * 0.8))
	for i in range(12):
		var ang: = TAU * i / 12.0
		var r: = (8.0 + (i % 3) * 5.0) * (1.0 - t) * s
		var a: float = clamp(1.0 - t, 0.0, 1.0)
		draw_circle(Vector2(cos(ang), sin(ang)) * r, 3.0 * a * s, Color(_color.r, _color.g, _color.b, a))
