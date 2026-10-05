extends CharacterBody2D
@onready var head: Sprite2D = $Head
@onready var left_arm: Sprite2D = $LeftArm
@onready var right_arm: Sprite2D = $RightArm
@onready var tail: Sprite2D = $Tail
@onready var body: Sprite2D = $Body

@export var body_float_amplitude: float = 3.0
@export var body_float_speed: float = 2.0
@export var head_tilt_angle: float = 3.0
@export var head_tilt_speed: float = 1.7
@export var head_bob_amplitude: float = 1.5
@export var head_bob_speed: float = 2.5
@export var arm_sway_amplitude: float = 5.0
@export var arm_sway_speed: float = 1.8
@export var tail_sway_angle: float = 12.0
@export var tail_sway_speed: float = 2.5
@export var tail_wave_offset: float = 0.5


@export var wave_hand: bool = false
@export var wave_cycle_time: float = 2.0
@export var wave_lift_angle: float = 45.0
@export var small_wave_range: float = 12.0
@export var small_wave_count: float = 3.0

var body_start_pos: Vector2
var head_start_pos: Vector2
var head_start_rotation: float
var left_arm_start_pos: Vector2
var left_arm_start_rotation: float
var right_arm_start_pos: Vector2
var tail_start_pos: Vector2
var tail_start_rotation: float

func _ready() -> void :
	if body != null:
		body_start_pos = body.position
	if head != null:
		head_start_pos = head.position
		head_start_rotation = head.rotation
	if left_arm != null:
		left_arm_start_pos = left_arm.position
		left_arm_start_rotation = left_arm.rotation
	if right_arm != null:
		right_arm_start_pos = right_arm.position
	if tail != null:
		tail_start_pos = tail.position
		tail_start_rotation = tail.rotation

func _process(delta: float) -> void :
	var time = Time.get_ticks_msec() / 1000.0


	var body_offset_y = sin(time * body_float_speed) * body_float_amplitude
	if body != null:
		body.position.y = body_start_pos.y + body_offset_y


	if head != null:
		var head_independent_bob = sin(time * head_bob_speed) * head_bob_amplitude
		head.position.y = head_start_pos.y + body_offset_y * 0.6 + head_independent_bob
		head.rotation = head_start_rotation + deg_to_rad(sin(time * head_tilt_speed) * head_tilt_angle)


	if left_arm != null:
		if not wave_hand:
			var left_arm_offset_y = cos(time * arm_sway_speed) * arm_sway_amplitude
			left_arm.position.y = left_arm_start_pos.y + body_offset_y * 0.5 + left_arm_offset_y
			left_arm.rotation = left_arm_start_rotation + deg_to_rad(sin(time * 1.3) * 1.5)
		else:
			var cycle_t = fmod(time, wave_cycle_time)
			var progress = cycle_t / wave_cycle_time
			var total_rot = 0.0

			if progress < 0.45:

				var lift_p = progress / 0.45
				lift_p = ease(lift_p, 0.3)
				total_rot = sin(lift_p * PI / 2.0) * wave_lift_angle

			elif progress < 0.7:

				var swing_p = (progress - 0.45) / 0.25
				total_rot = wave_lift_angle + sin(swing_p * PI * small_wave_count * 2.0) * small_wave_range

			else:

				var fall_p = (progress - 0.7) / 0.3
				fall_p = ease(fall_p, 0.3)
				total_rot = wave_lift_angle * (1.0 - sin(fall_p * PI / 2.0))

			left_arm.rotation = left_arm_start_rotation + deg_to_rad(total_rot)


	if right_arm != null:
		var right_arm_offset_y = cos(time * (arm_sway_speed + 0.4)) * arm_sway_amplitude * 0.85
		right_arm.position.y = right_arm_start_pos.y + body_offset_y * 0.5 + right_arm_offset_y



	if tail != null:
		tail.position.y = tail_start_pos.y + body_offset_y * 0.3
		var tail_wave = sin(time * tail_sway_speed) * tail_sway_angle
		var tail_wave2 = sin(time * tail_sway_speed * 1.7 + tail_wave_offset) * tail_sway_angle * 0.4
		tail.rotation = tail_start_rotation + deg_to_rad(tail_wave + tail_wave2)
		tail.position.y += sin(time * tail_sway_speed * 0.8) * 1.5


func ease(t: float, strength: float) -> float:
	if strength < 1.0:
		return pow(t, 1.0 / strength)
	else:
		return pow(t, strength)
