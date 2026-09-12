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
var health_label: Label
var vitality_label: Label


var death_screen: ColorRect = null


@onready var audio_player: AudioStreamPlayer2D = $AudioStreamPlayer2D

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void :
	air_dashes_left = max_air_dashes
	target_scale_x = abs(sprite.scale.x)
	target_scale_y = abs(sprite.scale.y)
	current_health = max_health
	current_vitality = max_vitality

	_create_contamination_detector()
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







	$Area2D.body_entered.connect(_on_brick_entered)
	$Area2D.body_exited.connect(_on_brick_exited)


	var timer = Timer.new()
	timer.wait_time = 1.0
	timer.autostart = true
	timer.timeout.connect( func(): print("当前触碰砖块数量: ", touching_bricks))
	add_child(timer)

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

func _set_all_sprites_modulate(color: Color) -> void :
	sprite.modulate = color
	for spr in sprites:
		if spr:
			spr.modulate = color

func _physics_process(delta: float) -> void :
	if is_dead:
		return











	if movement_bonus > 0:
		movement_bonus = max(movement_bonus - movement_bonus_decay_rate * delta, 0.0)

	if is_light_reflecting:
		light_reflect_timer -= delta
		if light_reflect_timer <= 0:
			is_light_reflecting = false

	_update_ui()
	_update_vitality_and_health(delta)
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

		elif allow_air_jump:
			velocity.y = - current_jump * 0.9
			_squish(0.8, 1.2)
			allow_air_jump = false


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



	_update_sprite_animation(delta, input_dir)

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
