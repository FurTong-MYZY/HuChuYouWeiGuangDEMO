extends Sprite2D

@export var parallax_factor: Vector2 = Vector2(0.5, 0.5)
var camera: Camera2D
var last_camera_position: Vector2

func _ready():
	camera = get_viewport().get_camera_2d()
	if camera:
		last_camera_position = camera.global_position

func _process(_delta):
	if not camera:
		camera = get_viewport().get_camera_2d()
		if not camera:
			return
		last_camera_position = camera.global_position


	var camera_delta = camera.global_position - last_camera_position


	global_position += camera_delta * parallax_factor


	last_camera_position = camera.global_position
