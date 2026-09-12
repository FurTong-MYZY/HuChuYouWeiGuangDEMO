extends Node2D



@export var bush_id: int = 1
@export var harvest_duration: float = 2.0
@export var bush_texture: Texture2D
@export var bush_scale: float = 0.8

var harvested: = false
var _harvesting: = false
var _harvest_timer: = 0.0
var _players_near: Array = []
var _visual: Node2D
var _progress_label: Label


func is_berry_bush() -> bool:
	return true


func is_harvested() -> bool:
	return harvested


func _ready() -> void :
	_build_visual()
	_build_progress_label()
	var area: = Area2D.new()
	area.name = "PickupArea"
	area.collision_mask = 3
	var shape: = CollisionShape2D.new()
	var circle: = CircleShape2D.new()
	circle.radius = 500.0
	shape.shape = circle
	area.add_child(shape)
	add_child(area)
	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)


func _process(delta: float) -> void :
	if harvested:
		return
	var has_local_player: = false
	for p in _players_near:
		if is_instance_valid(p) and p.is_multiplayer_authority():
			has_local_player = true
			break

	if has_local_player and Input.is_action_just_pressed("interact") and not _harvesting:
		_start_harvest()
	if _harvesting:
		_harvest_timer -= delta
		_update_progress()
		if _harvest_timer <= 0.0:
			_harvesting = false
			_hide_progress()

			if Network and Network.has_method("request_harvest"):
				Network.request_harvest(bush_id)



func on_harvested() -> void :
	harvested = true
	_harvesting = false
	if _visual:
		_visual.visible = false
	if _progress_label:
		_progress_label.visible = false

	var area: = get_node_or_null("PickupArea")
	if area:
		area.set_deferred("monitoring", false)


func _start_harvest() -> void :
	_harvesting = true
	_harvest_timer = harvest_duration
	if _progress_label:
		_progress_label.visible = true
	_update_progress()


func _update_progress() -> void :
	if _progress_label:
		var pct: = int((1.0 - _harvest_timer / harvest_duration) * 100.0)
		_progress_label.text = "采集中 %d%%" % pct


func _hide_progress() -> void :
	if _progress_label:
		_progress_label.visible = false


func _on_body_entered(body: Node2D) -> void :
	if body.is_in_group("player") and not _players_near.has(body):
		_players_near.append(body)


func _on_body_exited(body: Node2D) -> void :
	_players_near.erase(body)




func _build_visual() -> void :
	_visual = Node2D.new()
	_visual.name = "Visual"
	add_child(_visual)
	var spr: = Sprite2D.new()
	spr.name = "BushSprite"
	spr.texture = bush_texture
	spr.scale = Vector2(bush_scale, bush_scale)
	_visual.add_child(spr)


func _build_progress_label() -> void :
	_progress_label = Label.new()
	_progress_label.name = "ProgressLabel"
	_progress_label.position = Vector2(-800, -380)
	_progress_label.size = Vector2(1600, 140)
	_progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_progress_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_progress_label.visible = false
	_progress_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_progress_label.z_index = 100
	_progress_label.add_theme_font_size_override("font_size", 72)
	_progress_label.add_theme_color_override("font_color", Color.WHITE)
	_progress_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	_progress_label.add_theme_constant_override("outline_size", 14)
	add_child(_progress_label)
