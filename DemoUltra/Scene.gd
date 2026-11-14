extends Area2D

@export var next_scene: PackedScene

var player_inside = false
var _hint: Node2D = null
var _interacted: bool = false

func _ready():
	body_entered.connect( func(body):
		if body.is_in_group("player"):
			player_inside = true
	)
	body_exited.connect( func(body):
		if body.is_in_group("player"):
			player_inside = false
	)
	_hint = load("res://interact_hint.gd").new()
	_hint.top_level = true
	add_child(_hint)
	_hint.setup(global_position, Color(0.48, 0.9, 1.0, 1.0))

func _process(_delta):
	if player_inside and not _interacted and Input.is_action_just_pressed("interact"):
		_interacted = true
		_clear_hint()
		if next_scene:
			get_tree().change_scene_to_packed(next_scene)

func _clear_hint() -> void :
	if _hint and is_instance_valid(_hint):
		_hint.visible = false
		_hint.queue_free()
	_hint = null
