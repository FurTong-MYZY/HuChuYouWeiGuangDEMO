extends Area2D

@export var wind_force: float = 400.0
@export var wind_direction: Vector2 = Vector2(0, -1)
@export var player_layer: int = 1

var bodies_in_wind: Array = []


func _ready() -> void :
	collision_layer = 0
	collision_mask = player_layer

	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node2D) -> void :
	if body is CharacterBody2D:
		if not bodies_in_wind.has(body):
			bodies_in_wind.append(body)


func _on_body_exited(body: Node2D) -> void :
	bodies_in_wind.erase(body)


func _physics_process(delta: float) -> void :
	for body in bodies_in_wind:
		if is_instance_valid(body) and body is CharacterBody2D:
			body.velocity += wind_direction * wind_force * delta
