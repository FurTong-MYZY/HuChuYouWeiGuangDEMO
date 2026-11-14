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

func _ready() -> void :
	velocity = Vector2.ZERO
	sprite.flip_h = false
	attack_area.scale.x = 1
	attack_area.monitoring = false
	anim_timer.timeout.connect(_on_anim_tick)
	cooldown_timer.timeout.connect(_on_cooldown_end)
	change_state(State.IDLE)

func _physics_process(_delta: float) -> void :
	global_position.x = clamp(global_position.x, min_x, max_x)

	match current_state:
		State.IDLE, State.COOLDOWN:
			velocity.x = 0
		State.CHASE:
			_chase()
		State.ATTACK:
			velocity.x = 0

	move_and_slide()


func _chase() -> void :
	if not player:
		change_state(State.IDLE)
		return

	var direction: float = player.global_position.x - global_position.x
	var abs_dist: float = absf(direction)

	if abs_dist <= attack_range:
		change_state(State.ATTACK)
		return

	var dir: int = 1 if direction > 0.0 else -1
	velocity.x = dir * move_speed
	sprite.flip_h = dir > 0
	attack_area.scale.x = -1 if dir > 0 else 1


func change_state(new_state: State) -> void :
	current_state = new_state
	current_frame = 0

	match new_state:
		State.IDLE:
			attack_area.monitoring = false
			anim_timer.wait_time = 0.3
			anim_timer.start()
		State.CHASE:
			attack_area.monitoring = false
			anim_timer.wait_time = 0.12
			anim_timer.start()
		State.ATTACK:
			has_hit = false
			attack_area.scale.x = -1 if sprite.flip_h else 1
			attack_area.monitoring = true
			_spawn_slash_fx()
			anim_timer.wait_time = 0.1
			anim_timer.start()
		State.COOLDOWN:
			attack_area.monitoring = false
			anim_timer.wait_time = 0.3
			anim_timer.start()


func _on_anim_tick() -> void :
	match current_state:
		State.IDLE, State.COOLDOWN:
			if idle_frames.is_empty():
				return
			current_frame = (current_frame + 1) % idle_frames.size()
			sprite.texture = idle_frames[current_frame]

		State.CHASE:
			if move_frames.is_empty():
				return
			current_frame = (current_frame + 1) % move_frames.size()
			sprite.texture = move_frames[current_frame]

		State.ATTACK:
			if attack_frames.is_empty():
				return
			if current_frame >= 3 and current_frame <= 6 and not has_hit:
				_deal_damage()

			if current_frame >= attack_frames.size() - 1:
				anim_timer.stop()
				_on_attack_finished()
				return

			sprite.texture = attack_frames[current_frame]
			current_frame += 1


func _deal_damage() -> void :
	has_hit = true
	var bodies: = attack_area.get_overlapping_bodies()
	for body in bodies:
		if body.has_method("take_trap_damage"):
			body.take_trap_damage()
			_spawn_hit_fx(body.global_position)
			break


func _on_attack_finished() -> void :
	attack_area.monitoring = false
	change_state(State.COOLDOWN)
	cooldown_timer.wait_time = attack_cooldown
	cooldown_timer.start()


func _on_cooldown_end() -> void :
	if player:
		var dist: = absf(player.global_position.x - global_position.x)
		if dist <= attack_range:
			change_state(State.ATTACK)
		else:
			change_state(State.CHASE)
	else:
		change_state(State.IDLE)


func _spawn_slash_fx() -> void :
	var parent: = get_parent()
	if parent == null:
		return
	var dir: int = -1 if sprite.flip_h else 1
	var points: = PackedVector2Array()
	for i in range(14):
		var t: = float(i) / 13.0
		var ang: = -1.18 + 2.36 * t
		points.append(Vector2(cos(ang) * 220.0 * dir, sin(ang) * 220.0))

	var glow: = Line2D.new()
	glow.width = 30.0
	glow.default_color = Color(1.0, 0.12, 0.18, 0.18)
	glow.points = points
	var glow_mat: = CanvasItemMaterial.new()
	glow_mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	glow.material = glow_mat
	glow.z_index = 5
	parent.add_child(glow)
	glow.global_position = global_position + Vector2(0, 100)
	glow.scale = Vector2(0.82, 0.82)
	var glow_tw: = create_tween()
	glow_tw.set_parallel(true)
	glow_tw.tween_property(glow, "scale", Vector2(1.08, 1.08), 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	glow_tw.tween_property(glow, "modulate:a", 0.0, 0.26)
	glow_tw.chain().tween_callback(glow.queue_free)

	var arc: = Line2D.new()
	arc.width = 8.0
	arc.default_color = Color(1.0, 0.62, 0.42, 0.9)
	arc.points = points
	var arc_mat: = CanvasItemMaterial.new()
	arc_mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	arc.material = arc_mat
	arc.z_index = 6
	parent.add_child(arc)
	arc.global_position = glow.global_position
	arc.scale = Vector2(0.82, 0.82)
	var arc_tw: = create_tween()
	arc_tw.set_parallel(true)
	arc_tw.tween_property(arc, "scale", Vector2(1.08, 1.08), 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	arc_tw.tween_property(arc, "modulate:a", 0.0, 0.26)
	arc_tw.chain().tween_callback(arc.queue_free)

	var flash_tw: = create_tween()
	flash_tw.tween_property(sprite, "modulate", Color(1.55, 1.25, 1.25, 1.0), 0.04)
	flash_tw.tween_property(sprite, "modulate", Color.WHITE, 0.14)
	_shake_camera(2.0)

func _spawn_hit_fx(pos: Vector2) -> void :
	var parent: = get_parent()
	if parent == null:
		return
	var spark: = Spark.new()
	parent.add_child(spark)
	spark.global_position = pos
	spark.setup(Color(1.0, 0.36, 0.2), 16, 120.0 * PixelArt.SCALE)
	_shake_camera(4.5)

func _shake_camera(amount: float) -> void :
	var camera: = get_viewport().get_camera_2d()
	if camera == null:
		return
	var base: = camera.offset
	var tw: = create_tween()
	for i in range(4):
		var a: = amount * (1.0 - float(i) / 4.0)
		tw.tween_property(camera, "offset", base + Vector2(randf_range( - a, a), randf_range( - a, a)), 0.022)
	tw.tween_property(camera, "offset", base, 0.04)


func player_entered_warning(body: Node2D) -> void :
	if body.is_in_group("player"):
		player = body
		if current_state in [State.IDLE, State.COOLDOWN]:
			var dist: = absf(player.global_position.x - global_position.x)
			if dist <= attack_range:
				change_state(State.ATTACK)
			else:
				change_state(State.CHASE)

func player_exited_warning(body: Node2D) -> void :
	if body == player:
		player = null
		attack_area.monitoring = false
		if current_state == State.CHASE:
			change_state(State.IDLE)
