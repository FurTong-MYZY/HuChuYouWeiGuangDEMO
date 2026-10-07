extends Area2D


@export var bounce_speed: float = 500.0
@export var bounce_duration: float = 0.3
@export var decay_rate: float = 5.0
@export var min_speed_percent: float = 0.1
@export var bounce_direction: Vector2 = Vector2.UP


@export var squash_amount: float = 0.3
@export var stretch_amount: float = 0.2
@export var animation_duration: float = 0.3

var player: Node2D = null
var is_bouncing: bool = false
var bounce_velocity: Vector2 = Vector2.ZERO
var bounce_time: float = 0.0


@onready var bounce_sprite: Sprite2D = $Sprite2D
@onready var particles: GPUParticles2D = $GPUParticles2D


var original_scale: Vector2 = Vector2.ONE
var is_animating: bool = false
var animation_time: float = 0.0

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	if bounce_sprite:
		original_scale = bounce_sprite.scale

func _on_body_entered(body):
	if body.is_in_group("player"):
		player = body


func _on_body_exited(body):
	if body == player:

		if not is_bouncing:
			player = null

func _input(event):
	if event.is_action_pressed("interact") and player and not is_bouncing:
		print("方向：", bounce_direction)
		start_bounce()
		play_bounce_effects()

func start_bounce():
	if not player or not is_instance_valid(player):
		return

	is_bouncing = true
	bounce_time = 0.0

	var direction = bounce_direction.normalized()
	bounce_velocity = direction * bounce_speed

	if player is CharacterBody2D:
		player.is_bouncing_from_bumper = true
		player.velocity = Vector2.ZERO
		print("速度：", bounce_velocity)

func _process(delta):

	if is_bouncing and player and is_instance_valid(player):
		bounce_time += delta

		if Input.is_action_just_pressed("dash"):

			_end_bounce_and_dash()
			return

		if bounce_time >= bounce_duration:

			stop_bounce()
			return


		var progress = bounce_time / bounce_duration
		var decay_factor = exp( - decay_rate * bounce_time)

		var min_factor = min_speed_percent
		decay_factor = max(decay_factor, min_factor)

		var current_velocity = bounce_velocity * decay_factor

		var movement = current_velocity * delta


		if player is CharacterBody2D:
			player.global_position += movement
		elif player is RigidBody2D:
			player.global_position += movement


	if is_animating and bounce_sprite:
		animation_time += delta

		if animation_time < animation_duration:
			var progress = animation_time / animation_duration

			if progress < 0.3:
				var squash_progress = progress / 0.3
				var current_squash = squash_amount * squash_progress
				var current_stretch = stretch_amount * squash_progress * 0.5

				bounce_sprite.scale = original_scale * Vector2(
					1.0 - current_squash, 
					1.0 + current_stretch
				)
			elif progress < 0.6:
				var stretch_progress = (progress - 0.3) / 0.3
				var current_stretch = stretch_amount * (1.0 - stretch_progress)
				var current_squash = squash_amount * (1.0 - stretch_progress)

				bounce_sprite.scale = original_scale * Vector2(
					1.0 + current_stretch, 
					1.0 - current_squash * 0.5
				)
			else:
				var recover_progress = (progress - 0.6) / 0.4
				var eased_recover = ease(recover_progress, 3.0)

				bounce_sprite.scale = original_scale * Vector2(
					1.0 + stretch_amount * (1.0 - eased_recover), 
					1.0 - squash_amount * 0.5 * (1.0 - eased_recover)
				)
		else:
			is_animating = false
			bounce_sprite.scale = original_scale

func _end_bounce_and_dash():
	if not player or not is_instance_valid(player):
		stop_bounce()
		return


	is_bouncing = false
	bounce_time = 0.0
	bounce_velocity = Vector2.ZERO

	if player is CharacterBody2D:
		player.is_bouncing_from_bumper = false

		var input_dir = Input.get_axis("move_left", "move_right")

		player._try_dash(input_dir)

		if not player.is_dashing:
			var dash_dir = input_dir if input_dir != 0 else (1 if player.facing_right else -1)
			player.velocity = Vector2(dash_dir * player.dash_speed, 0)

	player = null

func play_bounce_effects():
	if particles:
		particles.restart()
		particles.emitting = true

	start_squash_animation()

func start_squash_animation():
	is_animating = true
	animation_time = 0.0

func stop_bounce():
	is_bouncing = false
	bounce_time = 0.0
	bounce_velocity = Vector2.ZERO

	if player and is_instance_valid(player):
		if player is CharacterBody2D:
			player.is_bouncing_from_bumper = false
			var direction = bounce_direction.normalized()
			var final_speed = bounce_speed * min_speed_percent
			player.velocity = direction * final_speed
	player = null

func _exit_tree():
	if body_entered.is_connected(_on_body_entered):
		body_entered.disconnect(_on_body_entered)
	if body_exited.is_connected(_on_body_exited):
		body_exited.disconnect(_on_body_exited)
