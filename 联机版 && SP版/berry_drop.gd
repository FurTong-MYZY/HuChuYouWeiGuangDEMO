extends CharacterBody2D



var berry_id: int = 0
@export var berry_texture: Texture2D
var _visual: Node2D
var _pickup_ready: = false
var _gravity: float = 3200.0
var _floor_friction: float = 1400.0


func _ready() -> void :
	_build_visual()
	var area: = get_node_or_null("PickupArea")
	if area:
		area.body_entered.connect(_on_body_entered)



func setup(initial_velocity: Vector2) -> void :
	velocity = initial_velocity
	if initial_velocity == Vector2.ZERO:

		_pickup_ready = true
	else:

		_pickup_ready = false
		await get_tree().create_timer(0.5).timeout
		if is_instance_valid(self):
			_pickup_ready = true


func _physics_process(delta: float) -> void :
	velocity.y += _gravity * delta
	if is_on_floor():

		velocity.x = move_toward(velocity.x, 0.0, _floor_friction * delta)
	move_and_slide()


func _on_body_entered(body: Node2D) -> void :
	if not _pickup_ready:
		return
	if not body.is_in_group("player"):
		return
	if not body.is_multiplayer_authority():
		return
	if body.has_method("add_berry_to_inventory"):
		if body.add_berry_to_inventory():

			if Network and Network.has_method("request_pickup"):
				Network.request_pickup(berry_id)


func _build_visual() -> void :
	_visual = Node2D.new()
	_visual.name = "Visual"
	add_child(_visual)

	var spr: = Sprite2D.new()
	spr.texture = berry_texture
	var tw: = berry_texture.get_width() if berry_texture else 0
	var scale_f: = 28.0 / float(tw) if tw > 0 else 1.0
	spr.scale = Vector2(scale_f, scale_f)
	_visual.add_child(spr)
