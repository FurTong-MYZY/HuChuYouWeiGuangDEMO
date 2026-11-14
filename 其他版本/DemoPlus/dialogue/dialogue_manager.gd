extends Node














signal dialogue_started(dialogue_id: String)
signal line_shown(node: Dictionary)
signal dialogue_ended

const DATA_PATH: = "res://dialogue/dialogue_data.json"

var active: bool = false
var current_dialogue_id: String = ""
var current_id: String = ""
var current_node: Dictionary = {}
var flags: Dictionary = {}

var _data: Dictionary = {}
var _ui: CanvasLayer

func _ready() -> void :

	process_mode = Node.PROCESS_MODE_ALWAYS
	_load_data()
	_create_ui()

	get_tree().scene_changed.connect(_on_scene_changed)

func _load_data() -> void :
	if not FileAccess.file_exists(DATA_PATH):
		push_error("DialogueManager: 找不到对话数据文件 " + DATA_PATH)
		return
	var raw: = FileAccess.get_file_as_string(DATA_PATH)
	var parsed = JSON.parse_string(raw)
	if typeof(parsed) != TYPE_DICTIONARY or not (parsed as Dictionary).has("nodes"):
		push_error("DialogueManager: 对话数据格式错误")
		return
	_data = parsed

func _create_ui() -> void :
	var ui_script: GDScript = load("res://dialogue/dialogue_ui.gd")
	if ui_script == null:
		push_error("DialogueManager: 无法加载 dialogue_ui.gd")
		return
	_ui = ui_script.new()
	add_child(_ui)



func start_dialogue(id: String) -> bool:
	if active:
		return false
	if not _data.has("nodes"):
		return false
	var nodes: Dictionary = _data["nodes"]
	if not nodes.has(id):
		push_error("DialogueManager: 找不到对话节点 " + id)
		return false
	active = true
	current_dialogue_id = id
	dialogue_started.emit(id)
	_enter_node(id)
	return true

func end_dialogue() -> void :
	if not active:
		return
	active = false
	current_dialogue_id = ""
	current_id = ""
	current_node = {}
	dialogue_ended.emit()

func advance() -> void :

	if not active or not get_choices().is_empty():
		return
	var next_id: = _resolve_next(current_node)
	if next_id.is_empty():
		end_dialogue()
	else:
		_enter_node(next_id)

func choose(index: int) -> void :
	if not active:
		return
	var choices: = get_choices()
	if index < 0 or index >= choices.size():
		return
	var choice: Dictionary = choices[index]
	_apply_set_flag(choice.get("set_flag"))
	var next_id: = ""
	if choice.has("next") and choice["next"] != null:
		next_id = str(choice["next"])
	if next_id.is_empty():
		end_dialogue()
	else:
		_enter_node(next_id)

func get_choices() -> Array:
	var list: Array = current_node.get("choices", [])
	var result: Array = []
	for c in list:
		if typeof(c) != TYPE_DICTIONARY:
			continue
		var cond: String = str(c.get("condition", ""))
		if not cond.is_empty() and not flags.get(cond, false):
			continue
		result.append(c)
	return result

func set_flag(name: String) -> void :
	flags[name] = true

func has_flag(name: String) -> bool:
	return flags.get(name, false)



func _enter_node(id: String) -> void :
	var nodes: Dictionary = _data["nodes"]
	if not nodes.has(id):
		push_error("DialogueManager: 节点不存在: " + id)
		end_dialogue()
		return
	current_node = nodes[id]
	current_id = id
	_apply_set_flag(current_node.get("set_flag"))
	line_shown.emit(current_node)

func _apply_set_flag(value) -> void :
	if value == null:
		return
	if typeof(value) == TYPE_STRING:
		flags[str(value)] = true
	elif typeof(value) == TYPE_ARRAY:
		for f in value:
			if typeof(f) == TYPE_STRING:
				flags[f] = true

func _resolve_next(node: Dictionary) -> String:
	if node.has("goto") and node["goto"] != null:
		return str(node["goto"])
	if node.has("goto_if") and typeof(node["goto_if"]) == TYPE_DICTIONARY:
		var gi: Dictionary = node["goto_if"]
		var cond: bool = flags.get(str(gi.get("flag", "")), false)
		return str(gi.get("then" if cond else "else", ""))
	if node.has("next") and node["next"] != null:
		return str(node["next"])
	return ""

func _on_scene_changed(_new_scene: Node) -> void :
	if active:
		active = false
		current_dialogue_id = ""
		current_id = ""
		current_node = {}
		dialogue_ended.emit()
