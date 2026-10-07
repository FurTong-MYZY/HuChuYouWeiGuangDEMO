extends Area2D

@export var fade_duration: = 0.3

@onready var label: Label = $Label
var tween: Tween

func _ready() -> void :
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	label.modulate.a = 0.0

func _on_body_entered(body: Node2D) -> void :
	if not body.is_in_group("player"):
		return
	_fade_label(1.0)

func _on_body_exited(body: Node2D) -> void :
	if not body.is_in_group("player"):
		return
	_fade_label(0.0)

func _fade_label(target_alpha: float) -> void :

	if tween and tween.is_valid():
		tween.kill()

	tween = create_tween()
	tween.tween_property(label, "modulate:a", target_alpha, fade_duration)
