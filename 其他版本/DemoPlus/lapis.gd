extends CharacterBody2D

@onready var head: Sprite2D = $Head
@onready var body: Sprite2D = $Body

@export var body_float_amplitude: float = 4.0
@export var body_float_speed: float = 2.0
@export var head_float_amplitude: float = 2.0
@export var head_float_speed: float = 3.0
@export var head_sway_angle: float = 2.0
@export var head_sway_speed: float = 1.5

var body_start_pos: Vector2
var head_start_pos: Vector2
var head_start_rotation: float

func _ready() -> void :
	body_start_pos = body.position
	head_start_pos = head.position
	head_start_rotation = head.rotation

func _process(delta: float) -> void :

	var time = Time.get_ticks_msec() / 1000.0


	var body_offset_y = sin(time * body_float_speed) * body_float_amplitude



	var head_offset_y = sin(time * head_float_speed) * head_float_amplitude
	head.position.y = head_start_pos.y + body_offset_y * 0.8 + head_offset_y


	head.rotation = head_start_rotation + deg_to_rad(sin(time * head_sway_speed) * head_sway_angle)


	body.scale.y = 1.0 + sin(time * body_float_speed) * 0.01
