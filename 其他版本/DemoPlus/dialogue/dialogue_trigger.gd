extends Area2D






class_name DialogueTrigger

enum Mode{ON_ENTER, ON_INTERACT}

@export var dialogue_id: String = ""
@export var trigger_mode: Mode = Mode.ON_INTERACT
@export var one_shot: bool = false
@export_multiline var hint_text: String = ""

const ACCENT: = Color(0.835, 0.698, 0.42)
const TEXT_COLOR: = Color(0.965, 0.94, 0.86)
const PANEL_BG: = Color(0.075, 0.07, 0.085, 0.85)

var _player_in_range: = false
var _triggered: = false
var _hint: PanelContainer = null
var _hint_label: Label = null
var _bob_tween: Tween = null
var _cooldown: float = 0.0

func _ready() -> void :
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	if trigger_mode == Mode.ON_INTERACT:
		_build_hint()
	DialogueManager.dialogue_ended.connect(_on_dialogue_ended)


func _build_hint() -> void :
	_hint = PanelContainer.new()
	var sb: = StyleBoxFlat.new()
	sb.bg_color = PANEL_BG
	sb.set_corner_radius_all(18)
	sb.set_border_width_all(1)
	sb.border_color = Color(ACCENT.r, ACCENT.g, ACCENT.b, 0.55)
	sb.content_margin_left = 14
	sb.content_margin_right = 14
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	sb.shadow_color = Color(0, 0, 0, 0.35)
	sb.shadow_size = 8
	sb.shadow_offset = Vector2(0, 4)
	_hint.add_theme_stylebox_override("panel", sb)

	_hint_label = Label.new()
	_hint_label.text = hint_text if not hint_text.is_empty() else "按 交互键 对话"
	_hint_label.add_theme_font_size_override("font_size", 54)
	_hint_label.add_theme_color_override("font_color", TEXT_COLOR)
	_hint_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.6))
	_hint_label.add_theme_constant_override("shadow_offset_x", 1)
	_hint_label.add_theme_constant_override("shadow_offset_y", 1)
	_hint.add_child(_hint_label)

	_hint.visible = false
	_hint.modulate.a = 0.0
	add_child(_hint)
	_hint.reset_size()
	_hint.position = Vector2( - _hint.size.x * 0.5, -74.0)

func _show_hint() -> void :
	if _hint == null:
		return
	_hint.visible = true
	if _bob_tween and _bob_tween.is_valid():
		_bob_tween.kill()
	var tw: = create_tween()
	tw.tween_property(_hint, "modulate:a", 1.0, 0.2)
	_bob_tween = create_tween().set_loops()
	_bob_tween.tween_property(_hint, "position:y", -66.0, 0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_bob_tween.tween_property(_hint, "position:y", -82.0, 0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _hide_hint() -> void :
	if _hint == null:
		return
	if _bob_tween and _bob_tween.is_valid():
		_bob_tween.kill()
	_hint.visible = false


func _on_body_entered(body: Node2D) -> void :
	if not body.is_in_group("player"):
		return
	_player_in_range = true
	if trigger_mode == Mode.ON_ENTER:
		_fire()
	else:
		_show_hint()

func _on_body_exited(body: Node2D) -> void :
	if not body.is_in_group("player"):
		return
	_player_in_range = false
	_hide_hint()

func _unhandled_input(event: InputEvent) -> void :
	if trigger_mode != Mode.ON_INTERACT:
		return
	if not _player_in_range:
		return
	if event.is_action_pressed("interact"):
		_fire()

func _process(delta: float) -> void :
	if _cooldown > 0.0:
		_cooldown -= delta
		return
	if trigger_mode != Mode.ON_INTERACT:
		return
	if not _player_in_range:
		return
	if Input.is_action_just_pressed("interact"):
		_fire()

func _fire() -> void :
	if DialogueManager.active:
		return
	if DialogueManager.start_dialogue(dialogue_id):
		_hide_hint()

func _on_dialogue_ended() -> void :
	_cooldown = 0.5
	if one_shot:
		return
	if trigger_mode == Mode.ON_INTERACT and _player_in_range and monitoring:
		_show_hint()
