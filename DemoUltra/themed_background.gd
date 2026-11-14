extends Node2D


@export_enum("warning", "lab", "city") var theme: String = "warning"
@export var variant: int = 0

const SEARCHLIGHT_PATH: = "res://spr/场景/背景/searchlight.png"
const WARNING_ATMO: = preload("res://warning_atmo.gdshader")
const LAB_ATMO: = preload("res://lab_atmo.gdshader")
const CITY_ATMO: = preload("res://city_atmo.gdshader")

var _sky_root: Control
var _atmo_root: Control
var _layer_sprites: Array[Sprite2D] = []
var _layer_factors: Array[Vector2] = []
var _beam_pivots: Array[Node2D] = []
var _beam_sprites: Array[Sprite2D] = []
var _beam_time: = 0.0

func _ready() -> void :
	_disable_legacy_background()
	_build_sky_and_layers()
	_build_atmosphere()
	if theme == "warning":
		_build_searchlights()

func _disable_legacy_background() -> void :
	var parent: = get_parent()
	for old_name in ["background", "bg"]:
		var old: = parent.get_node_or_null(old_name)
		if old:
			old.visible = false
			old.queue_free()

	for child in parent.get_children():
		if child is Parallax2D:
			child.visible = false
			child.queue_free()

func _theme_paths() -> Dictionary:
	match theme:
		"lab":
			return {
				"sky": "res://spr/场景/背景/lab_sky.png", 
				"far": "res://spr/场景/背景/lab_far.png", 
				"mid": "res://spr/场景/背景/lab_mid.png", 
				"near": "res://spr/场景/背景/lab_near.png", 
				"atmo": LAB_ATMO, 
			}
		"city":
			return {
				"sky": "res://spr/场景/背景/city_high_sky.png", 
				"far": "res://spr/场景/背景/city_high_far.png", 
				"mid": "res://spr/场景/背景/city_high_mid.png", 
				"near": "res://spr/场景/背景/city_high_near.png", 
				"atmo": CITY_ATMO, 
			}
		_:
			return {
				"sky": "res://spr/场景/背景/warning_sky.png", 
				"far": "res://spr/场景/背景/warning_far.png", 
				"mid": "res://spr/场景/背景/warning_mid.png", 
				"near": "res://spr/场景/背景/warning_near.png", 
				"atmo": WARNING_ATMO, 
			}

func _build_sky_and_layers() -> void :
	var paths: = _theme_paths()
	var sky_texture: Texture2D = load(paths["sky"])
	var sky_layer: = CanvasLayer.new()
	sky_layer.layer = -40
	add_child(sky_layer)
	var layer: = CanvasLayer.new()
	layer.layer = -30
	add_child(layer)

	_sky_root = Control.new()
	_sky_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_sky_root.size = get_viewport().get_visible_rect().size
	sky_layer.add_child(_sky_root)

	if sky_texture:
		var sky: = TextureRect.new()
		sky.texture = sky_texture
		sky.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		sky.stretch_mode = TextureRect.STRETCH_SCALE
		sky.mouse_filter = Control.MOUSE_FILTER_IGNORE
		sky.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_sky_root.add_child(sky)

	_layer_factors = [
		Vector2(0.004, 0.002), 
		Vector2(0.01, 0.006), 
		Vector2(0.018, 0.012), 
	]
	for i in range(3):
		var key: String = ["far", "mid", "near"][i]
		var texture: Texture2D = load(paths[key])
		if texture == null:
			continue
		var spr: = Sprite2D.new()
		spr.texture = texture
		spr.centered = true
		spr.flip_h = variant % 2 == 1
		spr.z_index = i
		layer.add_child(spr)
		_layer_sprites.append(spr)

	get_viewport().size_changed.connect(_on_viewport_resized)

func _build_atmosphere() -> void :
	var layer: = CanvasLayer.new()
	layer.layer = 0
	add_child(layer)
	_atmo_root = Control.new()
	_atmo_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_atmo_root.position = Vector2.ZERO
	_atmo_root.size = get_viewport().get_visible_rect().size
	layer.add_child(_atmo_root)

	var rect: = ColorRect.new()
	rect.color = Color.WHITE
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var mat: = ShaderMaterial.new()
	mat.shader = _theme_paths()["atmo"]
	rect.material = mat
	_atmo_root.add_child(rect)

func _build_searchlights() -> void :
	var beam_tex: Texture2D = load(SEARCHLIGHT_PATH)
	if beam_tex == null:
		return
	var layer: = CanvasLayer.new()
	layer.layer = -10
	add_child(layer)
	var positions: = [Vector2(250, 720), Vector2(1120, 720)]
	for i in range(positions.size()):
		var pivot: = Node2D.new()
		pivot.position = positions[i]
		layer.add_child(pivot)
		var beam: = Sprite2D.new()
		beam.texture = beam_tex
		beam.centered = false
		beam.position = Vector2(-256, -500)
		beam.scale = Vector2(1.25, 1.25)
		beam.modulate = Color(1.0, 0.32, 0.22, 0.32 if i == 0 else 0.24)
		var mat: = CanvasItemMaterial.new()
		mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		beam.material = mat
		pivot.add_child(beam)
		_beam_pivots.append(pivot)
		_beam_sprites.append(beam)
		pivot.set_meta("phase", float(i) * 2.3)
		pivot.set_meta("base_rot", 0.22 if i == 0 else -0.24)

func _process(delta: float) -> void :
	_update_background_parallax()
	if _beam_pivots.is_empty():
		return
	_beam_time += delta
	for i in range(_beam_pivots.size()):
		var pivot: = _beam_pivots[i]
		var base: float = pivot.get_meta("base_rot")
		var phase: float = pivot.get_meta("phase")
		pivot.rotation = base + sin(_beam_time * 0.32 + phase) * 0.24
		_beam_sprites[i].modulate.a = (0.32 if i == 0 else 0.24) * (0.72 + 0.28 * sin(_beam_time * 1.8 + phase))

func _update_background_parallax() -> void :
	if _layer_sprites.is_empty():
		return
	var view: = get_viewport().get_visible_rect().size
	var cam: = get_viewport().get_camera_2d()
	var center: = cam.get_screen_center_position() if cam else Vector2.ZERO
	var lift: = [-155.0, -105.0, -55.0]
	for i in range(_layer_sprites.size()):
		var spr: = _layer_sprites[i]
		if spr.texture == null:
			continue
		var tex_size: = spr.texture.get_size()
		var base_scale: = maxf(view.x / tex_size.x, view.y / tex_size.y)
		var s: = base_scale * 1.18
		spr.scale = Vector2(s, s)
		var margin: = (tex_size * s - view) * 0.5
		var off: = - center * _layer_factors[i]
		off.x = clampf(off.x, - margin.x, margin.x)
		off.y = clampf(off.y, - margin.y, margin.y)

		spr.position = view * 0.5 + off + Vector2(0, lift[i] if i < lift.size() else 0.0)

func _on_viewport_resized() -> void :
	var size: = get_viewport().get_visible_rect().size
	if _sky_root:
		_sky_root.size = size
	if _atmo_root:
		_atmo_root.size = size
