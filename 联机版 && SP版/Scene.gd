extends Area2D

@export var next_scene: PackedScene

var player_inside = false

func _ready():
	body_entered.connect( func(body):
		if body.is_in_group("player"):
			player_inside = true
	)
	body_exited.connect( func(body):
		if body.is_in_group("player"):
			player_inside = false
	)

func _unhandled_input(event):
	if player_inside and event.is_action_pressed("interact"):
		get_tree().change_scene_to_packed(next_scene)
