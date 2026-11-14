extends Node2D
var _cam: Camera2D
func _ready() -> void :
	var scene: Node2D = load("res://scene.tscn").instantiate()
	add_child(scene)
	_cam = Camera2D.new()
	_cam.position = Vector2(2600, -900)
	_cam.zoom = Vector2(0.3, 0.3)
	_cam.enabled = true
	add_child(_cam)
	for i in range(200):
		await get_tree().process_frame

	var mech: = scene.get_node("Mechanics")
	for c in mech.get_children():
		if c is NeonBlock:
			c._solid = false
			c._apply_state(false)
			print("ghost ", c.name)
	for i in range(10):
		await get_tree().process_frame
	var img: = get_viewport().get_texture().get_image()
	img.save_png("user://ghost_check.png")
	print("SHOT ", img.get_size())
	get_tree().quit()

func _process(delta):
	if _cam:
		for c in get_tree().get_root().find_children("*", "Camera2D", true, false):
			if c != _cam:
				c.enabled = false
		_cam.enabled = true
		_cam.position = Vector2(2600, -900)
		_cam.zoom = Vector2(0.3, 0.3)
