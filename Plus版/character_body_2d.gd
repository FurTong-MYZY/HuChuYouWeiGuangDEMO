extends CharacterBody2D


@export var speed: float = 2000
@export var jump_force: float = 2888
@export var gravity: float = 6666
@export var max_fall_speed: float = 8000
@export var dash_speed: float = 800.0
@export var dash_duration: float = 0.15
@export var max_air_dashes: int = 1
@export var invincible_duration: float = 0.2
@export var trap_invincible_duration: float = 1.0
@export var ghost_scene: PackedScene
@export var ghost_interval: float = 0.02
@export var ghost_lifetime: float = 0.15
@export var squish_amount: float = 0.3
@export var squish_speed: float = 12.0
@export var max_health: float = 100.0
@export var max_vitality: float = 100.0
@export var vitality_regen: float = 2.0
@export var health_regen_at_full_vitality: float = 0.5
@export var vitality_penalty_max: float = 0.35
@export var vitality_drain_on_contamination: float = 5.0
@export var vitality_restore_on_zero: float = 50.0
@export var health_penalty_on_zero_vitality: float = 30.0
@export var trap_damage: float = 25.0

@export var dash_sound: AudioStream
@export var light_reflect_dash_sound: AudioStream
@export var dash_sound_volume: float = 0.0

@export var animation_switch_interval: float = 0.15
@export var sprite1: Sprite2D
@export var sprite2: Sprite2D
@export var sprite3: Sprite2D
@export var sprite4: Sprite2D
@export var sprite5: Sprite2D
@export var sprite6: Sprite2D


@export var eye_left_happy: Sprite2D
@export var eye_left_squint: Sprite2D
@export var eye_left_pain: Sprite2D
@export var eye_right_happy: Sprite2D
@export var eye_right_squint: Sprite2D
@export var eye_right_pain: Sprite2D
@export var expression_duration: float = 1.0


@export var head_sprite: Sprite2D
@export var tail_sprite: Sprite2D

@export var dash_anim_scale: float = 1.0
@export var dash_anim_offset: Vector2 = Vector2(0, 0)
@export var dash_anim_duration: float = 0.15


@export var eye_mirror_offset_x: float = 0.0
@export var tail_mirror_offset_x: float = 0.0


@export var head_offset_range: Vector2 = Vector2(10, 20)
@export var head_rotation_range: float = 6.0
@export var head_animation_speed: float = 8.0


@export var tail_rotation_range: float = 15.0
@export var tail_animation_speed: float = 8.0


@export var movement_bonus_decay_rate: float = 0.5
@export var movement_bonus_max: float = 0.5
@export var movement_bonus_on_light_reflect: float = 0.1
@export var movement_bonus_on_dash_end_brick: float = 0.1

@export var coyote_time: float = 0.08
@export var death_screen_duration: float = 1.0


var is_dashing: bool = false
var _dash_anim: Sprite2D = null
var _dash_anim_frames: Array[Texture2D] = []
var _dash_anim_frame: int = 0
var _dash_anim_frame_timer: float = 0.0
var _saved_body_visible: Dictionary = {}
var dash_timer: float = 0.0
var dash_direction: int = 1
var air_dashes_left: int = 0
var facing_right: bool = true
var prev_facing_right: bool = true
var is_invincible: bool = false
var invincible_timer: float = 0.0
var ghost_timer: float = 0.0
var is_dead: bool = false
var is_light_reflecting: bool = false
var light_reflect_timer: float = 0.0
var current_health: float = 100.0
var current_vitality: float = 100.0
var contamination_bodies: Array = []
var contamination_timer: float = 0.0
var target_scale_x: float = 0.5
var target_scale_y: float = 0.5

var touching_bricks: int = 0
var is_bouncing_from_bumper: bool = false
var dialogue_locked: bool = false
var movement_bonus: float = 0.0


var animation_timer: float = 0.0
var sprites: Array[Sprite2D] = []
var current_sprite_index: int = 0
var prev_sprite_index: int = 0


var coyote_timer: float = 0.0
var was_on_floor: bool = false

var allow_air_jump: bool = false
var dash_window_timer: float = 0.0

const DASH_JUMP_WINDOW: float = 0.3

var wall_jump_direction: int = -1

@export_group("跳跃喷气特效")
@export var jet_particles: int = 18
@export var jet_spread: float = 40.0
@export var jet_speed_min: float = 90.0
@export var jet_speed_max: float = 220.0
@export var jet_lifetime: float = 0.35


var ui: Control
var health_bar: ProgressBar
var vitality_bar: ProgressBar
var health_label: Label
var vitality_label: Label
var death_screen: ColorRect = null
var _hp_danger: ColorRect
var _danger_pulse: float = 0.0
var _vig_mat: ShaderMaterial
var _vignette: ColorRect
var _vit_noise_mat: ShaderMaterial
var _noise_rect: ColorRect
var _burst_mat: ShaderMaterial
var _burst_rect: ColorRect
var _burst_strength: float = 0.0


@onready var audio_player: AudioStreamPlayer2D = $AudioStreamPlayer2D


@onready var sprite: Sprite2D = $Sprite2D


var expression_timer: float = 0.0
var current_expression: String = "none"
var is_expression_active: bool = false
var _pain_lock: float = 0.0


var head_initial_position: Vector2
var tail_initial_position: Vector2
var tail_initial_rotation: float
var current_head_offset: Vector2 = Vector2.ZERO
var current_head_rotation: float = 0.0
var current_tail_rotation: float = 0.0


var eye_relative_offset: Vector2 = Vector2(-28, 70)


var eye_sprites: Array[Sprite2D] = []

func _ready() -> void :
	_mark_current_scene_unlocked()
	_dash_anim_frames = [
	preload("res://spr/流明/dash1.png"), 
	preload("res://spr/流明/dash2.png"), 
	preload("res://spr/流明/dash3.png"), 
	preload("res://spr/流明/dash4.png"), 
	preload("res://spr/流明/dash5.png"), 
	preload("res://spr/流明/dash6.png"), 
]
	air_dashes_left = max_air_dashes
	target_scale_x = abs(sprite.scale.x)
	target_scale_y = abs(sprite.scale.y)
	current_health = max_health
	current_vitality = max_vitality

	_create_contamination_detector()
	_create_ui()
	_create_danger_overlays()

	if not audio_player:
		audio_player = AudioStreamPlayer2D.new()
		audio_player.name = "AudioStreamPlayer2D"
		add_child(audio_player)


	sprites = [sprite1, sprite2, sprite3, sprite4, sprite5, sprite6]
	for i in range(sprites.size()):
		if sprites[i]:
			sprites[i].visible = (i == 0)
	current_sprite_index = 0
	prev_sprite_index = 0
	prev_facing_right = facing_right


	eye_sprites = [eye_left_happy, eye_left_squint, eye_left_pain, 
		eye_right_happy, eye_right_squint, eye_right_pain]
	_hide_all_eyes()


	if head_sprite:
		head_initial_position = head_sprite.position
		current_head_offset = Vector2.ZERO
		current_head_rotation = 0.0
	if tail_sprite:
		tail_initial_position = tail_sprite.position
		tail_initial_rotation = tail_sprite.rotation
		current_tail_rotation = 0.0


	$Area2D.body_entered.connect(_on_brick_entered)
	$Area2D.body_exited.connect(_on_brick_exited)


	DialogueManager.dialogue_started.connect(_on_dialogue_started)
	DialogueManager.dialogue_ended.connect(_on_dialogue_ended)

	await get_tree().process_frame

func _on_dialogue_started(_id: String) -> void :
	dialogue_locked = true

func _on_dialogue_ended() -> void :
	dialogue_locked = false

func _create_contamination_detector() -> void :
	var detector = Area2D.new()
	detector.name = "ContaminationDetector"
	detector.collision_layer = 0
	detector.collision_mask = 0

	var collision_shape = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(40, 50)
	collision_shape.shape = shape

	detector.add_child(collision_shape)
	add_child(detector)

	detector.area_entered.connect(_on_contamination_area_entered)
	detector.area_exited.connect(_on_contamination_area_exited)
	detector.body_entered.connect(_on_contamination_body_entered)
	detector.body_exited.connect(_on_contamination_body_exited)


func _hide_all_eyes() -> void :
	for eye in eye_sprites:
		if eye:
			eye.visible = false

func _set_eye_expression(left_eye: Sprite2D, right_eye: Sprite2D) -> void :
	_hide_all_eyes()
	if left_eye:
		left_eye.visible = true
	if right_eye:
		right_eye.visible = true

func _update_expression_from_health() -> void :
	if _pain_lock > 0.0:
		return
	if current_health >= 70:
		if current_vitality >= 60:
			_set_eye_expression(eye_left_happy, eye_right_happy)
			current_expression = "happy_happy"
		else:
			_set_eye_expression(eye_left_happy, eye_right_squint)
			current_expression = "happy_squint"
	elif current_health >= 40:
		if current_vitality >= 60:
			_set_eye_expression(eye_left_squint, eye_right_happy)
			current_expression = "squint_happy"
		else:
			_set_eye_expression(eye_left_squint, eye_right_squint)
			current_expression = "squint_squint"
	else:
		_set_eye_expression(eye_left_pain, eye_right_pain)
		current_expression = "pain"

func _trigger_pain_expression() -> void :
	_set_eye_expression(eye_left_pain, eye_right_pain)
	current_expression = "pain"
	is_expression_active = true
	expression_timer = expression_duration
	_pain_lock = expression_duration

func _clear_expression() -> void :
	_hide_all_eyes()
	current_expression = "none"
	is_expression_active = false
	expression_timer = 0.0



func set_mood_expression(mood: String, lock_time: float) -> void :
	match mood:
		"happy":
			_set_eye_expression(eye_left_happy, eye_right_happy)
			current_expression = "happy"
		"squint":
			_set_eye_expression(eye_left_squint, eye_right_squint)
			current_expression = "squint"
		"pain":
			_set_eye_expression(eye_left_pain, eye_right_pain)
			current_expression = "pain"
		_:
			return
	is_expression_active = true
	expression_timer = lock_time
	_pain_lock = lock_time


func _on_brick_entered(body):
	if body.is_in_group("brick"):
		touching_bricks += 1

func _on_brick_exited(body):
	if body.is_in_group("brick"):
		touching_bricks -= 1

func _create_ui() -> void :
	var canvas_layer = CanvasLayer.new()
	canvas_layer.name = "PlayerUI"
	canvas_layer.layer = 10

	ui = Control.new()
	ui.name = "UI"
	ui.set_anchors_preset(Control.PRESET_TOP_LEFT)

	var container = VBoxContainer.new()
	container.position = Vector2(10, 10)
	container.size = Vector2(250, 100)

	health_label = Label.new()
	health_label.text = "HP: 100/100"
	health_label.add_theme_color_override("font_color", Color.WHITE)
	health_label.add_theme_font_size_override("font_size", 18)
	container.add_child(health_label)

	health_bar = ProgressBar.new()
	health_bar.min_value = 0
	health_bar.max_value = max_health
	health_bar.value = current_health
	health_bar.size_flags_horizontal = Control.SIZE_FILL
	health_bar.custom_minimum_size = Vector2(230, 20)
	health_bar.modulate = Color(0.2, 0.8, 0.2)
	container.add_child(health_bar)

	var spacer1 = Control.new()
	spacer1.custom_minimum_size = Vector2(0, 5)
	container.add_child(spacer1)

	vitality_label = Label.new()
	vitality_label.text = "VIT: 100/100"
	vitality_label.add_theme_color_override("font_color", Color.WHITE)
	vitality_label.add_theme_font_size_override("font_size", 18)
	container.add_child(vitality_label)

	vitality_bar = ProgressBar.new()
	vitality_bar.min_value = 0
	vitality_bar.max_value = max_vitality
	vitality_bar.value = current_vitality
	vitality_bar.size_flags_horizontal = Control.SIZE_FILL
	vitality_bar.custom_minimum_size = Vector2(230, 20)
	vitality_bar.modulate = Color(0.2, 0.4, 0.8)
	container.add_child(vitality_bar)

	ui.add_child(container)
	canvas_layer.add_child(ui)
	add_child(canvas_layer)


const VIG_SHADER: = """shader_type canvas_item;
""" + \
"uniform vec4 tint : source_color = vec4(0,0,0,1);\r\n"\
+ \
"uniform float strength : hint_range(0.0,1.0) = 0.0;\r\n"\
+ \
"uniform float radius : hint_range(0.0,1.5) = 0.55;\r\n"\
+ \
"uniform float softness : hint_range(0.0,1.0) = 0.45;\r\n"\
+ \
"void fragment(){ vec2 uv = UV - vec2(0.5); float d = length(uv)*2.0; float v = smoothstep(radius, radius+softness, d); COLOR = vec4(tint.rgb, v*strength); }\r\n"

const NOISE_SHADER: = """shader_type canvas_item;
""" + \
"uniform float strength : hint_range(0.0,1.0) = 0.0;\r\n"\
+ \
"void fragment(){ vec2 gv = floor(UV*vec2(480.0,270.0)); float n = fract(sin(dot(gv+floor(TIME*20.0), vec2(12.9898,78.233)))*43758.5453); n = step(0.72,n); COLOR = vec4(0.45,0.15,0.8, n*strength); }\r\n"

const BURST_SHADER: = """shader_type canvas_item;
""" + \
"uniform float strength : hint_range(0.0,1.0) = 0.0;\r\n"\
+ \
"void fragment(){ vec2 uv = UV - vec2(0.5); float d = length(uv)*2.0; float mist = 1.0 - smoothstep(0.2,1.35,d)*0.35; float n = fract(sin(dot(floor(UV*vec2(320.0,180.0)), vec2(12.9898,78.233)))*43758.5453); COLOR = vec4(0.85,0.1,0.12, mist*(0.5+n*0.5)*strength); }\r\n"


func _create_danger_overlays() -> void :
	var layer: = CanvasLayer.new()
	layer.name = "DangerLayer"
	layer.layer = 15
	add_child(layer)


	var vig_shader: = Shader.new()
	vig_shader.code = VIG_SHADER
	_vig_mat = ShaderMaterial.new()
	_vig_mat.shader = vig_shader
	_vig_mat.set_shader_parameter("strength", 0.0)
	_vig_mat.set_shader_parameter("tint", Color(0, 0, 0))
	_vignette = ColorRect.new()
	_vignette.visible = false
	_vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	_vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vignette.material = _vig_mat
	layer.add_child(_vignette)


	var noise_shader: = Shader.new()
	noise_shader.code = NOISE_SHADER
	_vit_noise_mat = ShaderMaterial.new()
	_vit_noise_mat.shader = noise_shader
	_vit_noise_mat.set_shader_parameter("strength", 0.0)
	var vit_noise: = ColorRect.new()
	vit_noise.visible = false
	vit_noise.set_anchors_preset(Control.PRESET_FULL_RECT)
	vit_noise.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vit_noise.material = _vit_noise_mat
	_noise_rect = vit_noise
	layer.add_child(vit_noise)


	var burst_shader: = Shader.new()
	burst_shader.code = BURST_SHADER
	_burst_mat = ShaderMaterial.new()
	_burst_mat.shader = burst_shader
	_burst_mat.set_shader_parameter("strength", 0.0)
	var burst: = ColorRect.new()
	burst.visible = false
	burst.set_anchors_preset(Control.PRESET_FULL_RECT)
	burst.mouse_filter = Control.MOUSE_FILTER_IGNORE
	burst.material = _burst_mat
	_burst_rect = burst
	layer.add_child(burst)


	_hp_danger = ColorRect.new()
	_hp_danger.color = Color(0.7, 0.05, 0.05, 0.0)
	_hp_danger.set_anchors_preset(Control.PRESET_FULL_RECT)
	_hp_danger.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_hp_danger)

func _update_danger_overlays(delta: float) -> void :
	_danger_pulse += delta * 3.2
	var pulse: = (sin(_danger_pulse) + 1.0) * 0.5
	var hp_danger: = clampf((0.7 - current_health / max_health) / 0.7, 0.0, 1.0)
	var vit_danger: = clampf((0.7 - current_vitality / max_vitality) / 0.7, 0.0, 1.0)
	if is_dead:
		hp_danger = 0.0
		vit_danger = 0.0

	var hp_a: = hp_danger * (0.08 + pulse * 0.14)
	_hp_danger.color.a = lerpf(_hp_danger.color.a, hp_a, delta * 8.0)

	var vig_strength: = maxf(hp_danger, vit_danger) * (0.5 + pulse * 0.25)
	var tint: = Color(0.7, 0.05, 0.05) * hp_danger + Color(0.4, 0.12, 0.75) * vit_danger
	var cur_s: float = _vig_mat.get_shader_parameter("strength")
	_vig_mat.set_shader_parameter("strength", lerpf(cur_s, vig_strength, delta * 6.0))
	_vig_mat.set_shader_parameter("tint", tint)

	var cur_n: float = _vit_noise_mat.get_shader_parameter("strength")
	var n_target: = vit_danger * (0.35 + pulse * 0.25)
	_vit_noise_mat.set_shader_parameter("strength", lerpf(cur_n, n_target, delta * 6.0))

	_burst_strength = maxf(0.0, _burst_strength - delta * 1.8)
	_burst_mat.set_shader_parameter("strength", _burst_strength)

	_vignette.visible = vig_strength > 0.02
	_noise_rect.visible = n_target > 0.02
	_burst_rect.visible = _burst_strength > 0.02

func _trigger_hit_burst() -> void :
	_burst_strength = 1.0
func _set_all_sprites_modulate(color: Color) -> void :
	sprite.modulate = color
	for spr in sprites:
		if spr:
			spr.modulate = color
	if head_sprite:
		head_sprite.modulate = color
	if tail_sprite:
		tail_sprite.modulate = color
	for eye in eye_sprites:
		if eye:
			eye.modulate = color

func _physics_process(delta: float) -> void :
	if is_dead:
		return

	if is_bouncing_from_bumper:
		_update_ui()
		_update_vitality_and_health(delta)
		_update_contamination_damage(delta)
		_update_head_tail_animation(delta, 0.0)
		_apply_squish(delta)
		return

	if movement_bonus > 0:
		movement_bonus = max(movement_bonus - movement_bonus_decay_rate * delta, 0.0)

	if is_light_reflecting:
		light_reflect_timer -= delta
		if light_reflect_timer <= 0:
			is_light_reflecting = false

	if _pain_lock > 0.0:
		_pain_lock -= delta
	if is_expression_active:
		expression_timer -= delta
		if expression_timer <= 0:
			_clear_expression()

	_update_ui()
	_update_vitality_and_health(delta)
	_update_contamination_damage(delta)
	_update_danger_overlays(delta)

	if is_on_floor():
		air_dashes_left = max_air_dashes
		coyote_timer = coyote_time
		allow_air_jump = false

	if not is_on_floor() and was_on_floor:
		coyote_timer = coyote_time
	elif not is_on_floor():
		coyote_timer -= delta

	if is_invincible:
		invincible_timer -= delta
		if invincible_timer <= 0:
			is_invincible = false
			_set_all_sprites_modulate(Color.WHITE)

	if is_dashing:
		dash_timer -= delta
		velocity.x = dash_direction * dash_speed
		velocity.y = 0
		_update_dash_anim(delta)

		ghost_timer -= delta
		if ghost_timer <= 0:
			ghost_timer = ghost_interval
			_spawn_ghost()

		var dash_ending: bool = dash_timer <= 0
		if dash_ending:
			is_dashing = false
			_end_dash_anim()

		_update_head_tail_animation(delta, 0.0)
		_apply_squish(delta)
		move_and_slide()


		if dash_ending:
			if touching_bricks > 0 or is_on_wall():

				allow_air_jump = true
				wall_jump_direction = - dash_direction
				dash_window_timer = DASH_JUMP_WINDOW
				movement_bonus = min(movement_bonus + movement_bonus_on_dash_end_brick, movement_bonus_max)
			else:
				dash_window_timer = 0.0

		return

	var touch_x: = 0.0
	var mc: = get_node_or_null("/root/MobileControls")
	if mc: touch_x = mc.move_x
	var input_dir: = 0.0 if dialogue_locked else clampf(Input.get_axis("move_left", "move_right") + touch_x, -1.0, 1.0)


	if dash_window_timer > 0.0:
		dash_window_timer -= delta
		if dash_window_timer <= 0.0:
			allow_air_jump = false

	var vitality_factor = 1.0 - (vitality_penalty_max * (1.0 - current_vitality / max_vitality))
	var total_factor = vitality_factor * (1.0 + movement_bonus)
	var current_speed = speed * total_factor
	var current_jump = jump_force * total_factor

	velocity.x = input_dir * current_speed

	if input_dir != 0:
		facing_right = input_dir > 0

	if facing_right != prev_facing_right:
		_update_sprites_facing()
		prev_facing_right = facing_right

	if not is_on_floor():
		velocity.y += gravity * delta
		velocity.y = min(velocity.y, max_fall_speed)

	if not dialogue_locked and Input.is_action_just_pressed("jump"):
		if is_on_floor() or coyote_timer > 0:
			velocity.y = - current_jump
			_squish(0.8, 1.2)
			coyote_timer = 0.0
			_spawn_jump_fx(1 if facing_right else -1, Color(1, 1, 1), 1.0)
			_update_expression_from_health()
			is_expression_active = true
			expression_timer = expression_duration
		elif allow_air_jump:
			velocity.y = - current_jump * 0.9
			velocity.x = wall_jump_direction * current_speed * 0.9
			_squish(0.8, 1.2)
			allow_air_jump = false
			dash_window_timer = 0.0
			_spawn_jump_fx(wall_jump_direction, Color(1.0, 0.84, 0.0), 2.0)
			_update_expression_from_health()
			is_expression_active = true
			expression_timer = expression_duration

	if Input.is_action_just_released("jump") and velocity.y < 0:
		velocity.y *= 0.5

	var mobile_dash: = false
	if mc and mc.dash_queued > 0:
		mc.dash_queued -= 1
		mobile_dash = true

	if not dialogue_locked and (Input.is_action_just_pressed("dash") or mobile_dash):
		_try_dash(input_dir)

	var was_in_air = not is_on_floor()
	move_and_slide()

	was_on_floor = is_on_floor()

	if was_in_air and is_on_floor():
		_squish(1.3, 0.7)
		allow_air_jump = false
		_update_expression_from_health()
		is_expression_active = true
		expression_timer = expression_duration

	_update_sprite_animation(delta, input_dir)
	_update_head_tail_animation(delta, input_dir)
	_update_tail_dash_glow()
	_apply_squish(delta)

func _update_sprite_animation(delta: float, input_dir: float) -> void :
	var is_on_ground_or_coyote = is_on_floor() or coyote_timer > 0
	var is_moving = input_dir != 0 and is_on_ground_or_coyote

	if is_moving:
		animation_timer -= delta
		if animation_timer <= 0:
			animation_timer = animation_switch_interval
			current_sprite_index = (current_sprite_index + 1) % sprites.size()

			if current_sprite_index != prev_sprite_index:
				_update_sprite_visibility()
				prev_sprite_index = current_sprite_index
	else:
		if current_sprite_index != 0:
			current_sprite_index = 0
			_update_sprite_visibility()
			prev_sprite_index = 0
		animation_timer = animation_switch_interval

func _update_sprite_visibility() -> void :
	for i in range(sprites.size()):
		if sprites[i]:
			sprites[i].visible = (i == current_sprite_index)

func _update_sprites_facing() -> void :
	var dir_multiplier = 1 if facing_right else -1
	for spr in sprites:
		if spr:
			var abs_scale_x = abs(spr.scale.x)
			spr.scale.x = abs_scale_x * dir_multiplier
	if head_sprite:
		var abs_scale_x = abs(head_sprite.scale.x)
		head_sprite.scale.x = abs_scale_x * dir_multiplier


	if tail_sprite:
		var abs_scale_x = abs(tail_sprite.scale.x)
		tail_sprite.scale.x = abs_scale_x * dir_multiplier

		if facing_right:
			tail_sprite.position.x = tail_initial_position.x
		else:
			tail_sprite.position.x = tail_initial_position.x + tail_mirror_offset_x


	for eye in eye_sprites:
		if eye:
			var abs_scale_x = abs(eye.scale.x)
			eye.scale.x = abs_scale_x * dir_multiplier


	_update_eye_positions()

func _update_eye_positions() -> void :
	if not head_sprite:
		return

	var head_rot_rad = head_sprite.rotation
	var eye_offset_rotated = eye_relative_offset.rotated(head_rot_rad)


	var mirror_offset = 0.0
	if not facing_right:
		mirror_offset = eye_mirror_offset_x

	for eye in eye_sprites:
		if eye:
			eye.position = head_sprite.position + eye_offset_rotated + Vector2(mirror_offset, 0)
			eye.rotation = head_rot_rad

func _update_head_tail_animation(delta: float, input_dir: float) -> void :
	if not head_sprite and not tail_sprite:
		return

	var target_offset = Vector2.ZERO
	var target_head_rot = 0.0
	var target_tail_rot = 0.0


	var walking: = input_dir != 0.0 and is_on_floor()
	var idle_sway: = input_dir == 0.0 and is_on_floor()
	if walking:
		var horizontal_factor = clampf(velocity.x / speed, -1.0, 1.0)
		target_offset.x = horizontal_factor * head_offset_range.x
		target_head_rot = horizontal_factor * (head_rotation_range * 0.5)
		var time = Time.get_ticks_msec() / 1000.0
		var tail_wiggle = sin(time * 20.0) * 3.0
		target_tail_rot += tail_wiggle


	if not is_on_floor():



		var vertical_factor = - velocity.y / max_fall_speed
		vertical_factor = clamp(vertical_factor, -1.0, 1.0)
		target_tail_rot += vertical_factor * tail_rotation_range


		if velocity.y < 0:
			target_offset.y = - head_offset_range.y * 0.8 * ( - velocity.y / jump_force)
			target_head_rot -= head_rotation_range * 0.4
		else:
			target_offset.y = head_offset_range.y * 0.8 * (velocity.y / max_fall_speed)
			target_head_rot += head_rotation_range * 0.4
	else:

		if idle_sway:
			var t2 = Time.get_ticks_msec() / 1000.0
			target_tail_rot += sin(t2 * 2.5) * 2.0
			target_head_rot += sin(t2 * 2.0) * 1.5
			target_offset.y = sin(t2 * 2.0) * 1.5
		else:
			target_offset.y = 0.0


	if is_dashing:
		target_offset.x *= 1.5
		target_head_rot = head_rotation_range * (1 if dash_direction > 0 else -1)
		target_tail_rot = tail_rotation_range * (1 if dash_direction > 0 else -1)


	if is_bouncing_from_bumper:
		target_offset.y = - head_offset_range.y
		target_head_rot = - head_rotation_range
		target_tail_rot = tail_rotation_range * 0.5

	var smooth_speed = head_animation_speed * delta
	current_head_offset = current_head_offset.lerp(target_offset, smooth_speed)
	current_head_rotation = lerp(current_head_rotation, target_head_rot, smooth_speed)
	current_tail_rotation = lerp(current_tail_rotation, target_tail_rot, tail_animation_speed * delta)

	if head_sprite:
		head_sprite.position = head_initial_position + current_head_offset
		head_sprite.rotation = deg_to_rad(current_head_rotation)

		_update_eye_positions()

	if tail_sprite:
		tail_sprite.rotation = tail_initial_rotation + deg_to_rad(current_tail_rotation)

func _update_vitality_and_health(delta: float) -> void :
	if current_vitality < max_vitality:
		current_vitality = min(current_vitality + vitality_regen * delta, max_vitality)

	if current_vitality >= max_vitality and current_health < max_health:
		current_health = min(current_health + health_regen_at_full_vitality * delta, max_health)

	if current_vitality <= 0:
		current_health -= health_penalty_on_zero_vitality
		current_vitality = vitality_restore_on_zero
		_trigger_damage_feedback()

	if current_health <= 0:
		_die()

func _update_contamination_damage(delta: float) -> void :
	contamination_bodies = contamination_bodies.filter( func(body): return is_instance_valid(body))
	if contamination_bodies.size() > 0 and not is_dashing:
		contamination_timer -= delta
		if contamination_timer <= 0:
			contamination_timer = 0.1
			current_vitality = max(current_vitality - vitality_drain_on_contamination, 0)
			_trigger_contamination_feedback()
			if current_vitality <= 0:
				_update_vitality_and_health(0)

func take_trap_damage() -> void :
	if is_invincible or is_dashing or is_dead:
		return
	current_health -= trap_damage
	is_invincible = true
	invincible_timer = trap_invincible_duration

	_set_all_sprites_modulate(Color(1, 0.3, 0.3, 0.7))
	_trigger_pain_expression()
	_trigger_damage_feedback()
	_trigger_hit_burst()
	if current_health <= 0:
		_die()

func _trigger_damage_feedback() -> void :
	var tween = create_tween()
	tween.tween_method(
		func(color: Color):
			_set_all_sprites_modulate(color), 
		Color.RED, 
		Color(1, 0.3, 0.3, 0.7), 
		0.05
	)

	var camera = get_viewport().get_camera_2d()
	if camera:
		var original_pos = camera.global_position
		var shake_tween = create_tween()
		for i in range(6):
			shake_tween.tween_callback( func(): camera.global_position = original_pos + Vector2(randf_range(-3, 3), randf_range(-3, 3)))
			shake_tween.tween_interval(0.03)
		shake_tween.tween_callback( func(): camera.global_position = original_pos)

func _trigger_contamination_feedback() -> void :
	_set_all_sprites_modulate(Color(0.6, 0.2, 0.8, 0.8))
	var tween = create_tween()
	tween.tween_method(
		func(color: Color):
			_set_all_sprites_modulate(color), 
		Color(0.6, 0.2, 0.8, 0.8), 
		Color.WHITE, 
		0.1
	)

func _die() -> void :
	is_dead = true
	velocity = Vector2.ZERO

	_trigger_pain_expression()
	_create_death_screen()

	var tween = create_tween()
	tween.tween_method(_set_all_sprites_modulate, Color.WHITE, Color(1, 0, 0, 0), 0.3)
	tween.tween_interval(death_screen_duration)
	tween.tween_callback(_restart_scene)

func _create_death_screen() -> void :
	death_screen = ColorRect.new()
	death_screen.color = Color(1, 0, 0, 0)
	death_screen.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var viewport_size = get_viewport().get_visible_rect().size
	death_screen.size = viewport_size
	death_screen.position = Vector2.ZERO

	var canvas_layer = CanvasLayer.new()
	canvas_layer.layer = 100
	add_child(canvas_layer)
	canvas_layer.add_child(death_screen)

	var tween = create_tween()
	tween.tween_property(death_screen, "color", Color(0.903, 0.292, 0.235, 1.0), 0.3)

func _restart_scene() -> void :
	get_tree().reload_current_scene()

func _update_tail_dash_glow() -> void :
	if not tail_sprite:
		return
	if is_invincible or is_dashing or is_dead:
		return
	var can: = is_on_floor() or air_dashes_left > 0
	if can:
		var t: = (sin(Time.get_ticks_msec() * 0.004) + 1.0) * 0.5
		var boost: = 1.2 + t * 0.2
		tail_sprite.modulate = Color(boost, boost, boost)
	else:
		tail_sprite.modulate = Color(1, 1, 1)

func _try_dash(input_dir: float) -> void :
	if is_dashing:
		return
	if contamination_bodies.size() > 0:
		_light_reflect()
		return
	if is_on_floor():
		_start_dash(input_dir)
	elif air_dashes_left > 0:
		air_dashes_left -= 1
		_start_dash(input_dir)

func _light_reflect() -> void :
	is_light_reflecting = true
	light_reflect_timer = 0.3
	_set_all_sprites_modulate(Color(1, 1, 0, 1))
	air_dashes_left = max_air_dashes
	current_vitality = min(current_vitality + 20, max_vitality)
	movement_bonus = min(movement_bonus + movement_bonus_on_light_reflect, movement_bonus_max)
	_start_dash(1 if facing_right else -1)

func _play_dash_sound(is_light_reflect: bool) -> void :
	if not audio_player:
		return

	var sound_to_play: AudioStream = null

	if is_light_reflect and light_reflect_dash_sound:
		sound_to_play = light_reflect_dash_sound
	elif dash_sound:
		sound_to_play = dash_sound

	if sound_to_play:
		audio_player.stream = sound_to_play
		audio_player.volume_db = dash_sound_volume
		audio_player.play()

func _start_dash(input_dir: float) -> void :
	is_dashing = true
	dash_timer = dash_duration
	is_invincible = true
	invincible_timer = dash_duration
	_begin_dash_anim()

	_play_dash_sound(is_light_reflecting)

	if is_light_reflecting:
		_set_all_sprites_modulate(Color(1, 0.9, 0, 0.8))
	else:
		_set_all_sprites_modulate(Color(1, 1, 1, 0.5))
	ghost_timer = 0.0
	if input_dir != 0:
		dash_direction = 1 if input_dir > 0 else -1
		facing_right = dash_direction > 0
	else:
		dash_direction = 1 if facing_right else -1


	if facing_right != prev_facing_right:
		_update_sprites_facing()
		prev_facing_right = facing_right

	_squish(0.6, 1.4)

func _squish(scale_x_mult: float, scale_y_mult: float) -> void :
	var base = abs(sprite.scale.x)
	target_scale_x = base * scale_x_mult
	target_scale_y = base * scale_y_mult

func _apply_squish(delta: float) -> void :
	var current_x = abs(sprite.scale.x)
	var current_y = abs(sprite.scale.y)
	var new_x = lerp(current_x, target_scale_x, squish_speed * delta)
	var new_y = lerp(current_y, target_scale_y, squish_speed * delta)

	sprite.scale.x = new_x * (1 if facing_right else -1)
	sprite.scale.y = new_y


	for spr in sprites:
		if spr:
			spr.scale = sprite.scale


	if head_sprite:
		head_sprite.scale = sprite.scale
	if tail_sprite:
		tail_sprite.scale = sprite.scale


	for eye in eye_sprites:
		if eye:
			eye.scale = sprite.scale

	target_scale_x = lerp(target_scale_x, 0.5, squish_speed * delta * 0.8)
	target_scale_y = lerp(target_scale_y, 0.5, squish_speed * delta * 0.8)

func _spawn_ghost() -> void :
	if ghost_scene == null or sprites.size() == 0:
		return
	var ghost: Node2D = ghost_scene.instantiate()
	get_parent().add_child(ghost)
	ghost.global_position = global_position

	var ghost_textures = [
		preload("res://spr/流明/残影1.png"), 
		preload("res://spr/流明/残影2.png"), 
		preload("res://spr/流明/残影3.png"), 
		preload("res://spr/流明/残影4.png"), 
	]
	var texture_to_use: Texture2D = ghost_textures[randi() % ghost_textures.size()]
	var color_to_use: Color

	if is_light_reflecting:
		color_to_use = Color(1, 0.8, 0, 0.9)
	else:
		color_to_use = sprite.modulate

	if ghost.has_method("setup"):
		ghost.setup(texture_to_use, color_to_use, ghost_lifetime * (1.5 if is_light_reflecting else 1.0))

	ghost.scale.x = abs(ghost.scale.x) * (1 if facing_right else -1)



func _spawn_jump_fx(dir: int, tint: Color, scale_mult: float) -> void :
	var holder = Node2D.new()
	holder.position = global_position + Vector2(0, 40)
	holder.z_index = -1
	get_parent().add_child(holder)

	var parts = CPUParticles2D.new()
	parts.amount = int(jet_particles * scale_mult)
	parts.lifetime = jet_lifetime
	parts.one_shot = true
	parts.explosiveness = 1.0
	parts.emitting = true

	parts.direction = Vector2( - dir * 0.35, 1.0)
	parts.spread = jet_spread
	parts.initial_velocity_min = jet_speed_min * scale_mult
	parts.initial_velocity_max = jet_speed_max * scale_mult
	parts.gravity = Vector2(0, 80)
	parts.scale_amount_min = 0.2
	parts.scale_amount_max = 0.55
	var grad = Gradient.new()
	grad.set_color(0, Color(tint.r, tint.g, tint.b, 1.0))
	grad.set_color(1, Color(tint.r, tint.g, tint.b, 0.0))
	var tex = GradientTexture2D.new()
	tex.gradient = grad
	tex.fill_from = Vector2(0, 0)
	tex.fill_to = Vector2(0, 1)
	parts.texture = tex
	var cramp = Gradient.new()
	cramp.set_color(0, Color(tint.r, tint.g, tint.b, 1.0))
	cramp.set_color(1, Color(tint.r, tint.g, tint.b, 0.0))
	parts.color_ramp = cramp
	holder.add_child(parts)

	var t = create_tween()
	t.tween_interval(0.45)
	t.tween_callback(holder.queue_free)

func add_contamination_source(source: TileMapLayer) -> void :
	if not contamination_bodies.has(source):
		contamination_bodies.append(source)

func remove_contamination_source(source: TileMapLayer) -> void :
	contamination_bodies.erase(source)

func _on_contamination_area_entered(area: Area2D) -> void :
	if area.is_in_group("Contamination"):
		if not contamination_bodies.has(area):
			contamination_bodies.append(area)

func _on_contamination_area_exited(area: Area2D) -> void :
	contamination_bodies.erase(area)

func _on_contamination_body_entered(body: Node2D) -> void :
	if body.is_in_group("Contamination"):
		if not contamination_bodies.has(body):
			contamination_bodies.append(body)

func _on_contamination_body_exited(body: Node2D) -> void :
	contamination_bodies.erase(body)

func _update_ui() -> void :
	if not health_bar or not vitality_bar:
		return
	health_bar.value = current_health
	health_label.text = "HP: %d/%d" % [int(current_health), int(max_health)]
	vitality_bar.value = current_vitality
	vitality_label.text = "VIT: %d/%d" % [int(current_vitality), int(max_vitality)]

	if current_health < 30:
		health_bar.modulate = Color.RED
		health_label.modulate = Color.RED
	else:
		health_bar.modulate = Color(0.2, 0.8, 0.2)
		health_label.modulate = Color.WHITE
	if current_vitality < 30:
		vitality_bar.modulate = Color(0.8, 0.2, 0.8)
		vitality_label.modulate = Color(0.8, 0.4, 0.8)
	else:
		vitality_bar.modulate = Color(0.2, 0.4, 0.8)
		vitality_label.modulate = Color.WHITE

func _mark_current_scene_unlocked() -> void :
	var path: = get_tree().current_scene.scene_file_path
	var mapping: = {
		"res://lab.tscn": "ch1", 
		"res://city.tscn": "ch2", 
		"res://scene.tscn": "ch3", 
		"res://lab_B.tscn": "sp1", 
		"res://city_B.tscn": "sp2", 
	}
	if mapping.has(path):
		var cfg: = ConfigFile.new()
		cfg.load("user://progress.cfg")
		cfg.set_value("unlocked", mapping[path], true)
		cfg.save("user://progress.cfg")

func _set_body_sprites_visible(v: bool) -> void :
	if sprite:
		sprite.visible = v
	for i in range(sprites.size()):
		if sprites[i]:
			sprites[i].visible = v and (i == current_sprite_index)
	if head_sprite:
		head_sprite.visible = v
	if tail_sprite:
		tail_sprite.visible = v
	for eye in eye_sprites:
		if eye:
			eye.visible = v

func _begin_dash_anim() -> void :
	_set_body_sprites_visible(false)
	if _dash_anim:
		_dash_anim.queue_free()
	_dash_anim = Sprite2D.new()
	_dash_anim.name = "DashAnim"
	_dash_anim.texture = _dash_anim_frames[0]
	_dash_anim.scale = Vector2(dash_anim_scale, dash_anim_scale)
	_dash_anim.position = dash_anim_offset
	_dash_anim.flip_h = not facing_right
	_dash_anim.z_index = 10
	add_child(_dash_anim)
	_dash_anim_frame = 0
	_dash_anim_frame_timer = 0.0

func _update_dash_anim(delta: float) -> void :
	if not _dash_anim:
		return
	_dash_anim_frame_timer += delta
	var frame_time: = dash_anim_duration / float(_dash_anim_frames.size())
	if _dash_anim_frame_timer >= frame_time:
		_dash_anim_frame_timer = 0.0
		_dash_anim_frame = min(_dash_anim_frame + 1, _dash_anim_frames.size() - 1)
		_dash_anim.texture = _dash_anim_frames[_dash_anim_frame]
		_dash_anim.flip_h = not facing_right

func _end_dash_anim() -> void :
	if _dash_anim:
		_dash_anim.queue_free()
		_dash_anim = null
	_set_body_sprites_visible(true)
	_hide_all_eyes()
	_update_expression_from_health()
