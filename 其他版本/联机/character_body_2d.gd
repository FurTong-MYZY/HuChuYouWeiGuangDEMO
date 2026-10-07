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
var movement_bonus: float = 0.0


var animation_timer: float = 0.0
var sprites: Array[Sprite2D] = []
var current_sprite_index: int = 0
var prev_sprite_index: int = 0


var coyote_timer: float = 0.0
var was_on_floor: bool = false

var allow_air_jump: bool = false


var ui: Control
var health_bar: ProgressBar
var vitality_bar: ProgressBar
var satiety_bar: ProgressBar
var health_label: Label
var vitality_label: Label
var satiety_label: Label
var death_screen: ColorRect = null


var max_satiety: float = 100.0
var current_satiety: float = 100.0
var satiety_drain_rate: float = 0.5
var satiety_danger_threshold: float = 20.0
var satiety_hurt_hp: float = 5.0
var satiety_hurt_vit: float = 5.0
var berry_satiety_restore: float = 30.0
var _satiety_hurt_timer: float = 0.0
var _satiety_hp_timer: float = 0.0


const INVENTORY_SIZE: = 6
const ITEM_BERRY: = "berry"
var inventory: Array = []
var selected_slot: int = -1
var inventory_slot_panels: Array = []
var inventory_slot_labels: Array = []
var inventory_slot_icons: Array = []
var inventory_container: HBoxContainer
var _berry_icon_texture: Texture2D
var _slot_box_normal: StyleBoxFlat
var _slot_box_selected: StyleBoxFlat


@onready var audio_player: AudioStreamPlayer2D = $AudioStreamPlayer2D


@onready var sprite: Sprite2D = $Sprite2D


var expression_timer: float = 0.0
var current_expression: String = "none"
var is_expression_active: bool = false


var head_initial_position: Vector2
var tail_initial_position: Vector2
var tail_initial_rotation: float
var current_head_offset: Vector2 = Vector2.ZERO
var current_head_rotation: float = 0.0
var current_tail_rotation: float = 0.0


var eye_relative_offset: Vector2 = Vector2(-28, 70)


var eye_sprites: Array[Sprite2D] = []


const EXPRESSIONS: Array[String] = ["none", "happy_happy", "happy_squint", "squint_happy", "squint_squint", "pain"]


var _net_sync_timer: float = 0.0
const NET_SYNC_INTERVAL: = 1.0 / 30.0

func _ready() -> void :

	inventory.clear()
	for i in range(INVENTORY_SIZE):
		inventory.append("")

	air_dashes_left = max_air_dashes
	target_scale_x = abs(sprite.scale.x)
	target_scale_y = abs(sprite.scale.y)
	current_health = max_health
	current_vitality = max_vitality

	_create_contamination_detector()

	if is_multiplayer_authority():
		_create_ui()

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

	await get_tree().process_frame

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

func _clear_expression() -> void :
	_hide_all_eyes()
	current_expression = "none"
	is_expression_active = false
	expression_timer = 0.0


func _apply_expression_index(idx: int) -> void :
	if idx < 0 or idx >= EXPRESSIONS.size():
		return
	current_expression = EXPRESSIONS[idx]
	match current_expression:
		"happy_happy":
			_set_eye_expression(eye_left_happy, eye_right_happy)
		"happy_squint":
			_set_eye_expression(eye_left_happy, eye_right_squint)
		"squint_happy":
			_set_eye_expression(eye_left_squint, eye_right_happy)
		"squint_squint":
			_set_eye_expression(eye_left_squint, eye_right_squint)
		"pain":
			_set_eye_expression(eye_left_pain, eye_right_pain)
		_:
			_hide_all_eyes()


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

	var spacer2 = Control.new()
	spacer2.custom_minimum_size = Vector2(0, 5)
	container.add_child(spacer2)

	satiety_label = Label.new()
	satiety_label.text = "SAT: 100/100"
	satiety_label.add_theme_color_override("font_color", Color.WHITE)
	satiety_label.add_theme_font_size_override("font_size", 18)
	container.add_child(satiety_label)

	satiety_bar = ProgressBar.new()
	satiety_bar.min_value = 0
	satiety_bar.max_value = max_satiety
	satiety_bar.value = current_satiety
	satiety_bar.size_flags_horizontal = Control.SIZE_FILL
	satiety_bar.custom_minimum_size = Vector2(230, 20)
	satiety_bar.modulate = Color(0.9, 0.7, 0.2)
	container.add_child(satiety_bar)

	ui.add_child(container)
	canvas_layer.add_child(ui)
	add_child(canvas_layer)


	_create_inventory_ui()



func _create_inventory_ui() -> void :

	_berry_icon_texture = _make_berry_icon_texture()
	_slot_box_normal = StyleBoxFlat.new()
	_slot_box_normal.bg_color = Color(0, 0, 0, 0.45)
	_slot_box_normal.set_border_width_all(2)
	_slot_box_normal.border_color = Color(1, 1, 1, 0.55)
	_slot_box_selected = StyleBoxFlat.new()
	_slot_box_selected.bg_color = Color(0, 0, 0, 0.55)
	_slot_box_selected.set_border_width_all(4)
	_slot_box_selected.border_color = Color(1, 0.85, 0.2, 1)

	var bar_layer: = CanvasLayer.new()
	bar_layer.name = "InventoryUI"
	bar_layer.layer = 15

	var bar_root: = Control.new()
	bar_root.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)

	bar_root.offset_left = -360
	bar_root.offset_top = -96
	bar_root.offset_right = 160
	bar_root.offset_bottom = -20
	bar_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar_layer.add_child(bar_root)

	inventory_container = HBoxContainer.new()
	inventory_container.add_theme_constant_override("separation", 8)
	inventory_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inventory_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	bar_root.add_child(inventory_container)

	for i in range(INVENTORY_SIZE):
		var panel: = PanelContainer.new()
		panel.custom_minimum_size = Vector2(72, 72)
		panel.mouse_filter = Control.MOUSE_FILTER_STOP
		panel.add_theme_stylebox_override("panel", _slot_box_normal)
		var wrap: = Control.new()
		wrap.set_anchors_preset(Control.PRESET_FULL_RECT)
		wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.add_child(wrap)
		var lbl: = Label.new()
		lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", 20)
		lbl.text = "空"
		wrap.add_child(lbl)
		var icon: = TextureRect.new()
		icon.set_anchors_preset(Control.PRESET_FULL_RECT)
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon.texture = _berry_icon_texture
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.visible = false
		wrap.add_child(icon)

		var idx: = i
		panel.gui_input.connect( func(event: InputEvent) -> void :
			if event is InputEventMouseButton and event.pressed:
				if event.button_index == MOUSE_BUTTON_LEFT:
					selected_slot = idx
					_update_inventory_ui()
				elif event.button_index == MOUSE_BUTTON_RIGHT:
					_eat_berry(idx)
		)
		inventory_container.add_child(panel)
		inventory_slot_panels.append(panel)
		inventory_slot_labels.append(lbl)
		inventory_slot_icons.append(icon)

	add_child(bar_layer)
	_update_inventory_ui()



func _make_berry_icon_texture() -> Texture2D:
	return load("res://spr/杂物/浆果.png") as Texture2D

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

	var _peer: = multiplayer.multiplayer_peer
	if _peer == null:
		return
	if _peer is ENetMultiplayerPeer and (_peer as ENetMultiplayerPeer).get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED:
		return
	if not is_multiplayer_authority():
		return
	if is_dead:
		return

	if is_bouncing_from_bumper:
		_update_ui()
		_update_vitality_and_health(delta)
		_update_satiety(delta)
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

	if is_expression_active:
		expression_timer -= delta
		if expression_timer <= 0:
			_clear_expression()

	_update_ui()
	_update_vitality_and_health(delta)
	_update_satiety(delta)
	_update_contamination_damage(delta)

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

		ghost_timer -= delta
		if ghost_timer <= 0:
			ghost_timer = ghost_interval
			_spawn_ghost()

		if dash_timer <= 0:
			if touching_bricks > 0:
				allow_air_jump = true
				movement_bonus = min(movement_bonus + movement_bonus_on_dash_end_brick, movement_bonus_max)
			is_dashing = false

		_update_head_tail_animation(delta, 0.0)
		_apply_squish(delta)
		move_and_slide()
		return

	var input_dir: = Input.get_axis("move_left", "move_right")

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

	if Input.is_action_just_pressed("jump"):
		if is_on_floor() or coyote_timer > 0:
			velocity.y = - current_jump
			_squish(0.8, 1.2)
			coyote_timer = 0.0
			_update_expression_from_health()
			is_expression_active = true
			expression_timer = expression_duration
		elif allow_air_jump:
			velocity.y = - current_jump * 0.9
			_squish(0.8, 1.2)
			allow_air_jump = false
			_update_expression_from_health()
			is_expression_active = true
			expression_timer = expression_duration

	if Input.is_action_just_released("jump") and velocity.y < 0:
		velocity.y *= 0.5

	if Input.is_action_just_pressed("dash"):
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
	_apply_squish(delta)


	_send_net_state(delta)

func _send_net_state(delta: float) -> void :
	_net_sync_timer -= delta
	if _net_sync_timer > 0.0:
		return
	_net_sync_timer = NET_SYNC_INTERVAL

	var expr_idx: = EXPRESSIONS.find(current_expression)
	if expr_idx < 0:
		expr_idx = 0
	_sync_state.rpc(global_position, velocity, facing_right, current_sprite_index, is_dashing, 
		expr_idx, current_head_offset, current_head_rotation, current_tail_rotation, is_dead, 
		sprite.modulate)

@rpc("authority", "unreliable", "call_remote")
func _sync_state(pos: Vector2, vel: Vector2, facing: bool, sprite_idx: int, dashing: bool, 
		expr_idx: int, head_offset: Vector2, head_rot: float, tail_rot: float, dead: bool, 
		body_color: Color) -> void :

	global_position = pos
	velocity = vel
	facing_right = facing
	is_dashing = dashing
	if current_sprite_index != sprite_idx:
		current_sprite_index = sprite_idx
		_update_sprite_visibility()
		prev_sprite_index = sprite_idx

	if prev_facing_right != facing_right:
		_update_sprites_facing()
		prev_facing_right = facing_right

	_apply_expression_index(expr_idx)

	current_head_offset = head_offset
	current_head_rotation = head_rot
	current_tail_rotation = tail_rot
	if head_sprite:
		head_sprite.position = head_initial_position + current_head_offset
		head_sprite.rotation = deg_to_rad(current_head_rotation)
		_update_eye_positions()
	if tail_sprite:
		tail_sprite.rotation = tail_initial_rotation + deg_to_rad(current_tail_rotation)

	is_dead = dead

	if sprite.modulate != body_color:
		_set_all_sprites_modulate(body_color)

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


	if abs(velocity.x) > 10:
		var horizontal_factor = velocity.x / speed
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



func _update_satiety(delta: float) -> void :
	current_satiety = max(current_satiety - satiety_drain_rate * delta, 0.0)
	if current_satiety <= 0.0:

		_satiety_hurt_timer -= delta
		if _satiety_hurt_timer <= 0.0:
			_satiety_hurt_timer = 1.0
			current_vitality = max(current_vitality - satiety_hurt_vit, 0.0)
		_satiety_hp_timer -= delta
		if _satiety_hp_timer <= 0.0:
			_satiety_hp_timer = 3.0
			current_health = max(current_health - satiety_hurt_hp, 0.0)
			_trigger_damage_feedback()
			if current_health <= 0:
				_die()
	elif current_satiety < satiety_danger_threshold:

		_satiety_hurt_timer -= delta
		if _satiety_hurt_timer <= 0.0:
			_satiety_hurt_timer = 1.0
			current_vitality = max(current_vitality - satiety_hurt_vit, 0.0)
	_update_ui()







func add_berry_to_inventory() -> bool:
	for i in range(INVENTORY_SIZE):
		if inventory[i] == "":
			inventory[i] = ITEM_BERRY
			_update_inventory_ui()
			return true
	return false



func _eat_berry(slot: int) -> void :
	if slot < 0 or slot >= INVENTORY_SIZE:
		return
	if inventory[slot] != ITEM_BERRY:
		return
	inventory[slot] = ""
	current_satiety = min(current_satiety + berry_satiety_restore, max_satiety)
	_update_inventory_ui()
	_update_ui()



func _drop_selected_item() -> void :
	if selected_slot < 0 or selected_slot >= INVENTORY_SIZE:
		return
	if inventory[selected_slot] != ITEM_BERRY:
		return
	inventory[selected_slot] = ""
	_update_inventory_ui()

	var dir: = 1.0 if facing_right else -1.0
	var drop_pos: = global_position + Vector2(dir * 120.0, -60.0)
	var throw_vel: = Vector2(dir * 700.0, -500.0)
	if Network and Network.has_method("request_drop"):
		Network.request_drop(drop_pos, throw_vel)



func _update_inventory_ui() -> void :
	for i in range(INVENTORY_SIZE):
		if i >= inventory_slot_panels.size():
			break
		var panel: PanelContainer = inventory_slot_panels[i]
		var lbl: Label = inventory_slot_labels[i]
		var icon: TextureRect = inventory_slot_icons[i]
		var has_berry: bool = (inventory[i] == ITEM_BERRY)
		if has_berry:
			lbl.text = ""
			icon.visible = true
		else:
			lbl.text = "空"
			icon.visible = false

		if i == selected_slot:
			panel.add_theme_stylebox_override("panel", _slot_box_selected)
		else:
			panel.add_theme_stylebox_override("panel", _slot_box_normal)


func _unhandled_input(event: InputEvent) -> void :

	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_Q:
			_drop_selected_item()



func _print_inventory() -> void :
	print("[Player] 物品栏=", inventory, " 饱食度=", int(current_satiety), " HP=", int(current_health), " VIT=", int(current_vitality))

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


	if Network and Network.has_method("notify_player_died"):
		Network.notify_player_died()

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

	if multiplayer.multiplayer_peer != null:
		_respawn_network()
		return
	get_tree().reload_current_scene()

func _respawn_network() -> void :
	if not is_multiplayer_authority():
		return
	current_health = max_health
	current_vitality = max_vitality
	current_satiety = max_satiety
	is_dead = false
	is_invincible = false
	is_dashing = false
	velocity = Vector2.ZERO
	_set_all_sprites_modulate(Color.WHITE)
	if death_screen:
		death_screen.queue_free()
		death_screen = null

	var scene = get_tree().current_scene
	var spawn_marker = scene.get_node_or_null("SpawnPoint") if scene else null
	if spawn_marker:
		global_position = spawn_marker.global_position
	else:
		global_position = Network.get_spawn_point(multiplayer.get_unique_id())
	_update_ui()

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

	_play_dash_sound(is_light_reflecting)

	if is_light_reflecting:
		_set_all_sprites_modulate(Color(1, 0.9, 0, 0.8))
	else:
		_set_all_sprites_modulate(Color(1, 1, 1, 0.5))
	ghost_timer = 0.0
	if input_dir != 0:
		dash_direction = int(input_dir)
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

	var random_index = randi() % sprites.size()
	var random_sprite = sprites[random_index]
	var texture_to_use = random_sprite.texture
	var color_to_use: Color

	if is_light_reflecting:
		color_to_use = Color(1, 0.8, 0, 0.9)
	else:
		color_to_use = sprite.modulate

	if ghost.has_method("setup"):
		ghost.setup(texture_to_use, color_to_use, ghost_lifetime * (1.5 if is_light_reflecting else 1.0))

	ghost.scale.x = abs(ghost.scale.x) * (1 if facing_right else -1)

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
	if satiety_bar and satiety_label:
		satiety_bar.value = current_satiety
		satiety_label.text = "SAT: %d/%d" % [int(current_satiety), int(max_satiety)]

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
	if satiety_bar and satiety_label:
		if current_satiety < satiety_danger_threshold:
			satiety_bar.modulate = Color.RED
			satiety_label.modulate = Color.RED
		else:
			satiety_bar.modulate = Color(0.9, 0.7, 0.2)
			satiety_label.modulate = Color.WHITE
