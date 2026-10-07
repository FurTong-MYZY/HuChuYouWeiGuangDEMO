
extends CharacterBody2D
class_name Boss

enum State{IDLE, CHASE, ATTACK, COOLDOWN}

@export var move_speed: float = 100.0
@export var min_x: float = 0.0
@export var max_x: float = 500.0
@export var attack_range: float = 40.0
@export var attack_cooldown: float = 1.5

@export var idle_frames: Array[Texture2D] = []
@export var move_frames: Array[Texture2D] = []
@export var attack_frames: Array[Texture2D] = []

var current_state: State = State.IDLE
var player: CharacterBody2D = null
var current_frame: int = 0
var has_hit: bool = false

@onready var sprite: Sprite2D = $Sprite2D
@onready var anim_timer: Timer = $AnimationTimer
@onready var cooldown_timer: Timer = $AttackCooldownTimer
@onready var attack_area: Area2D = $AttackArea

func _ready():
	velocity = Vector2.ZERO
	sprite.flip_h = false
	attack_area.scale.x = 1
	anim_timer.timeout.connect(_on_anim_tick)
	cooldown_timer.timeout.connect(_on_cooldown_end)
	change_state(State.IDLE)

func _physics_process(_delta):
	global_position.x = clamp(global_position.x, min_x, max_x)

	match current_state:
		State.IDLE, State.COOLDOWN:
			velocity.x = 0
		State.CHASE:
			_chase()
		State.ATTACK:
			velocity.x = 0

	move_and_slide()


func _chase():
	if not player:
		change_state(State.IDLE)
		return

	var direction = player.global_position.x - global_position.x
	var abs_dist = abs(direction)

	if abs_dist <= attack_range:
		change_state(State.ATTACK)
		return

	var dir = sign(direction)
	velocity.x = dir * move_speed
	sprite.flip_h = dir > 0
	attack_area.scale.x = -1 if dir > 0 else 1


func change_state(new_state: State):
	current_state = new_state
	current_frame = 0

	match new_state:
		State.IDLE:
			anim_timer.wait_time = 0.3
			anim_timer.start()
		State.CHASE:
			anim_timer.wait_time = 0.12
			anim_timer.start()
		State.ATTACK:
			has_hit = false
			attack_area.scale.x = -1 if sprite.flip_h else 1
			anim_timer.wait_time = 0.1
			anim_timer.start()
		State.COOLDOWN:
			anim_timer.wait_time = 0.3
			anim_timer.start()


func _on_anim_tick():
	match current_state:
		State.IDLE, State.COOLDOWN:
			current_frame = (current_frame + 1) % idle_frames.size()
			sprite.texture = idle_frames[current_frame]

		State.CHASE:
			current_frame = (current_frame + 1) % move_frames.size()
			sprite.texture = move_frames[current_frame]

		State.ATTACK:
			if current_frame >= 3 and current_frame <= 6 and not has_hit:
				_deal_damage()

			if current_frame >= attack_frames.size() - 1:
				anim_timer.stop()
				_on_attack_finished()
				return

			sprite.texture = attack_frames[current_frame]
			current_frame += 1


func _deal_damage():
	has_hit = true
	var bodies = attack_area.get_overlapping_bodies()
	for body in bodies:
		if body.has_method("take_trap_damage"):
			body.take_trap_damage()
			break


func _on_attack_finished():
	change_state(State.COOLDOWN)
	cooldown_timer.wait_time = attack_cooldown
	cooldown_timer.start()


func _on_cooldown_end():
	if player:
		var dist = abs(player.global_position.x - global_position.x)
		if dist <= attack_range:
			change_state(State.ATTACK)
		else:
			change_state(State.CHASE)
	else:
		change_state(State.IDLE)


func player_entered_warning(body: Node2D):
	if body.is_in_group("player"):
		player = body
		if current_state in [State.IDLE, State.COOLDOWN]:
			var dist = abs(player.global_position.x - global_position.x)
			if dist <= attack_range:
				change_state(State.ATTACK)
			else:
				change_state(State.CHASE)

func player_exited_warning(body: Node2D):
	if body == player:
		player = null
		if current_state == State.CHASE:
			change_state(State.IDLE)
