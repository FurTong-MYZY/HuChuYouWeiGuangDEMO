extends CanvasLayer




const ACCENT: = Color(0.835, 0.698, 0.42)
const ACCENT_SOFT: = Color(0.835, 0.698, 0.42, 0.4)
const TEXT_COLOR: = Color(0.965, 0.94, 0.86)
const PANEL_BG: = Color(0.075, 0.07, 0.085, 0.84)
const CHOICE_BG: = Color(0.1, 0.095, 0.11, 0.9)
const CHOICE_BG_HOVER: = Color(0.17, 0.16, 0.18, 0.96)
const DIM_COLOR: = Color(0, 0, 0, 0.38)


const CHAR_DELAY: = 0.038
const PUNCT_DELAY: = 0.17
const PANEL_MAX_WIDTH: = 1080.0
const PANEL_MARGIN_X: = 90.0
const PANEL_BOTTOM_OFFSET: = 72.0
const FONT_TEXT: = 26
const FONT_NAME: = 22
const FONT_HINT: = 18
const FONT_CHOICE: = 22
const _PUNCT: = "，。！？…、；：·,.!?;:"


var _dim: ColorRect
var _panel: PanelContainer
var _name_bar: ColorRect
var _name_label: Label
var _text_label: RichTextLabel
var _hint_label: Label
var _choices_box: VBoxContainer


var _full_text: = ""
var _displayed: = ""
var _typing: = false
var _type_done: = false
var _type_gen: = 0
var _current_line_id: = ""
var _shown_choices: Array = []
var _choice_focus: int = 0


var _audio: AudioStreamPlayer
var _type_sounds: Array[AudioStream] = []
var _advance_sound: AudioStream
var _select_sound: AudioStream

var _start_cooldown: float = 0.0
var _hint_tween: Tween

func _ready() -> void :
	layer = 200
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_build_ui()
	_generate_sounds()
	DialogueManager.dialogue_started.connect(_on_dialogue_started)
	DialogueManager.line_shown.connect(_on_line_shown)
	DialogueManager.dialogue_ended.connect(_on_dialogue_ended)
	get_viewport().size_changed.connect(_layout)




func _build_ui() -> void :

	_dim = ColorRect.new()
	_dim.color = DIM_COLOR
	_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_dim.gui_input.connect(_on_dim_gui_input)
	_dim.visible = false
	add_child(_dim)


	_panel = PanelContainer.new()
	_panel.anchor_left = 0.5
	_panel.anchor_right = 0.5
	_panel.anchor_top = 1.0
	_panel.anchor_bottom = 1.0
	_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_panel.offset_top = - PANEL_BOTTOM_OFFSET
	_panel.offset_bottom = - PANEL_BOTTOM_OFFSET
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb: = StyleBoxFlat.new()
	sb.bg_color = PANEL_BG
	sb.set_corner_radius_all(16)
	sb.set_border_width_all(1)
	sb.border_color = Color(ACCENT.r, ACCENT.g, ACCENT.b, 0.45)
	sb.shadow_color = Color(0, 0, 0, 0.4)
	sb.shadow_size = 20
	sb.shadow_offset = Vector2(0, 8)
	_panel.add_theme_stylebox_override("panel", sb)
	add_child(_panel)

	var margin: = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 34)
	margin.add_theme_constant_override("margin_right", 34)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 22)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(margin)

	var vbox: = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(vbox)


	var speaker_row: = HBoxContainer.new()
	speaker_row.add_theme_constant_override("separation", 12)
	speaker_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(speaker_row)

	_name_bar = ColorRect.new()
	_name_bar.color = ACCENT
	_name_bar.custom_minimum_size = Vector2(3, 20)
	_name_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	speaker_row.add_child(_name_bar)

	_name_label = Label.new()
	_name_label.add_theme_font_size_override("font_size", FONT_NAME)
	_name_label.add_theme_color_override("font_color", ACCENT)
	_name_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.5))
	_name_label.add_theme_constant_override("shadow_offset_x", 1)
	_name_label.add_theme_constant_override("shadow_offset_y", 1)
	speaker_row.add_child(_name_label)

	var divider: = ColorRect.new()
	divider.color = ACCENT_SOFT
	divider.custom_minimum_size = Vector2(0, 1)
	divider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	divider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	speaker_row.add_child(divider)


	_text_label = RichTextLabel.new()
	_text_label.bbcode_enabled = false
	_text_label.fit_content = true
	_text_label.scroll_active = false
	_text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_text_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_text_label.add_theme_font_size_override("normal_font_size", FONT_TEXT)
	_text_label.add_theme_color_override("default_color", TEXT_COLOR)
	_text_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.55))
	_text_label.add_theme_constant_override("shadow_offset_x", 2)
	_text_label.add_theme_constant_override("shadow_offset_y", 2)
	_text_label.add_theme_constant_override("line_spacing", 6)
	vbox.add_child(_text_label)


	var bottom_row: = HBoxContainer.new()
	bottom_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(bottom_row)

	var spacer: = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom_row.add_child(spacer)

	_hint_label = Label.new()
	_hint_label.text = "▼  按 交互键 继续"
	_hint_label.add_theme_font_size_override("font_size", FONT_HINT)
	_hint_label.add_theme_color_override("font_color", Color(ACCENT.r, ACCENT.g, ACCENT.b, 0.9))
	_hint_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.5))
	_hint_label.add_theme_constant_override("shadow_offset_x", 1)
	_hint_label.add_theme_constant_override("shadow_offset_y", 1)
	_hint_label.visible = false
	bottom_row.add_child(_hint_label)


	_choices_box = VBoxContainer.new()
	_choices_box.add_theme_constant_override("separation", 12)
	_choices_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_choices_box.visible = false
	add_child(_choices_box)

	_hide_name()
	_layout()




func _layout() -> void :
	var vp_size: = get_viewport().get_visible_rect().size
	var w: = minf(vp_size.x - PANEL_MARGIN_X * 2.0, PANEL_MAX_WIDTH)
	w = maxf(w, 360.0)
	_panel.custom_minimum_size.x = w
	_text_label.custom_minimum_size.x = w - 68.0
	_layout_choices()

func _layout_choices() -> void :
	if _choices_box.visible:
		_choices_box.reset_size()
		var vp_size: = get_viewport().get_visible_rect().size
		var w: = minf(vp_size.x - 240.0, 720.0)
		w = maxf(w, 300.0)
		for c in _choices_box.get_children():
			if c is Button:
				c.custom_minimum_size.x = w
		_choices_box.reset_size()
		var target_y: = vp_size.y * 0.3 - _choices_box.size.y * 0.5
		_choices_box.position = Vector2(
			(vp_size.x - _choices_box.size.x) * 0.5, 
			maxf(24.0, target_y)
		)




func _on_dialogue_started(_id: String) -> void :
	visible = true
	_start_cooldown = 0.25
	_dim.visible = false
	_dim.modulate.a = 0.0
	_panel.modulate.a = 0.0
	_panel.scale = Vector2(0.98, 0.98)
	_layout()
	var tw: = create_tween()
	tw.tween_property(_panel, "modulate:a", 1.0, 0.18)
	tw.parallel().tween_property(_panel, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _on_line_shown(node: Dictionary) -> void :
	_current_line_id = DialogueManager.current_id
	_hide_choices()
	_hide_continue_hint()

	var speaker: = str(node.get("speaker", ""))
	if speaker.is_empty():
		_hide_name()
	else:
		_name_label.text = speaker
		_name_bar.visible = true
		_name_label.visible = true

	_full_text = str(node.get("text", ""))
	_displayed = ""
	_typing = true
	_type_done = false
	_type_gen += 1
	_text_label.text = ""

	if _full_text.is_empty() and DialogueManager.get_choices().is_empty():

		_type_done = true
		_typing = false
		_await_routing_advance()
	else:
		_type_coroutine(_full_text, _type_gen)

func _on_dialogue_ended() -> void :
	_hide_choices()
	_hide_continue_hint()
	_typing = false
	_type_done = false
	var tw: = create_tween()
	tw.tween_property(_dim, "modulate:a", 0.0, 0.16)
	tw.parallel().tween_property(_panel, "modulate:a", 0.0, 0.16)
	tw.tween_callback( func() -> void :
		_dim.visible = false
		visible = false
		_dim.modulate.a = 1.0
		_panel.modulate.a = 1.0
		_panel.scale = Vector2.ONE
	)




func _type_coroutine(text: String, gen: int) -> void :
	var i: = 0
	while i < text.length() and _typing and gen == _type_gen:
		var ch: = text[i]
		_displayed += ch
		if not (ch in " \n\t"):
			_play_type_sound()
		_text_label.text = _displayed + "▍"
		var delay: = PUNCT_DELAY if (ch in _PUNCT) else CHAR_DELAY
		await get_tree().create_timer(delay).timeout
		i += 1
	if _typing and gen == _type_gen:
		_typing = false
		_text_label.text = _full_text
	_finish_line()

func _skip_typing() -> void :
	if not _typing:
		return
	_typing = false
	_text_label.text = _full_text
	_finish_line()

func _finish_line() -> void :
	if _type_done:
		return
	_type_done = true
	_typing = false
	_text_label.text = _full_text

	if not DialogueManager.get_choices().is_empty():
		_show_choices(DialogueManager.get_choices())
		return

	_show_continue_hint()
	var wait: = float(DialogueManager.current_node.get("wait", 0.0))
	if wait > 0.0:
		var line_id: = _current_line_id
		await get_tree().create_timer(wait).timeout
		if DialogueManager.active and DialogueManager.current_id == line_id:
			DialogueManager.advance()

func _await_routing_advance() -> void :
	var line_id: = _current_line_id
	await get_tree().create_timer(0.01).timeout
	if DialogueManager.active and DialogueManager.current_id == line_id:
		DialogueManager.advance()




func _show_choices(choices: Array) -> void :
	for c in _choices_box.get_children():
		_choices_box.remove_child(c)
		c.queue_free()
	_shown_choices = []
	_choice_focus = 0

	for i in choices.size():
		var choice: Dictionary = choices[i]
		var btn: = Button.new()
		btn.text = str(choice.get("text", ""))
		btn.add_theme_font_size_override("font_size", FONT_CHOICE)
		btn.focus_mode = Control.FOCUS_NONE
		var idx: = i
		btn.pressed.connect( func() -> void : _choose(idx))
		btn.mouse_entered.connect( func() -> void :
			_choice_focus = idx
			_refresh_choice_styles()
		)
		_choices_box.add_child(btn)
		_shown_choices.append(btn)

	_choices_box.visible = true
	_dim.visible = true
	_dim.modulate.a = 1.0
	_layout_choices()
	_refresh_choice_styles()

	for i in _shown_choices.size():
		var b: Button = _shown_choices[i]
		b.modulate.a = 0.0
		var tw: = create_tween().bind_node(b)
		tw.tween_interval(i * 0.06)
		tw.tween_property(b, "modulate:a", 1.0, 0.16)

func _refresh_choice_styles() -> void :
	for i in _shown_choices.size():
		var b: Button = _shown_choices[i]
		var selected: = (i == _choice_focus)
		b.add_theme_color_override("font_color", Color.WHITE if selected else TEXT_COLOR)
		b.add_theme_stylebox_override("normal", _choice_style(selected))
		b.add_theme_stylebox_override("hover", _choice_style(selected))
		b.add_theme_stylebox_override("pressed", _choice_style(true, true))
		b.add_theme_stylebox_override("focus", _choice_style(selected))

func _hide_choices() -> void :
	_choices_box.visible = false
	_dim.visible = false
	_dim.modulate.a = 0.0
	for c in _choices_box.get_children():
		_choices_box.remove_child(c)
		c.queue_free()
	_shown_choices = []
	_choice_focus = 0

func _choose(index: int) -> void :
	if not DialogueManager.active:
		return
	_play_select_sound()
	_hide_choices()
	DialogueManager.choose(index)

func _choice_style(selected: bool, pressed: bool = false) -> StyleBoxFlat:
	var sb: = StyleBoxFlat.new()
	if pressed:
		sb.bg_color = Color(0.06, 0.055, 0.065, 0.95)
	else:
		sb.bg_color = CHOICE_BG_HOVER if selected else CHOICE_BG
	sb.set_corner_radius_all(22)
	sb.set_border_width_all(2 if selected else 1)
	sb.border_color = Color(ACCENT.r, ACCENT.g, ACCENT.b, 1.0 if selected else 0.35)
	sb.content_margin_left = 26
	sb.content_margin_right = 26
	sb.content_margin_top = 13
	sb.content_margin_bottom = 13
	sb.shadow_color = Color(0, 0, 0, 0.35)
	sb.shadow_size = 8 if selected else 4
	sb.shadow_offset = Vector2(0, 3)
	return sb




func _show_continue_hint() -> void :
	_hint_label.visible = true
	_hint_label.modulate.a = 1.0
	if _hint_tween and _hint_tween.is_valid():
		_hint_tween.kill()
	_hint_tween = create_tween().set_loops()
	_hint_tween.tween_property(_hint_label, "modulate:a", 0.35, 0.55).set_trans(Tween.TRANS_SINE)
	_hint_tween.tween_property(_hint_label, "modulate:a", 1.0, 0.55).set_trans(Tween.TRANS_SINE)

func _hide_continue_hint() -> void :
	if _hint_tween and _hint_tween.is_valid():
		_hint_tween.kill()
	_hint_label.visible = false




func _process(_delta: float) -> void :

	if not DialogueManager.active:
		return
	if not Input.is_action_just_pressed("interact"):
		return
	if not _shown_choices.is_empty():
		_choose(_choice_focus)
	elif _typing:
		_skip_typing()
		_play_select_sound()
	else:
		_play_advance_sound()
		DialogueManager.advance()

func _unhandled_input(event: InputEvent) -> void :
	if _start_cooldown > 0.0:
		return
	if not DialogueManager.active:
		return

	if not _shown_choices.is_empty():
		if event.is_action_pressed("ui_up") or event.is_action_pressed("move_up"):
			_choice_focus = wrapi(_choice_focus - 1, 0, _shown_choices.size())
			_refresh_choice_styles()
			get_viewport().set_input_as_handled()
			return
		if event.is_action_pressed("ui_down") or event.is_action_pressed("move_down"):
			_choice_focus = wrapi(_choice_focus + 1, 0, _shown_choices.size())
			_refresh_choice_styles()
			get_viewport().set_input_as_handled()
			return
		if event.is_action_pressed("interact"):
			_choose(_choice_focus)
			get_viewport().set_input_as_handled()
			return
		return

	if event.is_action_pressed("interact"):
		if _typing:
			_skip_typing()
			_play_select_sound()
			get_viewport().set_input_as_handled()
			return
		_play_advance_sound()
		DialogueManager.advance()
		get_viewport().set_input_as_handled()

func _on_dim_gui_input(event: InputEvent) -> void :
	if not DialogueManager.active:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if _typing:
			_skip_typing()
			_play_select_sound()
			return
		if not _shown_choices.is_empty():
			return
		_play_advance_sound()
		DialogueManager.advance()




func _generate_sounds() -> void :
	_audio = AudioStreamPlayer.new()
	_audio.volume_db = -10.0
	add_child(_audio)
	_type_sounds.append(_make_tone(1560.0, 0.03, 0.5))
	_type_sounds.append(_make_tone(1240.0, 0.032, 0.5))
	_type_sounds.append(_make_tone(1830.0, 0.026, 0.45))
	_advance_sound = _make_tone(720.0, 0.07, 0.6)
	_select_sound = _make_tone(980.0, 0.05, 0.55)

func _play_type_sound() -> void :
	if _type_sounds.is_empty() or _audio == null:
		return
	_audio.stream = _type_sounds[randi() % _type_sounds.size()]
	_audio.pitch_scale = randf_range(0.92, 1.12)
	_audio.play()

func _play_advance_sound() -> void :
	if _advance_sound == null or _audio == null:
		return
	_audio.stream = _advance_sound
	_audio.pitch_scale = 1.0
	_audio.play()

func _play_select_sound() -> void :
	if _select_sound == null or _audio == null:
		return
	_audio.stream = _select_sound
	_audio.pitch_scale = randf_range(0.9, 1.1)
	_audio.play()

func _make_tone(freq: float, dur: float, amp: float) -> AudioStreamWAV:
	var sr: = 22050
	var n: = int(sr * dur)
	var data: = PackedByteArray()
	data.resize(n * 2)
	for i in n:
		var t: = float(i) / sr
		var env: = pow(1.0 - t / dur, 2.2)
		var s: = sin(TAU * freq * t) * env * amp
		data.encode_s16(i * 2, int(clampf(s, -1.0, 1.0) * 32767.0))
	var wav: = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sr
	wav.stereo = false
	wav.data = data
	return wav




func _hide_name() -> void :
	_name_bar.visible = false
	_name_label.visible = false
