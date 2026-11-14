extends Area2D

@export var target_to_remove: StaticBody2D

@export var sound_effect: AudioStream

@onready var particles: CPUParticles2D = $CPUParticles2D if has_node("CPUParticles2D") else null
@onready var sprite: Sprite2D = $Sprite2D if has_node("Sprite2D") else null

var player_in_range: bool = false
var tween: Tween
var sound_played: bool = false
var _hint: Node2D = null
var _interacted: bool = false

static var shared_audio_player: AudioStreamPlayer

func _ready() -> void :
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_start_shimmer()
	_spawn_interact_hint()

	_initialize_shared_audio_player()

func _spawn_interact_hint() -> void :
	_hint = load("res://interact_hint.gd").new()
	_hint.top_level = true
	add_child(_hint)
	_hint.setup(global_position, Color(1.0, 0.84, 0.32, 1.0))

func _initialize_shared_audio_player() -> void :
	if not shared_audio_player:
		shared_audio_player = AudioStreamPlayer.new()
		add_child(shared_audio_player)


	if shared_audio_player and not shared_audio_player.stream and sound_effect:
		shared_audio_player.stream = sound_effect



func _on_body_entered(body: Node2D) -> void :
	if body.is_in_group("player"):
		player_in_range = true
		_on_player_near()

func _on_body_exited(body: Node2D) -> void :
	if body.is_in_group("player"):
		player_in_range = false


func _on_player_near() -> void :
	if sprite:
		var near_tween = create_tween()
		near_tween.tween_property(sprite, "modulate", Color(1.3, 1.3, 1.0), 0.1)
		near_tween.tween_property(sprite, "modulate", Color.WHITE, 0.2)


func _input(event: InputEvent) -> void :
	if not player_in_range:
		return
	if Input.is_action_just_pressed("interact"):
		_on_interact()

func _on_interact() -> void :
	if _interacted:
		return
	_interacted = true
	_clear_hint()

	if shared_audio_player and shared_audio_player.stream and not sound_played:
		shared_audio_player.play()
		sound_played = true


	if particles:
		particles.emitting = true
		await get_tree().create_timer(0.3).timeout
		particles.emitting = false

	if sprite:
		if tween and tween.is_valid():
			tween.kill()
		sprite.modulate = Color.WHITE
		var burst_tween = create_tween()
		burst_tween.tween_property(sprite, "modulate", Color(2, 2, 2), 0.05)
		burst_tween.tween_property(sprite, "modulate", Color.WHITE, 0.15)
		burst_tween.tween_callback(_start_shimmer)

	if target_to_remove:
		target_to_remove.queue_free()

func _clear_hint() -> void :
	if _hint and is_instance_valid(_hint):
		_hint.visible = false
		_hint.queue_free()
	_hint = null





func _start_shimmer() -> void :
	if not sprite:
		return
	tween = create_tween()
	tween.set_loops()
	tween.tween_property(sprite, "modulate:a", 0.5, 0.7)
	tween.tween_property(sprite, "modulate:a", 1.0, 0.7)
