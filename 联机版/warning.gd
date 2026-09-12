extends Area2D

@export var boss: Boss

func _ready():
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	if not body_exited.is_connected(_on_body_exited):
		body_exited.connect(_on_body_exited)

func _on_body_entered(body):
	print("111")
	if body.is_in_group("player"):

		boss.player_entered_warning(body)

func _on_body_exited(body):
	if body.is_in_group("player"):
		boss.player_exited_warning(body)
