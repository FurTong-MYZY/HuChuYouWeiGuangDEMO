extends Node2D



const SKY_PATH: = "res://spr/场景/neon_city/sky.png"
const FAR_PATH: = "res://spr/场景/neon_city/far.png"
const MID_PATH: = "res://spr/场景/neon_city/mid.png"
const NEAR_PATH: = "res://spr/场景/neon_city/near.png"
const RAIN_SHADER: = preload("res://neon_rain.gdshader")
const LAYER_WIDTH: = 2048.0

var _sky_root: Control
var _atmo_root: Control

func _ready() -> void :

	for old_name in ["background", "bg"]:
		var old: = get_parent().get_node_or_null(old_name)
		if old:
			old.visible = false
			old.queue_free()

	_build_sky()
	_build_parallax()
	_build_atmosphere()

func _build_sky() -> void :
	var layer: = CanvasLayer.new()
	layer.layer = -30
	add_child(layer)

	_sky_root = Control.new()
	_sky_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_sky_root.position = Vector2.ZERO
	_sky_root.size = get_viewport().get_visible_rect().size
	layer.add_child(_sky_root)
	get_viewport().size_changed.connect(_on_viewport_resized)

	var sky: = TextureRect.new()
	sky.texture = load(SKY_PATH)
	sky.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sky.stretch_mode = TextureRect.STRETCH_SCALE
	sky.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sky.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_sky_root.add_child(sky)

func _build_parallax() -> void :
	var parallax: = ParallaxBackground.new()
	parallax.layer = -20
	parallax.scroll_ignore_camera_zoom = true
	add_child(parallax)

	_add_parallax_layer(parallax, FAR_PATH, Vector2(0.055, 0.012), 0)
	_add_parallax_layer(parallax, MID_PATH, Vector2(0.14, 0.025), 1)
	_add_parallax_layer(parallax, NEAR_PATH, Vector2(0.32, 0.045), 2)

func _add_parallax_layer(parent: ParallaxBackground, path: String, motion: Vector2, index: int) -> void :
	var texture: Texture2D = load(path)
	if texture == null:
		return
	var layer: = ParallaxLayer.new()
	layer.motion_scale = motion
	layer.motion_mirroring = Vector2(LAYER_WIDTH, 0)
	layer.z_index = index
	parent.add_child(layer)

	var sprite: = Sprite2D.new()
	sprite.texture = texture
	sprite.centered = false
	sprite.position = Vector2.ZERO

	if index == 2:
		sprite.modulate = Color(0.72, 0.78, 0.9, 0.95)
	layer.add_child(sprite)

func _build_atmosphere() -> void :
	var layer: = CanvasLayer.new()
	layer.layer = 0
	add_child(layer)

	_atmo_root = Control.new()
	_atmo_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_atmo_root.position = Vector2.ZERO
	_atmo_root.size = get_viewport().get_visible_rect().size
	layer.add_child(_atmo_root)

	var rain: = ColorRect.new()
	rain.color = Color.WHITE
	rain.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rain.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var rain_mat: = ShaderMaterial.new()
	rain_mat.shader = RAIN_SHADER
	rain.material = rain_mat
	_atmo_root.add_child(rain)

func _on_viewport_resized() -> void :
	var size: = get_viewport().get_visible_rect().size
	if _sky_root:
		_sky_root.size = size
	if _atmo_root:
		_atmo_root.size = size
