extends Camera2D

@export var player: CharacterBody2D
@export var smooth_speed: float = 8.0
@export var dead_zone: Vector2 = Vector2(150, 80)
@export var speed_multiplier: float = 2.0
@export var max_offset: float = 200.0

var follow_offset: Vector2 = Vector2.ZERO

func _process(delta: float):
	if player == null:
		return


	var camera_velocity = player.velocity * speed_multiplier


	follow_offset += camera_velocity * delta


	follow_offset = follow_offset.limit_length(max_offset)


	var target_pos = player.global_position + follow_offset
	var offset = target_pos - global_position
	var dead_offset = Vector2(
		clamp(offset.x, - dead_zone.x, dead_zone.x), 
		clamp(offset.y, - dead_zone.y, dead_zone.y)
	)


	var move_target = global_position + (offset - dead_offset)
	global_position = lerp(global_position, move_target, smooth_speed * delta)
